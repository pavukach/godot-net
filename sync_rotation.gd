class_name SyncRotation
extends Node2D

@export var use_local_rotation := false

var _rot: NetVar
var _net: NetNode
var _parent: Node2D

var target_rot: float:
	get:
		return _rot.get_value()


func _ready() -> void:
	process_physics_priority = NetProcessPriority.SYNC_APPLY
	process_priority = NetProcessPriority.SYNC_APPLY

	_net = owner as NetNode
	_parent = get_parent() as Node2D

	_rot = NetVar.new(0.0, ByteData.Type.FLOAT, NetInterp.angle)

	_net.register_var(_rot)
	_net.register_initial_var(_rot)

	if NetManager.network.is_server():
		_rot.set_value(parent_rotation())


func _physics_process(_delta: float) -> void:
	if not NetManager.network.is_server():
		return
	_rot.set_value(parent_rotation())


func _process(_delta: float) -> void:
	if NetManager.network.is_server():
		return
	_apply_parent(target_rot)


func parent_rotation() -> float:
	return _parent.rotation if use_local_rotation else _parent.global_rotation


func _apply_parent(rot: float) -> void:
	if use_local_rotation:
		_parent.rotation = rot
	else:
		_parent.global_rotation = rot
