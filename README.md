# godot_net

A small, self-contained networking stack for Godot 4. Server-authoritative,
snapshot-based entity replication with interest management and client-side
interpolation.

## Install

Add the repository as a git submodule at `res://addons/godot_net`:

```sh
git submodule add git@github.com:<you>/godot_net.git addons/godot_net
```

## Setup

1. Register the networking manager as an autoload named **`NetManager`**
   (the name is not optional — the stack resolves itself through it):

   ```
   [autoload]
   NetManager="*res://addons/godot_net/net_manager.gd"
   ```

2. Call one of the init functions before the game needs networking:

   ```gdscript
   NetManager.init_server()                            # defaults to NetConfig
   NetManager.init_server(8080, "0.0.0.0")

   NetManager.init_client("wss", "example.com", 443)
   NetManager.init_client("ws", "127.0.0.1", 4242)
   ```

   `init_client` returns immediately; the connection is established in the
   background. Await `NetManager.network.connected_to_server` to continue once
   you are online.

3. Point the spawner at the node that replicated entities are added to, and
   register the scenes that may be spawned:

   ```gdscript
   NetManager.spawner.world = get_node("/root/Game/World")
   NetManager.spawner.entities = [player.tscn, projectile.tscn]
   NetManager.spawner.rebuild_index()
   ```

## Spawning networked things

A networked scene's root extends `NetObject` (or `NetNode` for replicated
entities). Children register their state through the root:

```gdscript
extends NetNode

@onready var _net: NetNode = owner as NetNode
@onready var _velocity: NetVar

func _ready() -> void:
    _velocity = NetVar.new(0.0, ByteData.Type.FLOAT)
    _net.register_var(_velocity)
    _net.register_initial_var(_velocity)
```

Three registration calls, by intent:

| call | purpose |
| --- | --- |
| `register_var` | sent every server tick, unreliable, interpolated on the client |
| `register_initial_var` | sent once when the entity spawns for a player |
| `register_reliable_var` | sent on every change, reliable, not interpolated |

`SyncPosition` and `SyncRotation` (`res://addons/godot_net/`) are drop-in
components for the common case — add one to a `Node2D` and it syncs itself.

## Interest management

Entities are only replicated to players whose interest zone contains them.
`NetManager.interest.start_tracking(entity_id, player_id)` sends the entity to a
player; `stop_tracking` despawns it for them. `InterestZone` and
`InterestTarget` (`interest/`) are ready-made `Area2D` helpers.

## Notes

- Authoritative server: only the server may spawn entities or mutate synced
  state. Clients interpolate toward received snapshots.
- Timestamps come from a shared tick counter (`NetManager.timeline`), so the
  server and clients must run the same physics tick rate.
- `NetConfig` holds the default host, port and bind address.

## Tuning

| script | purpose |
| --- | --- |
| `net_ping_config.gd` | ping interval and latency smoothing |
| `net_timeline_config.gd` | interpolation delay, history size, resync thresholds |
