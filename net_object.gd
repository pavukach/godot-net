class_name NetObject
extends Node2D

var network_id: int
var network_methods: Array[NetFunc] = []


func register_method(callable: Callable, arg_types: Array[ByteData.Type], reliable: bool) -> int:
	var index := network_methods.size()
	network_methods.append(NetFunc.new(callable, arg_types, reliable))
	return index


func register_event(callable: Callable, arg_types: Array[ByteData.Type], reliable: bool) -> int:
	return register_method(_wrap_event(callable), arg_types, reliable)


func _wrap_event(callable: Callable) -> Callable:
	return func(...args: Array) -> void:
		if NetManager.network.is_server():
			callable.callv(args)
			return
		var tick := NetManager.network.packet_tick
		if NetManager.timeline.playhead() >= tick:
			callable.callv(args)
			return
		var captured: Array = args.duplicate()
		var state := {"fired": false, "on_tick": Callable()}
		state["on_tick"] = func(passed_tick: int) -> void:
			if state["fired"] or passed_tick < tick:
				return
			state["fired"] = true
			if NetManager.timeline.tick_passed.is_connected(state["on_tick"]):
				NetManager.timeline.tick_passed.disconnect(state["on_tick"])
			callable.callv(captured)
		NetManager.timeline.tick_passed.connect(state["on_tick"])


func destroy() -> void:
	queue_free()