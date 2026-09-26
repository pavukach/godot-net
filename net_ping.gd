class_name NetPing
extends NetHost

const METHOD_REQUEST := 0
const METHOD_REPLY := 1
const ROUND_TRIP_MS_DIVISOR := 2000.0

var _latency := 0.0
var _interval_timer := 0.0
var _sequence := 0
var _sent_at_ms := 0


func _ready() -> void:
	network_methods = [
		NetFunc.new(_on_request, [ByteData.Type.UINT], true),
		NetFunc.new(_on_reply, [ByteData.Type.UINT], true),
	]
	claim_id(NetworkCore.PING_ENTITY)


func latency() -> float:
	return _latency


func _process(delta: float) -> void:
	if NetManager.network.is_server() or NetManager.network.peer == null:
		return
	_interval_timer += delta
	if _interval_timer < NetPingConfig.PING_INTERVAL:
		return
	_interval_timer = 0.0
	_sequence += 1
	_sent_at_ms = Time.get_ticks_msec()
	NetManager.network.send(1, NetworkCore.PING_ENTITY, METHOD_REQUEST, [_sequence])


func _on_request(sequence: int) -> void:
	NetManager.network.send(
		NetManager.network.sender_id,
		NetworkCore.PING_ENTITY,
		METHOD_REPLY,
		[sequence],
	)


func _on_reply(sequence: int) -> void:
	if sequence != _sequence:
		return
	var one_way := (Time.get_ticks_msec() - _sent_at_ms) / ROUND_TRIP_MS_DIVISOR
	if _latency <= 0.0:
		_latency = one_way
		return
	var rate := (
		NetPingConfig.PING_SPIKE_SMOOTHING
		if one_way > _latency
		else NetPingConfig.PING_DECAY_SMOOTHING
	)
	_latency = lerpf(_latency, one_way, rate)