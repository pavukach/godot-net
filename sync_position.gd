class_name SyncPosition
extends Node2D

var _pos_x: NetVar
var _pos_y: NetVar
var _net: NetNode
var _parent: Node2D

var target_pos: Vector2:
	get:
		return Vector2(_pos_x.get_value(), _pos_y.get_value())


func _ready() -> void:
	process_physics_priority = NetProcessPriority.SYNC_APPLY
	process_priority = NetProcessPriority.SYNC_APPLY

	_net = owner as NetNode
	_parent = get_parent() as Node2D

	_pos_x = NetVar.new(0.0, ByteData.Type.FLOAT, NetInterp.linear)
	_pos_y = NetVar.new(0.0, ByteData.Type.FLOAT, NetInterp.linear)

	_net.register_var(_pos_x)
	_net.register_var(_pos_y)
	_net.register_initial_var(_pos_x)
	_net.register_initial_var(_pos_y)

	if NetManager.network.is_server():
		_pos_x.set_value(_parent.global_position.x)
		_pos_y.set_value(_parent.global_position.y)


func _physics_process(_delta: float) -> void:
	if not NetManager.network.is_server():
		return
	_pos_x.set_value(_parent.global_position.x)
	_pos_y.set_value(_parent.global_position.y)


func _process(_delta: float) -> void:
	if NetManager.network.is_server():
		return
	_parent.global_position = target_pos
