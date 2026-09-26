class_name NetHost
extends NetObject

func claim_id(id: int) -> void:
	network_id = id
	NetManager.network.add_entity(network_id, self)