extends CharacterBody2D

# Player movement constants
const SPEED = 200.0
const ACCELERATION = 800.0
const FRICTION = 600.0

func _physics_process(delta):
	# Get input direction
	var input_dir = Vector2.ZERO
	input_dir.x = Input.get_axis("ui_left", "ui_right")
	input_dir.y = Input.get_axis("ui_up", "ui_down")
	
	# Normalize so diagonal movement isn't faster
	if input_dir.length() > 0:
		input_dir = input_dir.normalized()
		velocity = velocity.move_toward(input_dir * SPEED, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	
	move_and_slide()
