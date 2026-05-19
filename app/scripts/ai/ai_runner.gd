extends AIController3D

@onready var player_runner: CharacterBody3D = $".."
@onready var chaser = get_node("../../player_chaser")

@onready var ray_front = $"../Sensors/RayFront"
@onready var ray_back = $"../Sensors/RayBack"
@onready var ray_right = $"../Sensors/RayRight"
@onready var ray_left = $"../Sensors/RayLeft"

var last_distance = 0.0
var distance_delta = 0.0  # positive = got farther from chaser this step
var survived = false
var tagged = false

func get_obs() -> Dictionary:
	var runner_pos = player_runner.global_transform.origin
	var chaser_pos = chaser.global_transform.origin
	var diff = runner_pos - chaser_pos
	var current_distance = diff.length()
	# Positive when runner moved away from chaser since last step
	distance_delta = current_distance - last_distance
	last_distance = current_distance
	
	var obs = [runner_pos.x, runner_pos.y, runner_pos.z, chaser_pos.x, chaser_pos.y, chaser_pos.z, diff.x, diff.y, diff.z]
	
	# Add raycast distances to observations
	for ray in [ray_front, ray_back, ray_right, ray_left]:
		if ray.is_colliding():
			var dist = ray.global_position.distance_to(ray.get_collision_point())
			obs.append(dist)
		else:
			# Target position length is 2 for all rays
			obs.append(2.0)
			
	return {"obs": obs}


func get_reward() -> float:
	# Shape reward: positive for moving away from chaser, negative for moving closer
	# Scaled by 0.1 so step shaping stays well below any major rewards
	var reward = distance_delta * 0.1 - 0.01
	if survived:
		survived = false
		reward += 10.0
	if tagged:
		tagged = false
		reward -= 10.0
	return reward


func on_survived():
	survived = true


func on_tagged():
	tagged = true


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

	# action["move"] is a 2-element array [move_x, move_z] in world space.
	# We write into ai_move_dir which _physics_process reads instead of keyboard input.
	var move_x : float = action["move"][0]
	var move_z : float = action["move"][1]
	
	var final_move = Vector3(move_x, 0, move_z)
	
	# Convert world move to local space
	var local_move = player_runner.global_transform.basis.inverse() * final_move
	
	var chaser_pos = chaser.global_transform.origin
	var runner_pos = player_runner.global_transform.origin
	var to_chaser_local = player_runner.global_transform.basis.inverse() * (chaser_pos - runner_pos)
	
	# Wall avoidance logic
	# Front wall (-Z)
	if ray_front.is_colliding() and local_move.z < 0:
		local_move.z = 0
		if abs(local_move.x) < 0.1:
			local_move.x = 1.0 if to_chaser_local.x < 0 else -1.0 # run away from chaser
		else:
			local_move.x = sign(local_move.x) * 1.0
			
	# Back wall (+Z)
	if ray_back.is_colliding() and local_move.z > 0:
		local_move.z = 0
		if abs(local_move.x) < 0.1:
			local_move.x = 1.0 if to_chaser_local.x < 0 else -1.0
		else:
			local_move.x = sign(local_move.x) * 1.0
			
	# Right wall (+X)
	if ray_right.is_colliding() and local_move.x > 0:
		local_move.x = 0
		if abs(local_move.z) < 0.1:
			local_move.z = 1.0 if to_chaser_local.z < 0 else -1.0
		else:
			local_move.z = sign(local_move.z) * 1.0
			
	# Left wall (-X)
	if ray_left.is_colliding() and local_move.x < 0:
		local_move.x = 0
		if abs(local_move.z) < 0.1:
			local_move.z = 1.0 if to_chaser_local.z < 0 else -1.0
		else:
			local_move.z = sign(local_move.z) * 1.0
			
	final_move = player_runner.global_transform.basis * local_move
	
	player_runner.ai_move_dir = final_move
	# print("[ai_runner] set_action - move: ", Vector2(move_x, move_z), " ai_move_dir: ", player_runner.ai_move_dir)

	# action["jump"] is a discrete float (0.0 = no jump, 1.0 = jump).
	# ai_wants_jump is consumed (cleared) after one physics frame.
	var wants_jump : bool = action["jump"] == 1
	if wants_jump:
		player_runner.ai_wants_jump = true
		# print("[ai_runner] jump requested")
