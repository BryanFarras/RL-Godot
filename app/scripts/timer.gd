extends Control

@onready var timer = %Timer
@onready var label = %TimerLabel

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
		label.text = "Runner Wins!"
		is_finished = true
		print("Runner Wins!")

func _on_runner_tagged():
	timer.stop()
	label.text = "Tagged!"
	is_finished = true
	print("Tagged!")
