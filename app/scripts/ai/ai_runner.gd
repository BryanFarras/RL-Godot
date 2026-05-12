extends AIController3D

@onready var player_runner: CharacterBody3D = $".."
@onready var chaser = get_node("../../player_chaser")

var last_distance = 0.0
var distance_delta = 0.0  # positive = got farther from chaser this step

func get_obs() -> Dictionary:
	var runner_pos = player_runner.global_transform.origin
	var chaser_pos = chaser.global_transform.origin
	var diff = runner_pos - chaser_pos
	var current_distance = diff.length()
	# Positive when runner moved away from chaser since last step
	distance_delta = current_distance - last_distance
	last_distance = current_distance
	return {"obs": [runner_pos.x, runner_pos.y, runner_pos.z, chaser_pos.x, chaser_pos.y, chaser_pos.z, diff.x, diff.y, diff.z]}


func get_reward() -> float:
	# Shape reward: positive for moving away from chaser, negative for moving closer
	# Scaled by 0.1 so step shaping stays well below any major rewards
	return distance_delta * 0.1 - 0.01


func get_action_space() -> Dictionary:
	# move: continuous 2D (X, Z world axes)
	# jump: discrete 1 value (0 = no jump, 1 = jump)
	return {
		"move": {
			"size": 2,
			"action_type": "continuous"
		},
		"jump": {
			"size": 1,
			"action_type": "discrete"
		}
	}


func set_action(action) -> void:
	# Debug: verify action structure
	if not action.has("move") or not action.has("jump"):
		push_error("Invalid action format. Expected 'move' and 'jump' keys. Got: ", action.keys())
		return

	# --- Movement ---
	# action["move"] is a 2-element array [move_x, move_z] in world space.
	# We write into ai_move_dir which _physics_process reads instead of keyboard input.
	var move_x : float = action["move"][0]
	var move_z : float = action["move"][1]
	player_runner.ai_move_dir = Vector3(move_x, 0, move_z)
	print("[ai_runner] set_action - move: ", Vector2(move_x, move_z), " ai_move_dir: ", player_runner.ai_move_dir)

	# --- Jump ---
	# action["jump"] is a discrete float (0.0 = no jump, 1.0 = jump).
	# ai_wants_jump is consumed (cleared) after one physics frame.
	var wants_jump : bool = action["jump"] == 1
	if wants_jump:
		player_runner.ai_wants_jump = true
		print("[ai_runner] jump requested")
