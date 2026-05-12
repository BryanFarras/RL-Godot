extends Node

@onready var timer = $CanvasLayer/Timer
@onready var score = $CanvasLayer/Scores

var chasers: Array = []
var runners: Array = []
var games: Array = []

func _ready():
	# Collect all chaser and game references
	for i in range(1, 10):  # Games 1-10
		var game_path = "Game" if i == 1 else "Game%d" % i
		var game = get_node_or_null(game_path)
		
		if game == null:
			push_error("Game node not found: %s" % game_path)
			continue
		
		var chaser = game.get_node_or_null("player_chaser")
		if chaser == null:
			push_error("Chaser not found in %s" % game_path)
			continue
		
		var runner = game.get_node_or_null("player_runner")
		if runner == null:
			push_error("Runner not found in %s" % game_path)
			continue
		
		chasers.append(chaser)
		runners.append(runner)
		games.append(game)
	
	print("Loaded %d games and chasers" % chasers.size())
	
	var main_chaser = chasers[0]
	var main_runner = runners[0]
	
	# Connect all chasers to UI (any chaser tagging triggers reset)
	for chaser in chasers:
		chaser.runner_tagged.connect(timer._on_runner_tagged)
		chaser.runner_tagged.connect(score._on_runner_tagged)
	
	main_chaser.restart_game.connect(timer._on_restart_game)
	
	# Connect timer to UI and reset
	timer.runner_survived.connect(score._on_runner_survived)
	
	# Connect timer to all chasers for synchronized resets
	for chaser in chasers:
		timer.restart_game.connect(chaser.reset_state)

	for runner in runners:
		timer.restart_game.connect(runner.reset_state)
	
	# Connect timer to all games for synchronized restarts
	for game in games:
		timer.runner_survived.connect(game._on_timer_restart_game)
