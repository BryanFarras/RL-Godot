extends Node

@onready var player_chaser = $player_chaser
@onready var player_runner = $player_runner

func _ready():
	pass

## Called when the chaser presses the restart key.
## Resets player positions, velocities, directions, and the timer.
func _on_restart_game() -> void:
	player_chaser.reset_state()
	if player_runner and player_runner.has_method("reset_state"):
		player_runner.reset_state()

func _on_timer_restart_game() -> void:
	player_chaser.reset_state()
	if player_runner and player_runner.has_method("reset_state"):
		player_runner.reset_state()