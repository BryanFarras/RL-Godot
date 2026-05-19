extends RayCast3D

var target = get_collider()
var shape_id = get_collider_shape() # The shape index in the collider.

signal on_colliding

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
