class_name NetworkCore
extends RefCounted

const HEADER_SIZE := 9
const CONTEXT_ENTITY := 0xFFFFFFFD
const PING_ENTITY := 0xFFFFFFFE
const RETIRED_WINDOW := 1024

signal peer_connected(id: int)
signal peer_disconnected(id: int)
signal connected_to_server
signal packet_received(tick: int)

var peer: MultiplayerPeer
var sender_id: int
var packet_tick: int
var _entities: Dictionary[int, Object] = {}
var _pending_packets: Dictionary[int, Array] = {}
var _retired_entities: Dictionary[int, bool] = {}
var _retired_order: Array[int] = []
var _contexts: Dictionary[int, Object] = {}
var _players: Array[int] = []
var _ids := OrderedIndexBank.new()
var _is_server := false
var _connected_emitted := false
var _connected_peers: Array[int] = []


func _init() -> void:
	add_entity(acquire_id(), self)


func is_server() -> bool:
	return _is_server


func local_id() -> int:
	return peer.get_unique_id() if peer else 0


func set_peer(p: MultiplayerPeer, as_server: bool) -> void:
	peer = p
	_is_server = as_server
	p.peer_connected.connect(func(id: int):
		if not _connected_peers.has(id):
			_connected_peers.append(id)
		peer_connected.emit(id)
		if _is_server:
			add_player(id)
	)
	p.peer_disconnected.connect(func(id: int):
		_connected_peers.erase(id)
		peer_disconnected.emit(id)
		if _is_server:
			remove_player(id)
	)


func acquire_id() -> int:
	return _ids.get_index()


func get_players() -> Array[int]:
	return _players


func add_player(id: int) -> void:
	if id not in _players:
		_players.append(id)


func remove_player(id: int) -> void:
	_players.erase(id)


func release_entity(id: int) -> void:
	remove_entity(id)


func poll(_delta: float) -> void:
	if peer == null:
		return

	peer.poll()

	if not _is_server and not _connected_emitted:
		if peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			_connected_emitted = true
			add_player(local_id())
			_connected_peers.append(1)
			connected_to_server.emit()

	while peer.get_available_packet_count() > 0:
		_receive_packet()


func add_entity(id: int, entity: Object) -> void:
	_entities[id] = entity
	_retired_entities.erase(id)
	_flush_pending(id)


func get_entity(id: int) -> Object:
	return _entities.get(id)


func remove_entity(id: int) -> void:
	_entities.erase(id)
	_pending_packets.erase(id)
	_retired_entities[id] = true
	_retired_order.append(id)
	while _retired_order.size() > RETIRED_WINDOW:
		_retired_entities.erase(_retired_order.pop_front())


func register_context(peer_id: int, context: Object) -> void:
	_contexts[peer_id] = context


func unregister_context(peer_id: int) -> void:
	_contexts.erase(peer_id)


func get_context(peer_id: int) -> Object:
	return _contexts.get(peer_id)


func send(
	peer_id: int,
	entity_id: int,
	method_id: int,
	payload: Array,
) -> void:
	if peer == null:
		return

	var entity := _resolve_entity(entity_id, peer_id)

	if peer_id != 0 and peer_id not in _connected_peers:
		return

	var method: NetFunc = entity.network_methods[method_id]

	peer.set_target_peer(peer_id)
	peer.transfer_mode = (
		MultiplayerPeer.TRANSFER_MODE_RELIABLE
		if method.is_reliable()
		else MultiplayerPeer.TRANSFER_MODE_UNRELIABLE
	)

	var buffer := StreamPeerBuffer.new()
	buffer.put_u32(entity_id)
	buffer.put_u8(method_id)
	buffer.put_u32(NetManager.timeline.server_tick())
	buffer.put_data(ByteData.encode(payload, method.get_args()))

	peer.put_packet(buffer.data_array)


func _resolve_entity(entity_id: int, route_peer_id: int) -> Object:
	if entity_id == CONTEXT_ENTITY:
		if _is_server:
			return _contexts.get(route_peer_id)
		return _entities.get(CONTEXT_ENTITY)
	return _entities.get(entity_id)


func _receive_packet() -> void:
	sender_id = peer.get_packet_peer()
	var data := peer.get_packet()

	if data.size() < HEADER_SIZE:
		return

	var buffer := StreamPeerBuffer.new()
	buffer.data_array = data

	var entity_id := buffer.get_u32()
	var method_id := buffer.get_u8()
	packet_tick = buffer.get_u32()
	packet_received.emit(packet_tick)

	var payload: PackedByteArray = buffer.get_data(
		buffer.get_available_bytes()
	)[1]

	var entity := _resolve_entity(entity_id, sender_id)
	if entity == null:
		if _retired_entities.has(entity_id):
			return
		if not _pending_packets.has(entity_id):
			_pending_packets[entity_id] = []
		_pending_packets[entity_id].append([method_id, payload, packet_tick, sender_id])
		return

	_call_network_method(entity, method_id, payload)


func _call_network_method(
	entity: Object,
	method_id: int,
	payload: PackedByteArray,
) -> void:
	var methods: Array[NetFunc] = entity.network_methods
	var method: NetFunc = methods[method_id]

	var args := ByteData.decode_with_peer(payload, method.get_args(), sender_id)
	method.invoke(args)


func _flush_pending(entity_id: int) -> void:
	if not _pending_packets.has(entity_id):
		return
	var queued: Array = _pending_packets[entity_id]
	_pending_packets.erase(entity_id)
	if queued.is_empty():
		return
	var entity: Object = _entities[entity_id]
	var restore_tick := packet_tick
	var restore_sender := sender_id
	for packet in queued:
		var method_id: int = packet[0]
		var payload: PackedByteArray = packet[1]
		packet_tick = packet[2]
		sender_id = packet[3]
		_call_network_method(entity, method_id, payload)
	packet_tick = restore_tick
	sender_id = restore_sender