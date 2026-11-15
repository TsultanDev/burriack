extends RefCounted
## Campaign definitions: two pages of ten levels, with a boss at the end of each page.
## Layouts and palettes are generated deterministically so the project stays asset-free.

const PAGES := 2
const LEVELS_PER_PAGE := 10
const TOTAL_LEVELS := PAGES * LEVELS_PER_PAGE

const NAMES := [
	"FIRST CONTACT", "CROSSFIRE", "THE GAUNTLET", "DEAD SIGNAL", "VECTOR FIELD",
	"COLD SNAP", "BLACK ICE", "SINGULARITY", "EVENT HORIZON", "THE OVERSEER",
	"NEON FALL", "GHOST GRID", "FRACTURE", "HOT ZONE", "IRON VEIL",
	"RED SHIFT", "DARK MATTER", "LAST LIGHT", "TERMINUS", "THE ARCHITECT",
]

const BOSS_NAMES := ["THE OVERSEER", "THE ARCHITECT"]

static var _cache: Array = []


static func count() -> int:
	return TOTAL_LEVELS


static func get_level(index: int) -> Dictionary:
	var levels := _levels()
	return levels[clampi(index, 0, levels.size() - 1)]


static func _levels() -> Array:
	if _cache.is_empty():
		_cache = []
		for index in range(1, TOTAL_LEVELS + 1):
			_cache.append(_make_level(index))
	return _cache


static func _block(center: Vector3, size: Vector3) -> Dictionary:
	return {"center": center, "size": size}


static func _make_level(index: int) -> Dictionary:
	var page := ((index - 1) / LEVELS_PER_PAGE) + 1
	var slot := ((index - 1) % LEVELS_PER_PAGE) + 1
	var boss_level := slot == LEVELS_PER_PAGE
	var arena_half := 21.0 + float(slot) * 0.85 + float(page - 1) * 1.6
	var player_spawn := Vector3(0.0, 1.2, arena_half - 5.0)

	var shard_count := 5 if boss_level else mini(13, 7 + (slot - 1))
	var enemy_count := (4 + page) if boss_level else mini(9, 2 + ceili(slot * 0.55) + (page - 1) * 2)
	var enemy_health := (2 + page) if boss_level else 2 + int(floor(float(slot - 1) / 3.0)) + (page - 1)
	var enemy_speed := 3.0 + float(slot) * 0.07 + float(page - 1) * 0.25
	var enemy_damage := 12 + slot + (page - 1) * 3
	var respawn := maxf(2.8, 5.6 - float(slot) * 0.16 - float(page - 1) * 0.5)
	if boss_level:
		respawn = 0.0

	var layout := _generate_layout(index, arena_half, shard_count, player_spawn, slot, page)
	var theme := _theme(slot, page)
	var level := {
		"name": NAMES[index - 1],
		"brief": "",
		"arena_half": arena_half,
		"player_spawn": player_spawn,
		"shards": layout["shards"],
		"crates": layout["crates"],
		"walls": layout["walls"],
		"pillars": layout["pillars"],
		"spawns": layout["spawns"],
		"enemy_count": enemy_count,
		"enemy_health": enemy_health,
		"enemy_speed": enemy_speed,
		"enemy_damage": enemy_damage,
		"respawn": respawn,
		"boss_spawn": layout["boss_spawn"],
	}
	level.merge(theme)

	if boss_level:
		var boss_name: String = BOSS_NAMES[page - 1]
		level["name"] = boss_name
		level["boss"] = {
			"name": boss_name,
			"health": 16 + (page - 1) * 10,
			"speed": 3.25 + float(page) * 0.4,
			"damage": 18 + page * 5,
			"scale": 1.7 + float(page) * 0.25,
			"score": 650 + page * 250,
		}
		level["brief"] = "BOSS: %s. Collect %d shards, then destroy the boss." % [boss_name, shard_count]
	else:
		level["brief"] = "Collect %d shards. %d hunters. Clear the sector." % [shard_count, enemy_count]

	return level


static func _theme(slot: int, page: int) -> Dictionary:
	var hue := 0.52 + float(slot - 1) * 0.034
	if page == 2:
		hue = 0.98 + float(slot - 1) * 0.032
	hue = fposmod(hue, 1.0)

	var accent := Color.from_hsv(hue, 0.72, 1.0)
	var secondary := Color.from_hsv(fposmod(hue + 0.42, 1.0), 0.82, 1.0)
	var floor_base := Color(0.025 + accent.r * 0.05, 0.028 + accent.g * 0.045, 0.05 + accent.b * 0.05, 1.0)
	var floor_line := Color(accent.r * 0.82, accent.g * 0.75, accent.b * 0.86, 1.0)
	var wall := Color(0.06 + accent.r * 0.05, 0.06 + accent.g * 0.04, 0.09 + accent.b * 0.05, 1.0)
	var crate := Color(0.1 + accent.r * 0.06, 0.1 + accent.g * 0.05, 0.13 + accent.b * 0.06, 1.0)
	var pillar := Color(0.075 + accent.r * 0.04, 0.07 + accent.g * 0.04, 0.105 + accent.b * 0.05, 1.0)
	var fog := Color(0.035 + accent.r * 0.12, 0.03 + accent.g * 0.1, 0.055 + accent.b * 0.12, 1.0)
	var sky_top := Color(0.018 + accent.r * 0.035, 0.02 + accent.g * 0.035, 0.048 + accent.b * 0.04, 1.0)
	var sky_horizon := Color(0.16 + secondary.r * 0.2, 0.08 + secondary.g * 0.12, 0.18 + secondary.b * 0.18, 1.0)
	var ground_horizon := Color(0.08 + accent.r * 0.1, 0.045 + accent.g * 0.07, 0.1 + accent.b * 0.1, 1.0)
	var sun := Color(1.0, 0.72 + accent.g * 0.16, 0.78 + accent.b * 0.16, 1.0)

	return {
		"accent": accent,
		"floor_base": floor_base,
		"floor_line": floor_line,
		"wall": wall,
		"crate": crate,
		"pillar": pillar,
		"trim_a": accent,
		"trim_b": secondary,
		"fog": fog,
		"sky_top": sky_top,
		"sky_horizon": sky_horizon,
		"ground_horizon": ground_horizon,
		"sun": sun,
		"rim_a": accent,
		"rim_b": secondary,
	}


static func _generate_layout(index: int, half: float, shard_count: int, player_spawn: Vector3, slot: int, page: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 71000 + index * 7919

	var occupied: Array[Vector2] = [Vector2(player_spawn.x, player_spawn.z)]
	var boss_spawn := Vector3(0.0, 1.35, -(half - 5.0))
	if slot == LEVELS_PER_PAGE:
		occupied.append(Vector2(boss_spawn.x, boss_spawn.z))
	var shards: Array[Vector3] = []
	var crates: Array[Vector3] = []
	var walls: Array = []
	var pillars: Array = []

	for i in shard_count:
		var point := _pick_point(rng, half, occupied, 2.7)
		shards.append(Vector3(point.x, 1.25, point.y))
		occupied.append(point)

	var crate_count := 8 + slot + (page - 1) * 2
	for i in crate_count:
		var point := _pick_point(rng, half, occupied, 2.4)
		crates.append(Vector3(point.x, 0.65, point.y))
		occupied.append(point)

	var wall_count := 2 + int(floor(float(slot) / 3.0)) + (page - 1)
	for i in wall_count:
		for attempt in 60:
			var center := _pick_point(rng, half, occupied, 0.1)
			var horizontal := rng.randf() < 0.5
			var length := rng.randf_range(4.0, minf(8.5, half * 0.38))
			var size := Vector3(length, 1.3, 0.7) if horizontal else Vector3(0.7, 1.3, length)
			if not _wall_clear(center, length, horizontal, occupied, 2.1):
				continue
			walls.append(_block(Vector3(center.x, 0.65, center.y), size))
			occupied.append(center)
			var reach := length * 0.5
			if horizontal:
				occupied.append(center + Vector2(reach, 0.0))
				occupied.append(center - Vector2(reach, 0.0))
			else:
				occupied.append(center + Vector2(0.0, reach))
				occupied.append(center - Vector2(0.0, reach))
			break

	var pillar_count := 3 + int(floor(float(slot) / 3.0)) + (page - 1) * 2
	for i in pillar_count:
		var point := _pick_point(rng, half, occupied, 2.9)
		var height := rng.randf_range(3.2, 5.0)
		pillars.append(_block(Vector3(point.x, height * 0.5, point.y), Vector3(1.4, height, 1.4)))
		occupied.append(point)

	var spawns: Array[Vector3] = []
	var spawn_count := 12
	for i in spawn_count:
		var angle := TAU * float(i) / float(spawn_count) + rng.randf_range(-0.1, 0.1)
		var radius := half - 3.0
		var point := Vector2(cos(angle), sin(angle)) * radius
		spawns.append(Vector3(point.x, 0.9, point.y))

	return {
		"shards": shards,
		"crates": crates,
		"walls": walls,
		"pillars": pillars,
		"spawns": spawns,
		"boss_spawn": boss_spawn,
	}


static func _pick_point(rng: RandomNumberGenerator, half: float, occupied: Array[Vector2], clearance: float) -> Vector2:
	var margin := 4.0
	var fallback := Vector2.ZERO
	for attempt in 240:
		var point := Vector2(
			rng.randf_range(-half + margin, half - margin),
			rng.randf_range(-half + margin, half - margin)
		)
		fallback = point
		var clear := true
		for other in occupied:
			if point.distance_to(other) < clearance:
				clear = false
				break
		if clear:
			return point
	return fallback


static func _wall_clear(center: Vector2, length: float, horizontal: bool, occupied: Array[Vector2], clearance: float) -> bool:
	var half_length := length * 0.5
	var samples: Array[Vector2] = [center]
	for step in [-1.0, 0.0, 1.0]:
		if horizontal:
			samples.append(center + Vector2(half_length * step, 0.0))
		else:
			samples.append(center + Vector2(0.0, half_length * step))
	for sample in samples:
		for other in occupied:
			if sample.distance_to(other) < clearance:
				return false
	return true
