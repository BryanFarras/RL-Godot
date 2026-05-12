extends Control

@onready var timer = %Timer
@onready var label = %TimerLabel

signal restart_game
signal runner_survived

var is_finished := false

func _ready():
	timer.start()
	update_label()
	
func _process(delta):
	if not is_finished:
		update_label()

func update_label():
	if timer.time_left > 0:
		label.text = "Timer: %.1f" % timer.time_left
	else:
		emit_signal("runner_survived")
		label.text = "Runner Wins!"
		is_finished = true
		print("Runner Wins!")
		restart_delay()

## Restarts the countdown; called by game.gd on restart without resetting scores.
func reset():
	is_finished = false
	timer.start()
	# Use wait_time because time_left is still 0 on the same frame as start()
	label.text = "Timer: %.1f" % timer.wait_time

func _on_runner_tagged():
	timer.stop()
	label.text = "Tagged!"
	is_finished = true
	print("Runner Got Tagged!")
	restart_delay()

func _on_restart_game() -> void:
	reset()

func restart_delay():
	emit_signal("restart_game")
	reset()

