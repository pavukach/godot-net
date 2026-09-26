class_name NetInterest
extends Node

const INTEREST_LAYER := 2
const TARGET_LAYER := 3

var entity_per_player: Dictionary[int, Array] = {}


func on_entity_created(entity: NetNode) -> void:
	entity_per_player[entity.network_id] = []


func on_entity_destroyed(entity: NetNode) -> void:
	var players: Array = entity_per_player.get(entity.network_id, [])
	for player_id in players:
		NetManager.spawner.replicate_despawn(player_id, entity.network_id)
	entity_per_player.erase(entity.network_id)


func start_tracking(entity_id: int, player_id: int) -> void:
	if player_id in entity_per_player.get(entity_id, []):
		return
	entity_per_player[entity_id].append(player_id)
	var entity: NetNode = NetManager.network.get_entity(entity_id)
	NetManager.spawner.replicate_spawn(player_id, entity)


func stop_tracking(entity_id: int, player_id: int) -> void:
	entity_per_player[entity_id].erase(player_id)
	NetManager.spawner.replicate_despawn(player_id, entity_id)


func send(entity_id: int, method_id: int, payload: Array) -> void:
	for player in entity_per_player.get(entity_id, []):
		NetManager.network.send(player, entity_id, method_id, payload)
