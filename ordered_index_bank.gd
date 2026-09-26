class_name OrderedIndexBank
extends RefCounted

var _next_index := 0
var _free_indices: Array[int] = []

func get_index() -> int:
	if _free_indices.size() > 0:
		return _free_indices.pop_back()
	var index := _next_index
	_next_index += 1
	return index

func free_index(index: int) -> void:
	var place = _free_indices.bsearch_custom(index, func(a, b): return a > b)
	_free_indices.insert(place, index)
	while _free_indices.size() > 0 and _free_indices[0] + 1 == _next_index:
		_next_index -= 1
		_free_indices.pop_front()