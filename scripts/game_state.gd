extends Node
## Persistent campaign state shared between the menu and level scenes.

const TOTAL_LEVELS := 3

var current_level := 1
var total_score := 0


func start_campaign() -> void:
	current_level = 1
	total_score = 0


func next_level() -> bool:
	if current_level >= TOTAL_LEVELS:
		return false
	current_level += 1
	return true


func is_final_level() -> bool:
	return current_level >= TOTAL_LEVELS


func add_score(value: int) -> void:
	total_score += value
