extends Node

@export var enemy_scene: PackedScene
@export var spawn_points: Array[Node2D]
@export var spawn_interval: float = 2.0

var timer := 0.0

func _process(delta):
	timer += delta
	if timer >= spawn_interval:
		timer = 0.0
		spawn_enemy()

func spawn_enemy():
	if enemy_scene and spawn_points.size() > 0:
		var spawn_point = spawn_points.pick_random()
		var enemy = enemy_scene.instantiate()
		enemy.global_position = spawn_point.global_position
		get_tree().current_scene.add_child(enemy)
