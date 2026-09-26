extends Node

var network: NetworkCore
var spawner: NetSpawner
var interest: NetInterest
var timeline: NetTimeline
var ping: NetPing


func _ready() -> void:
	network = NetworkCore.new()
	spawner = NetSpawner.new()
	interest = NetInterest.new()
	ping = NetPing.new()
	timeline = NetTimeline.new()
	add_child(spawner)
	add_child(ping)
	add_child(timeline)
	add_child(interest)


func init_server(port := NetConfig.PORT, bind_address := NetConfig.BIND_ADDRESS) -> void:
	var ws := WebSocketMultiplayerPeer.new()
	ws.create_server(port, bind_address)
	network.set_peer(ws, true)
	print("Server started on %s:%d" % [bind_address, port])


func init_client(protocol: String, host: String, port: int) -> void:
	var ws := WebSocketMultiplayerPeer.new()
	ws.create_client("%s://%s:%d" % [protocol, host, port])
	network.set_peer(ws, false)
	print("Client connecting to %s://%s:%d" % [protocol, host, port])


func _process(delta: float) -> void:
	network.poll(delta)
