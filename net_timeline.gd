class_name NetTimeline
extends Node

signal tick_passed(tick: int)

var _server_tick := 0
var _latest_tick := -1
var _playhead := -1.0
var _delay_ticks := NetTimelineConfig.INITIAL_INTERP_DELAY_TICKS
var _last_emitted_tick := -1


func _ready() -> void:
	process_priority = NetProcessPriority.TIMELINE
	if not NetManager.network.is_server():
		NetManager.network.packet_received.connect(_on_packet_received)


func _physics_process(_delta: float) -> void:
	if NetManager.network.is_server():
		_server_tick += 1


func _process(delta: float) -> void:
	if NetManager.network.is_server():
		return
	_advance(delta)
	_emit_tick_passed()


func _on_packet_received(tick: int) -> void:
	_latest_tick = maxi(_latest_tick, tick)


func server_tick() -> int:
	return _server_tick


func playhead() -> float:
	return _playhead


func interp_delay_ticks() -> float:
	return _delay_ticks


func _emit_tick_passed() -> void:
	var tick := int(floor(_playhead))
	while _last_emitted_tick < tick:
		_last_emitted_tick += 1
		tick_passed.emit(_last_emitted_tick)


func _advance(delta: float) -> void:
	if _latest_tick < 0:
		return
	_update_delay()
	var target := _latest_tick - _delay_ticks
	if _playhead < 0.0 or absf(target - _playhead) > NetTimelineConfig.PLAYHEAD_RESYNC_TICKS:
		_playhead = target
		return
	_playhead += delta * Engine.physics_ticks_per_second
	_playhead = lerpf(_playhead, target, NetTimelineConfig.PLAYHEAD_CORRECTION)


func _update_delay() -> void:
	var target := clampf(
		NetManager.ping.latency() * Engine.physics_ticks_per_second
		+ NetTimelineConfig.INTERP_DELAY_MARGIN_TICKS,
		NetTimelineConfig.MIN_INTERP_DELAY_TICKS,
		NetTimelineConfig.MAX_INTERP_DELAY_TICKS,
	)
	var rate := (
		NetTimelineConfig.DELAY_GROW_RATE
		if target > _delay_ticks
		else NetTimelineConfig.DELAY_SHRINK_RATE
	)
	_delay_ticks = lerpf(_delay_ticks, target, rate)