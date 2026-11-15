extends Node
## Persistent campaign state: 2 pages, 10 levels each, boss at the end of a page.

const PAGES := 2
const LEVELS_PER_PAGE := 10
const TOTAL_LEVELS := PAGES * LEVELS_PER_PAGE
const PROGRESS_PATH := "user://campaign.cfg"

var current_level := 1
var unlocked_level := 1
var total_score := 0


func _ready() -> void:
	load_progress()


func start_campaign() -> void:
	current_level = 1
	total_score = 0


func select_level(index: int) -> void:
	current_level = clampi(index, 1, TOTAL_LEVELS)
	total_score = 0


func next_level() -> bool:
	if current_level >= TOTAL_LEVELS:
		return false
	current_level += 1
	return true


func complete_level() -> void:
	unlocked_level = maxi(unlocked_level, mini(current_level + 1, TOTAL_LEVELS))
	save_progress()


func is_final_level() -> bool:
	return current_level >= TOTAL_LEVELS


func page_of(index: int) -> int:
	return clampi(((index - 1) / LEVELS_PER_PAGE) + 1, 1, PAGES)


func slot_of(index: int) -> int:
	return ((index - 1) % LEVELS_PER_PAGE) + 1


func is_boss_level(index: int = -1) -> bool:
	var level := current_level if index < 0 else index
	return slot_of(level) == LEVELS_PER_PAGE


func is_unlocked(index: int) -> bool:
	return index >= 1 and index <= unlocked_level


func is_cleared(index: int) -> bool:
	return index >= 1 and index < unlocked_level


func level_label(index: int = -1) -> String:
	var level := current_level if index < 0 else index
	return "%d-%d" % [page_of(level), slot_of(level)]


func add_score(value: int) -> void:
	total_score += value


func reset_progress() -> void:
	current_level = 1
	unlocked_level = 1
	total_score = 0
	save_progress()


func save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("campaign", "unlocked_level", unlocked_level)
	config.save(PROGRESS_PATH)


func load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(PROGRESS_PATH) == OK:
		unlocked_level = clampi(int(config.get_value("campaign", "unlocked_level", 1)), 1, TOTAL_LEVELS)
	else:
		unlocked_level = 1
