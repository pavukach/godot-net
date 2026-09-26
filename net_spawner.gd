class_name NetSpawner
extends NetHost

const METHOD_SPAWN := 0
const METHOD_DESPAWN := 1

var world: Node
var entities: Array[PackedScene] = []

var scene_to_index: Dictionary = {}


func _ready() -> void:
	claim_id(NetManager.network.acquire_id())
	register_event(_spawn_remote, [ByteData.Type.UINT, ByteData.Type.UINT, ByteData.Type.UINT], true)
	register_event(_despawn_remote, [ByteData.Type.UINT], true)


func index_of_scene(scene: PackedScene) -> int:
	return scene_to_index.get(scene.resource_path, -1)


func rebuild_index() -> void:
	scene_to_index.clear()
	for i in entities.size():
		scene_to_index[entities[i].resource_path] = i


func spawn(entity_index: int, initial_transform := Transform2D.IDENTITY, owner_id := 0) -> NetNode:
	if not NetManager.network.is_server():
		push_error("Can only spawn entities on the server")
		return null
	var entity := entities[entity_index].instantiate() as NetNode
	var id := NetManager.network.acquire_id()
	NetManager.network.add_entity(id, entity)
	entity.network_id = id
	entity.network_type = entity_index
	entity.owner_id = owner_id
	entity.transform = initial_transform
	return entity


func add_to_world(entity: NetNode) -> void:
	world.add_child(entity)


func replicate_spawn(player_id: int, entity: NetNode) -> void:
	NetManager.network.send(
		player_id,
		network_id,
		METHOD_SPAWN,
		[entity.network_id, entity.network_type, entity.owner_id],
	)
	entity.update_initial(player_id)
	entity.update_reliable(player_id)


func replicate_despawn(player_id: int, entity_id: int) -> void:
	NetManager.network.send(player_id, network_id, METHOD_DESPAWN, [entity_id])


func _spawn_remote(entity_id: int, index: int, owner_id: int) -> void:
	if NetManager.network.get_entity(entity_id) != null:
		return
	var entity := entities[index].instantiate() as NetNode
	entity.network_id = entity_id
	entity.network_type = index
	entity.owner_id = owner_id
	entity.add_to_group(str(owner_id))
	entity.set_meta("peer_id", owner_id)
	world.add_child(entity)
	NetManager.network.add_entity(entity_id, entity)


func _despawn_remote(entity_id: int) -> void:
	var entity := NetManager.network.get_entity(entity_id) as NetNode
	NetManager.network.remove_entity(entity_id)
	entity.queue_free()