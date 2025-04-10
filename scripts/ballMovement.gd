extends CharacterBody2D

# Movement variables
var acceleration: float = 600   # How quickly the ball accelerates
var max_speed: float = 700      # Max normal rolling speed
var friction: float = 0.02      # Friction to slow down over time

# Momentum & physics
var velocity_vector: Vector2 = Vector2.ZERO
var is_grappling: bool = false
var grapple_point: Vector2 = Vector2.ZERO
var swing_strength: float = 1000
var grapple_raycast_node: RayCast2D  # Renamed to avoid conflict
var grapple_drawer: Node2D  # Reference to the GrappleDrawer node

# Time accumulator for momentum buildup
var momentum_accumulator: float = 0.0
var momentum_increase_rate: float = 50.0  # The rate at which momentum increases

func _ready():
	# Access GrappleRaycast node from the root level (Node2D, which is parent of ball)
	grapple_raycast_node = get_node("/root/Level/Player/GrappleRaycast") as RayCast2D
	if grapple_raycast_node == null:
		print("Error: GrappleRaycast node not found!")
	grapple_raycast_node.enabled = false  # Disable the raycast initially

	# Get the GrappleDrawer node from the root
	grapple_drawer = get_node("/root/Level/Player/GrappleDrawer")
	if grapple_drawer == null:
		print("Error: GrappleDrawer node not found!")

func _physics_process(delta):
	# Handle movement input and grappling logic
	if Input.is_action_just_pressed("grapple") and not is_grappling:
		activate_grapple()

	if is_grappling:
		swing(delta)
		# Draw Grapple 
		grapple_drawer.queue_redraw()
	else:
		apply_movement(delta)

	# Apply friction when not moving
	if velocity_vector.length() > 5:
		velocity_vector *= (1 - friction)

	velocity = velocity_vector
	move_and_slide()

	# If grappling, redraw the line
	if is_grappling:
		queue_redraw()

## Movement system when not grappling
func apply_movement(delta):
	var input_vector = Vector2.ZERO
	
	if Input.is_action_pressed("ui_left"):
		input_vector.x = -1
	elif Input.is_action_pressed("ui_right"):
		input_vector.x = 1
	
	if Input.is_action_pressed("ui_up"):
		input_vector.y = -1
	elif Input.is_action_pressed("ui_down"):
		input_vector.y = 1
	
	input_vector = input_vector.normalized()

	if input_vector != Vector2.ZERO:
		# Accelerate in the input direction while preserving momentum
		velocity_vector += input_vector * acceleration * delta
		# Cap speed
		if velocity_vector.length() > max_speed:
			velocity_vector = velocity_vector.normalized() * max_speed

var grapple_max_distance: float = 0.0  # Stores max allowed distance

## Find nearest grapple, if successful activate grappling
func activate_grapple():
	var nearest_grapple = find_nearest_grapple_point()
	if nearest_grapple:
		grapple_point = nearest_grapple.position
		is_grappling = true

		# Store initial distance for max grapple length
		grapple_max_distance = self.global_position.distance_to(grapple_point)

		# Notify GrappleDrawer that we are grappling
		grapple_drawer.is_grappling = true
		grapple_drawer.grapple_point = grapple_point
	else:
		print("No grapple point in range!\n")

## Movement system while grappling
func swing(delta):
	var direction_to_grapple = (self.grapple_point - self.global_position).normalized()
	var current_distance = self.global_position.distance_to(self.grapple_point)
	
	# Maintain the correct grapple distance (don't push ball to initial position)
	if current_distance > self.grapple_max_distance:
		# Ensure the ball stays within the max range without resetting to the initial position
		var correction_vector = (self.global_position - self.grapple_point).normalized() * (current_distance - self.grapple_max_distance)
		self.global_position -= correction_vector  # Adjust ball position to stay within max range
		self.velocity_vector -= correction_vector / delta  # Adjust velocity accordingly

	# Calculate perpendicular (tangential) directions for swinging
	var tangent_dir_1 = Vector2(-direction_to_grapple.y, direction_to_grapple.x)  # Counterclockwise
	var tangent_dir_2 = Vector2(direction_to_grapple.y, -direction_to_grapple.x)  # Clockwise

	# Choose the tangent direction that aligns with the ball's current velocity
	var tangent_direction = tangent_dir_1 if self.velocity_vector.dot(tangent_dir_1) > self.velocity_vector.dot(tangent_dir_2) else tangent_dir_2

	# Apply swing force based on tangential direction
	var swing_force = tangent_direction * self.swing_strength * delta
	self.velocity_vector += swing_force

	# Release grapple when needed
	if Input.is_action_just_pressed("release_grapple"):
		release_grapple()

func release_grapple():
	is_grappling = false
	grapple_raycast_node.enabled = false
	# Call the GrappleDrawer's release_grapple function to stop drawing the line
	grapple_drawer.release_grapple()


func find_nearest_grapple_point():
	var nearest = null
	var min_distance = 200  # Maximum grapple range
	var closest_distance = min_distance  # Store the closest valid point within range
	
	for grapple in get_tree().get_nodes_in_group("grapple_point"):
		if grapple is StaticBody2D:
			var dist = self.global_position.distance_to(grapple.global_position)

			print(grapple)
			print(dist)
			print("---")
			
			# Only consider grapple points that are within range
			if dist <= min_distance and (nearest == null or dist < closest_distance):
				closest_distance = dist
				nearest = grapple
	
	return nearest  # Returns the closest in-range grapple or null if none
