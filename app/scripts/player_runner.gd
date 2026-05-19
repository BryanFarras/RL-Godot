# Player Runner Script

extends CharacterBody3D

## Can we move around?
@export var can_move : bool = true
## Are we affected by gravity?
@export var has_gravity : bool = true
## Can we press to jump?
@export var can_jump : bool = true
## Can we hold to run?
@export var can_sprint : bool = false

@export_group("Speeds")
## Normal speed.
@export var look_speed : float = 0.002
## Normal speed.
@export var base_speed : float = 3.0

## Acceleration and drag
@export var acceleration : float = 10.0
@export var drag : float = 8.0

## Speed of jump.
@export var jump_velocity : float = 4.5
## How fast do we run?
@export var sprint_speed : float = 5.0

@export_group("Input Actions")
## Name of Input Action to move Left.
@export var input_left : String = "ui_left"
## Name of Input Action to move Right.
@export var input_right : String = "ui_right"
## Name of Input Action to move Forward.
@export var input_forward : String = "ui_up"
## Name of Input Action to move Backward.
@export var input_back : String = "ui_down"
## Name of Input Action to Jump.
@export var input_jump : String = "ui_accept"
## Name of Input Action to Sprint.
@export var input_sprint : String = "sprint"

@export var restart : String = "restart"

var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false

## AI-controlled input — set by ai_runner.gd each physics step.
var ai_move_dir : Vector3 = Vector3.ZERO
var ai_wants_jump : bool = false

## Spawn state — stored on _ready() and restored on reset.
var _spawn_position : Vector3
var _spawn_rotation : Vector3
var _spawn_look_rotation : Vector2

signal restart_game

@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $CollisionShape3D

var has_tagged := false

func _ready() -> void:
	check_input_mappings()
	# Save spawn state for resets
	_spawn_position = global_position
	_spawn_rotation = rotation
	_spawn_look_rotation = look_rotation
	
func _unhandled_input(event: InputEvent) -> void:
	
	# Mouse capturing
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): 
		capture_mouse()
	if Input.is_key_pressed(KEY_ESCAPE):
		release_mouse()

	# Restart round (preserves scores)
	if InputMap.has_action(restart) and Input.is_action_just_pressed(restart):
		reset_state()
		emit_signal("restart_game")
	
	if mouse_captured and event is InputEventMouseMotion:
		rotate_look(event.relative)

func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * look_speed
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))
	look_rotation.y -= rot_input.x * look_speed

	rotation.y = look_rotation.y
	head.rotation.x = look_rotation.x

func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true


func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

func _physics_process(delta: float) -> void:
	# Apply gravity to velocity
	if has_gravity:
		if not is_on_floor():
			velocity += get_gravity() * delta

	# Apply jumping
	if can_jump and is_on_floor():
		var jump_pressed = Input.is_action_just_pressed(input_jump) or ai_wants_jump
		if jump_pressed:
			velocity.y = jump_velocity
	ai_wants_jump = false  # Consume the AI jump request

	# Modify speed based on sprinting
	if can_sprint and Input.is_action_pressed(input_sprint):
		move_speed = sprint_speed
	else:
		move_speed = base_speed
		

	# Apply desired movement to velocity
	if can_move:
		var move_dir : Vector3
		if ai_move_dir != Vector3.ZERO:
			# AI path: ai_move_dir is already a world-space unit vector
			move_dir = ai_move_dir.normalized()
			if move_dir.length() > 0:
				print("[player_runner] using AI move_dir: ", move_dir, " speed: ", move_speed)
		else:
			# Player path: convert keyboard axes to world-space direction
			var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
			var forward = transform.basis.z
			var right = transform.basis.x
			move_dir = (right * input_dir.x + forward * input_dir.y).normalized()
		var target_velocity = Vector3.ZERO
		# Kill sideways drift when switching direction
		var current_horizontal = Vector3(velocity.x, 0, velocity.z)
		if move_dir:
			target_velocity = move_dir * move_speed
			current_horizontal = current_horizontal.project(move_dir)
		# Smooth acceleration
		velocity.x = move_toward(current_horizontal.x, target_velocity.x, acceleration * delta)
		velocity.z = move_toward(current_horizontal.z, target_velocity.z, acceleration * delta)
		# Apply drag when no input
		if not move_dir:
			velocity.x = move_toward(velocity.x, 0, drag * delta)
			velocity.z = move_toward(velocity.z, 0, drag * delta)
		if move_dir.dot(current_horizontal.normalized()) < 0:
			current_horizontal = Vector3.ZERO

	# Use velocity to actually move
	move_and_slide()

## Resets position, velocity, and camera direction to spawn state.
func reset_state() -> void:
	global_position = _spawn_position
	velocity = Vector3.ZERO
	look_rotation = _spawn_look_rotation
	rotation.y = look_rotation.y
	head.rotation.x = look_rotation.x
	has_tagged = false


## Checks if some Input Actions haven't been created.
## Disables functionality accordingly.
func check_input_mappings():
	if can_move and not InputMap.has_action(input_left):
		push_error("Movement disabled. No InputAction found for input_left: " + input_left)
		can_move = false
	if can_move and not InputMap.has_action(input_right):
		push_error("Movement disabled. No InputAction found for input_right: " + input_right)
		can_move = false
	if can_move and not InputMap.has_action(input_forward):
		push_error("Movement disabled. No InputAction found for input_forward: " + input_forward)
		can_move = false
	if can_move and not InputMap.has_action(input_back):
		push_error("Movement disabled. No InputAction found for input_back: " + input_back)
		can_move = false
	if can_jump and not InputMap.has_action(input_jump):
		push_error("Jumping disabled. No InputAction found for input_jump: " + input_jump)
		can_jump = false
	if can_sprint and not InputMap.has_action(input_sprint):
		push_error("Sprinting disabled. No InputAction found for input_sprint: " + input_sprint)
		can_sprint = false


	
