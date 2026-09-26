class_name NetObject
extends Node2D

var network_id: int
var network_methods: Array[NetFunc] = []


func register_method(callable: Callable, arg_types: Array[ByteData.Type], reliable: bool) -> int:
	var index := network_methods.size()
	network_methods.append(NetFunc.new(callable, arg_types, reliable))
	return index


func register_event(callable: Callable, arg_types: Array[ByteData.Type], reliable: bool) -> int:
	if NetManager.network.is_server():
		return register_method(callable, arg_types, reliable)
	return register_method(_wrap_event(callable), arg_types, reliable)


func _wrap_event(callable: Callable) -> Callable:
	return func(...args: Array) -> void:
		var tick := NetManager.network.packet_tick
		if NetManager.timeline.playhead() >= tick:
			callable.callv(args)
			return
		var captured: Array = args.duplicate()
		var fired := false
		var on_tick: Callable
		on_tick = func(passed_tick: int) -> void:
			if fired or passed_tick < tick:
				return
			fired = true
			if NetManager.timeline.tick_passed.is_connected(on_tick):
				NetManager.timeline.tick_passed.disconnect(on_tick)
			callable.callv(captured)
		NetManager.timeline.tick_passed.connect(on_tick)


func destroy() -> void:
	queue_free()