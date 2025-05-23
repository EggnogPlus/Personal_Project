extends Camera2D

var shake_amount: float = 0.0
var shake_decay: float = 5.0
var original_position := Vector2.ZERO

func _ready():
	original_position = position  # Save the starting point

func _process(delta):
	# If start_shake called with an amount > 0 - apply shake amount to random direction vector
	# lerp over time to decay shake effect and shake amount
	# reset camera position once shake amount = 0
	if shake_amount > 0:
		position = original_position + Vector2(
			randf_range(-1, 1),
			randf_range(-1, 1)
		) * shake_amount
		shake_amount = lerp(shake_amount, 0.0, shake_decay * delta)
	else:
		position = original_position

func start_shake(amount: float):
	shake_amount = amount
