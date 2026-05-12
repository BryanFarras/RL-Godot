extends Control

var chaser_score := 0
var runner_score := 0
@onready var chaser_label = %ChaserScoreLabel
@onready var runner_label = %RunnerScoreLabel

func _ready():
	update_labels()

func _on_runner_tagged():
	chaser_score += 1
	update_labels()

func _on_runner_survived():
	runner_score += 1
	update_labels()

func update_labels():
	chaser_label.text = "Chaser Score: %d" % chaser_score
	runner_label.text = "Runner Score: %d" % runner_score
