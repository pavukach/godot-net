class_name NetFunc
extends RefCounted

var _func: Callable
var _reliable: bool
var _args: Array[ByteData.Type]

func _init(
	p_func: Callable,
	args: Array[ByteData.Type],
	p_reliable: bool,
) -> void:
	_func = p_func
	_args = args
	_reliable = p_reliable

func invoke(args: Array) -> void:
	_func.callv(args)

func get_args() -> Array[ByteData.Type]:
	return _args

func is_reliable() -> bool:
	return _reliable
