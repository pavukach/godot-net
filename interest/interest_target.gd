class_name InterestTarget
extends Area2D

const RADIUS := 32.0

var entity_id: int


func _init(p_entity_id: int = 0) -> void:
	entity_id = p_entity_id


func _ready():
	if entity_id == 0:
		entity_id = (owner as NetNode).network_id
	var collider := CollisionShape2D.new()
	var shape := CircleShape2D.new()

	shape.radius = RADIUS
	collider.shape = shape

	add_child(collider)
	collision_layer = NetInterest.INTEREST_LAYER
	collision_mask = 1 << (NetInterest.INTEREST_LAYER - 1)
	monitoring = true
	monitorable = true
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


func _on_area_entered(area: Area2D) -> void:
	if not NetManager.network.is_server():
		return
	var zone := area as InterestZone
	if zone.type != InterestZone.Type.SPAWN:
		return

	NetManager.interest.start_tracking(entity_id, zone.player_id)


func _on_area_exited(area: Area2D) -> void:
	if not NetManager.network.is_server():
		return
	var zone := area as InterestZone
	if zone.type != InterestZone.Type.DESPAWN:
		return

	NetManager.interest.stop_tracking(entity_id, zone.player_id)
