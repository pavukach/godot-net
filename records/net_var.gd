class_name NetVar
extends RefCounted

var _value
var _initial
var _type
var _blend: Callable
var _history := NetHistory.new()

signal changed

func _init(p_value: Variant, p_type: ByteData.Type, blend := NetInterp.hold) -> void:
	_value = p_value
	_initial = p_value
	_type = p_type
	_blend = blend

func get_type() -> ByteData.Type:
	return _type

func get_value() -> Variant:
	if _history.is_empty():
		return _value
	return _history.sample(NetManager.timeline.playhead(), _blend)

func set_value(p_value: Variant) -> void:
	_value = p_value
	changed.emit()

func receive(p_value: Variant, tick: int) -> void:
	_history.add(tick, p_value)
	changed.emit()

func is_initial() -> bool:
	return _value == _initial
