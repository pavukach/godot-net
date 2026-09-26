class_name InterestZone
extends Area2D

const SPAWN_RADIUS := 900.0
const DESPAWN_RADIUS := 1050.0

enum Type {
	SPAWN,
	DESPAWN
}

var player_id: int
var radius: float
var type: Type

func _init(p_player_id: int, p_radius: float, p_type: Type) -> void:
	player_id = p_player_id
	radius = p_radius
	type = p_type

func _ready():
	var collider := CollisionShape2D.new()
	var shape := CircleShape2D.new()

	shape.radius = radius
	collider.shape = shape

	add_child(collider)
	collision_layer = NetInterest.INTEREST_LAYER
	collision_mask = 1 << (NetInterest.INTEREST_LAYER - 1)
	monitoring = true
	monitorable = true