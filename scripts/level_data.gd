extends RefCounted
## Campaign definitions for the three Crystal Rush sectors.
## Kept as plain dictionaries so the level builder stays asset-free.

static var _cache: Array = []


static func count() -> int:
	return _levels().size()


static func get_level(index: int) -> Dictionary:
	var levels := _levels()
	return levels[clampi(index, 0, levels.size() - 1)]


static func _levels() -> Array:
	if _cache.is_empty():
		_cache = [_level_one(), _level_two(), _level_three()]
	return _cache


static func _block(center: Vector3, size: Vector3) -> Dictionary:
	return {"center": center, "size": size}


static func _level_one() -> Dictionary:
	return {
		"name": "FIRST CONTACT",
		"brief": "Collect 8 shards. Stalkers are slow. Learn the arena.",
		"arena_half": 22.0,
		"player_spawn": Vector3(0.0, 1.2, 17.0),
		"shards": [
			Vector3(-7.0, 1.25, -8.0),
			Vector3(7.0, 1.25, -8.0),
			Vector3(0.0, 1.25, 11.0),
			Vector3(-16.0, 1.25, 2.0),
			Vector3(16.0, 1.25, 2.0),
			Vector3(-12.0, 1.25, -12.0),
			Vector3(12.0, 1.25, -12.0),
			Vector3(0.0, 1.25, -19.0),
		],
		"crates": [
			Vector3(-7.0, 0.65, -5.0),
			Vector3(7.0, 0.65, -5.0),
			Vector3(-13.0, 0.65, 5.0),
			Vector3(13.0, 0.65, 5.0),
			Vector3(-5.0, 0.65, 10.0),
			Vector3(6.0, 0.65, 10.0),
			Vector3(-16.0, 0.65, -13.0),
			Vector3(16.0, 0.65, -13.0),
			Vector3(-2.0, 0.65, -13.0),
			Vector3(10.0, 0.65, -17.0),
			Vector3(-11.0, 0.65, -17.0),
		],
		"walls": [
			_block(Vector3(-11.0, 0.65, -1.0), Vector3(6.0, 1.3, 0.7)),
			_block(Vector3(11.0, 0.65, -1.0), Vector3(6.0, 1.3, 0.7)),
			_block(Vector3(0.0, 0.65, 4.0), Vector3(0.7, 1.3, 6.0)),
		],
		"pillars": [
			_block(Vector3(0.0, 2.0, -6.0), Vector3(1.4, 4.0, 1.4)),
			_block(Vector3(-17.0, 2.0, 8.0), Vector3(1.4, 4.0, 1.4)),
			_block(Vector3(17.0, 2.0, 8.0), Vector3(1.4, 4.0, 1.4)),
			_block(Vector3(-8.0, 2.0, -18.0), Vector3(1.4, 4.0, 1.4)),
			_block(Vector3(8.0, 2.0, -18.0), Vector3(1.4, 4.0, 1.4)),
		],
		"spawns": [
			Vector3(0.0, 0.9, -19.0),
			Vector3(19.0, 0.9, 0.0),
			Vector3(-19.0, 0.9, 0.0),
			Vector3(17.0, 0.9, -17.0),
			Vector3(-17.0, 0.9, -17.0),
			Vector3(17.0, 0.9, 17.0),
			Vector3(-17.0, 0.9, 17.0),
			Vector3(10.0, 0.9, -18.0),
		],
		"enemy_count": 3,
		"enemy_health": 2,
		"enemy_speed": 3.0,
		"enemy_damage": 14,
		"respawn": 5.5,
		"accent": Color(0.35, 0.95, 1.0, 1.0),
		"floor_base": Color(0.035, 0.045, 0.07, 1.0),
		"floor_line": Color(0.14, 0.7, 0.82, 1.0),
		"wall": Color(0.075, 0.075, 0.13, 1.0),
		"crate": Color(0.12, 0.12, 0.2, 1.0),
		"pillar": Color(0.09, 0.08, 0.14, 1.0),
		"trim_a": Color(0.1, 0.85, 1.0, 1.0),
		"trim_b": Color(1.0, 0.15, 0.7, 1.0),
		"fog": Color(0.09, 0.07, 0.16, 1.0),
		"sky_top": Color(0.03, 0.04, 0.1, 1.0),
		"sky_horizon": Color(0.33, 0.12, 0.31, 1.0),
		"ground_horizon": Color(0.14, 0.07, 0.18, 1.0),
		"sun": Color(1.0, 0.82, 0.92, 1.0),
		"rim_a": Color(0.2, 0.7, 1.0, 1.0),
		"rim_b": Color(1.0, 0.2, 0.8, 1.0),
	}


static func _level_two() -> Dictionary:
	return {
		"name": "CROSSFIRE",
		"brief": "10 shards. 5 hunters. Use cover or get boxed in.",
		"arena_half": 26.0,
		"player_spawn": Vector3(0.0, 1.2, 21.0),
		"shards": [
			Vector3(-10.0, 1.25, -9.0),
			Vector3(10.0, 1.25, -9.0),
			Vector3(0.0, 1.25, 15.0),
			Vector3(-21.0, 1.25, 1.0),
			Vector3(21.0, 1.25, 1.0),
			Vector3(-16.0, 1.25, -18.0),
			Vector3(16.0, 1.25, -18.0),
			Vector3(-19.0, 1.25, 18.0),
			Vector3(19.0, 1.25, 18.0),
			Vector3(0.0, 1.25, -23.0),
		],
		"crates": [
			Vector3(-10.0, 0.65, -6.0),
			Vector3(10.0, 0.65, -6.0),
			Vector3(-16.0, 0.65, 7.0),
			Vector3(16.0, 0.65, 7.0),
			Vector3(-7.0, 0.65, 12.0),
			Vector3(7.0, 0.65, 12.0),
			Vector3(-19.0, 0.65, -15.0),
			Vector3(19.0, 0.65, -15.0),
			Vector3(-3.0, 0.65, -16.0),
			Vector3(13.0, 0.65, -21.0),
			Vector3(-13.0, 0.65, -21.0),
			Vector3(-22.0, 0.65, 17.0),
			Vector3(22.0, 0.65, 17.0),
		],
		"walls": [
			_block(Vector3(-13.0, 0.65, -1.0), Vector3(7.0, 1.3, 0.7)),
			_block(Vector3(13.0, 0.65, -1.0), Vector3(7.0, 1.3, 0.7)),
			_block(Vector3(0.0, 0.65, 5.0), Vector3(0.7, 1.3, 7.0)),
			_block(Vector3(-21.0, 0.65, 10.0), Vector3(0.7, 1.3, 5.0)),
			_block(Vector3(21.0, 0.65, 10.0), Vector3(0.7, 1.3, 5.0)),
		],
		"pillars": [
			_block(Vector3(0.0, 2.0, -8.0), Vector3(1.4, 4.0, 1.4)),
			_block(Vector3(-22.0, 2.0, 4.0), Vector3(1.4, 4.0, 1.4)),
			_block(Vector3(22.0, 2.0, 4.0), Vector3(1.4, 4.0, 1.4)),
			_block(Vector3(-11.0, 2.0, -22.0), Vector3(1.4, 4.0, 1.4)),
			_block(Vector3(11.0, 2.0, -22.0), Vector3(1.4, 4.0, 1.4)),
			_block(Vector3(-18.0, 2.0, -9.0), Vector3(1.4, 4.0, 1.4)),
			_block(Vector3(18.0, 2.0, -9.0), Vector3(1.4, 4.0, 1.4)),
		],
		"spawns": [
			Vector3(0.0, 0.9, -23.0),
			Vector3(23.0, 0.9, 0.0),
			Vector3(-23.0, 0.9, 0.0),
			Vector3(21.0, 0.9, -21.0),
			Vector3(-21.0, 0.9, -21.0),
			Vector3(21.0, 0.9, 21.0),
			Vector3(-21.0, 0.9, 21.0),
			Vector3(12.0, 0.9, -23.0),
			Vector3(-12.0, 0.9, -23.0),
			Vector3(23.0, 0.9, 12.0),
		],
		"enemy_count": 5,
		"enemy_health": 2,
		"enemy_speed": 3.5,
		"enemy_damage": 16,
		"respawn": 4.5,
		"accent": Color(1.0, 0.4, 0.85, 1.0),
		"floor_base": Color(0.05, 0.035, 0.075, 1.0),
		"floor_line": Color(0.85, 0.3, 0.75, 1.0),
		"wall": Color(0.09, 0.06, 0.12, 1.0),
		"crate": Color(0.16, 0.1, 0.18, 1.0),
		"pillar": Color(0.11, 0.07, 0.13, 1.0),
		"trim_a": Color(1.0, 0.25, 0.8, 1.0),
		"trim_b": Color(1.0, 0.55, 0.2, 1.0),
		"fog": Color(0.14, 0.06, 0.15, 1.0),
		"sky_top": Color(0.05, 0.03, 0.11, 1.0),
		"sky_horizon": Color(0.42, 0.12, 0.34, 1.0),
		"ground_horizon": Color(0.16, 0.06, 0.16, 1.0),
		"sun": Color(1.0, 0.75, 0.9, 1.0),
		"rim_a": Color(1.0, 0.25, 0.85, 1.0),
		"rim_b": Color(1.0, 0.6, 0.15, 1.0),
	}


static func _level_three() -> Dictionary:
	return {
		"name": "THE GAUNTLET",
		"brief": "12 shards. 7 relentless hunters. Survive the gauntlet.",
		"arena_half": 30.0,
		"player_spawn": Vector3(0.0, 1.2, 25.0),
		"shards": [
			Vector3(-11.0, 1.25, -11.0),
			Vector3(11.0, 1.25, -11.0),
			Vector3(0.0, 1.25, -26.0),
			Vector3(-25.0, 1.25, 1.0),
			Vector3(25.0, 1.25, 1.0),
			Vector3(-19.0, 1.25, -22.0),
			Vector3(19.0, 1.25, -22.0),
			Vector3(-19.0, 1.25, 21.0),
			Vector3(19.0, 1.25, 21.0),
			Vector3(0.0, 1.25, 22.0),
			Vector3(-7.0, 1.25, 5.0),
			Vector3(7.0, 1.25, -3.0),
		],
		"crates": [
			Vector3(-12.0, 0.65, -8.0),
			Vector3(12.0, 0.65, -8.0),
			Vector3(-18.0, 0.65, 9.0),
			Vector3(18.0, 0.65, 9.0),
			Vector3(-8.0, 0.65, 14.0),
			Vector3(8.0, 0.65, 14.0),
			Vector3(-23.0, 0.65, -17.0),
			Vector3(23.0, 0.65, -17.0),
			Vector3(-4.0, 0.65, -18.0),
			Vector3(15.0, 0.65, -24.0),
			Vector3(-15.0, 0.65, -24.0),
			Vector3(-25.0, 0.65, 20.0),
			Vector3(25.0, 0.65, 20.0),
			Vector3(-22.0, 0.65, -5.0),
			Vector3(22.0, 0.65, -5.0),
		],
		"walls": [
			_block(Vector3(-15.0, 0.65, -2.0), Vector3(8.0, 1.3, 0.7)),
			_block(Vector3(15.0, 0.65, -2.0), Vector3(8.0, 1.3, 0.7)),
			_block(Vector3(0.0, 0.65, 7.0), Vector3(0.7, 1.3, 9.0)),
			_block(Vector3(-22.0, 0.65, 12.0), Vector3(0.7, 1.3, 7.0)),
			_block(Vector3(22.0, 0.65, 12.0), Vector3(0.7, 1.3, 7.0)),
			_block(Vector3(0.0, 0.65, -16.0), Vector3(9.0, 1.3, 0.7)),
		],
		"pillars": [
			_block(Vector3(0.0, 2.0, -9.0), Vector3(1.4, 4.0, 1.4)),
			_block(Vector3(-25.0, 2.0, 3.0), Vector3(1.4, 4.0, 1.4)),
			_block(Vector3(25.0, 2.0, 3.0), Vector3(1.4, 4.0, 1.4)),
			_block(Vector3(-13.0, 2.0, -25.0), Vector3(1.4, 4.0, 1.4)),
			_block(Vector3(13.0, 2.0, -25.0), Vector3(1.4, 4.0, 1.4)),
			_block(Vector3(-20.0, 2.0, -11.0), Vector3(1.6, 4.0, 1.6)),
			_block(Vector3(20.0, 2.0, -11.0), Vector3(1.6, 4.0, 1.6)),
		],
		"spawns": [
			Vector3(0.0, 0.9, -27.0),
			Vector3(27.0, 0.9, 0.0),
			Vector3(-27.0, 0.9, 0.0),
			Vector3(25.0, 0.9, -25.0),
			Vector3(-25.0, 0.9, -25.0),
			Vector3(25.0, 0.9, 25.0),
			Vector3(-25.0, 0.9, 25.0),
			Vector3(14.0, 0.9, -27.0),
			Vector3(-14.0, 0.9, -27.0),
			Vector3(27.0, 0.9, 14.0),
			Vector3(-27.0, 0.9, 14.0),
			Vector3(0.0, 0.9, -14.0),
		],
		"enemy_count": 7,
		"enemy_health": 3,
		"enemy_speed": 4.0,
		"enemy_damage": 20,
		"respawn": 3.5,
		"accent": Color(1.0, 0.55, 0.2, 1.0),
		"floor_base": Color(0.055, 0.03, 0.04, 1.0),
		"floor_line": Color(0.95, 0.42, 0.15, 1.0),
		"wall": Color(0.1, 0.05, 0.06, 1.0),
		"crate": Color(0.18, 0.08, 0.09, 1.0),
		"pillar": Color(0.12, 0.06, 0.07, 1.0),
		"trim_a": Color(1.0, 0.45, 0.12, 1.0),
		"trim_b": Color(1.0, 0.15, 0.25, 1.0),
		"fog": Color(0.16, 0.045, 0.06, 1.0),
		"sky_top": Color(0.07, 0.02, 0.05, 1.0),
		"sky_horizon": Color(0.45, 0.1, 0.16, 1.0),
		"ground_horizon": Color(0.18, 0.05, 0.06, 1.0),
		"sun": Color(1.0, 0.7, 0.75, 1.0),
		"rim_a": Color(1.0, 0.4, 0.12, 1.0),
		"rim_b": Color(1.0, 0.12, 0.3, 1.0),
	}
