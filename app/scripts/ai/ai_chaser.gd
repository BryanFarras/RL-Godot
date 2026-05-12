extends AIController3D


@onready var chaser_body = get_parent() # Assumes this script is a child of the chaser CharacterBody3D
@onready var runner = get_node("../../player_runner")

var last_distance = 0.0
var tagged = false

func get_obs() -> Dictionary:
	var chaser_pos = chaser_body.global_transform.origin
	var runner_pos = runner.global_transform.origin
	var diff = runner_pos - chaser_pos
	last_distance = diff.length()
	return {"obs": [chaser_pos.x, chaser_pos.y, chaser_pos.z, runner_pos.x, runner_pos.y, runner_pos.z, diff.x, diff.y, diff.z]}


func get_reward() -> float:
	# Reward: +1 for tagging, small negative per step to encourage speed
	if tagged:
		tagged = false
		return 1.0
	return -0.01


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
	# --- Movement ---
	# action["move"] is a 2-element array [move_x, move_z] in world space.
	# We write into ai_move_dir which _physics_process reads instead of keyboard input.
	var move_x : float = action["move"][0]
	var move_z : float = action["move"][1]
	chaser_body.ai_move_dir = Vector3(move_x, 0, move_z)

	# --- Jump ---
	# action["jump"] is a discrete float (0.0 = no jump, 1.0 = jump).
	# ai_wants_jump is consumed (cleared) after one physics frame.
	var wants_jump : bool = action["jump"] == 1
	if wants_jump:
		chaser_body.ai_wants_jump = true

# Call this from the chaser script when tagging occurs:
func on_tagged():
	tagged = true
