extends Spatial
var enemy = preload("res://Enemy.tscn")
var spawn_timer = 0
var enemies_spawned = 1
var player = null

func _ready():
	add_to_group("spawner")

func _process(delta):
	if spawn_timer > 0:
		spawn_timer -= delta
	else:
		if enemies_spawned > 0:
			enemies_spawned -= 1
			var enemy_clone = enemy.instance()
			get_node("/root").add_child(enemy_clone)
			enemy_clone.global_transform = $Spawn_Point.global_transform
			yield(get_tree(), "idle_frame")	
			get_tree().call_group("enemies", "set_player", player)
		else:
			enemies_spawned = 1
			spawn_timer = 5

func set_player(p):
	player = p
	yield(get_tree(), "idle_frame")	
	get_tree().call_group("enemies", "set_player", player)