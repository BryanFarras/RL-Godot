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
	done = true
	needs_reset = true


func on_tagged():
	tagged = true
	done = true
	needs_reset = true


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
	
	var desired_move = Vector3(move_x, 0, move_z)
	
	if desired_move.length() < 0.01:
		player_runner.ai_move_dir = Vector3.ZERO
		return
		
	# Calculate repulsive forces from raycasts in world space
	var repulsion = Vector3.ZERO
	var rays = [
		{"node": ray_front, "local_dir": Vector3(0, 0, -1)},
		{"node": ray_back, "local_dir": Vector3(0, 0, 1)},
		{"node": ray_right, "local_dir": Vector3(1, 0, 0)},
		{"node": ray_left, "local_dir": Vector3(-1, 0, 0)},
	]
	
	for ray_info in rays:
		var ray = ray_info["node"]
		if ray.is_colliding():
			var col_point = ray.get_collision_point()
			var dist = ray.global_position.distance_to(col_point)
			dist = max(dist, 0.1) # Avoid division by zero
			
			# Hyperbolic weight: (max_range - dist) / dist
			var weight = (2.0 - dist) / dist
			var world_dir = player_runner.global_transform.basis * ray_info["local_dir"]
			world_dir = world_dir.normalized()
			
			# Add repulsive force (opposite to the ray direction)
			repulsion += -world_dir * weight * 1.5
			
	var final_move = desired_move + repulsion
	
	# If we are close to a wall, project the evasion direction onto the tangent of the wall
	if repulsion.length() > 0.5:
		var chaser_pos = chaser.global_transform.origin
		var runner_pos = player_runner.global_transform.origin
		var away_from_chaser = (runner_pos - chaser_pos).normalized()
		
		# Wall normal vector pointing out of the wall (away from obstacle)
		var wall_normal = -repulsion.normalized()
		
		# Project away_from_chaser onto the plane perpendicular to the wall normal (tangent)
		var tangent = away_from_chaser - away_from_chaser.project(wall_normal)
		if tangent.length() > 0.1:
			final_move = final_move.lerp(tangent.normalized() * desired_move.length(), 0.6)
			
	player_runner.ai_move_dir = final_move.normalized() * desired_move.length()
	# print("[ai_runner] set_action - move: ", Vector2(move_x, move_z), " ai_move_dir: ", player_runner.ai_move_dir)

	# action["jump"] is a discrete float (0.0 = no jump, 1.0 = jump).
	# ai_wants_jump is consumed (cleared) after one physics frame.
	var wants_jump : bool = action["jump"] == 1
	if wants_jump:
		player_runner.ai_wants_jump = true
		# print("[ai_runner] jump requested")
