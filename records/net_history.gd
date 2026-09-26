class_name NetHistory
extends RefCounted

class Sample:
	var tick: int
	var value: Variant

	func _init(p_tick: int, p_value: Variant) -> void:
		tick = p_tick
		value = p_value


var _samples: Array[Sample] = []


func is_empty() -> bool:
	return _samples.is_empty()


func add(tick: int, value: Variant) -> void:
	var at := _samples.size()
	while at > 0 and _samples[at - 1].tick > tick:
		at -= 1
	if at > 0 and _samples[at - 1].tick == tick:
		_samples[at - 1].value = value
		return
	_samples.insert(at, Sample.new(tick, value))
	if _samples.size() > NetTimelineConfig.SNAPSHOT_HISTORY:
		_samples.remove_at(0)


func sample(playhead: float, blend: Callable) -> Variant:
	var newest := _samples.size() - 1
	if playhead >= _samples[newest].tick:
		return _samples[newest].value
	for i in range(newest, 0, -1):
		var before := _samples[i - 1]
		if playhead < before.tick:
			continue
		var after := _samples[i]
		var weight := (playhead - before.tick) / float(after.tick - before.tick)
		return blend.call(before.value, after.value, weight)
	return _samples[0].value
