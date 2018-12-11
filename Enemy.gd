extends KinematicBody

const MOVE_SPEED = 15
const DAMAGE = 15
var damage_timer = 0
onready var raycast = $RayCast
onready var anim_player = $AnimationPlayer

var current_health = 40
var player = null
var dead = false

func _ready():
	anim_player.play("Walk")
	add_to_group("enemies")

func _physics_process(delta):
	if dead:
		return
	if player == null:
		return
	
	var vec_to_player = player.translation - translation
	vec_to_player = vec_to_player.normalized()
	raycast.cast_to = vec_to_player * 1.5
	
	move_and_collide(vec_to_player * MOVE_SPEED * delta)
	if damage_timer > 0:
		damage_timer -= delta
	else:
		if raycast.is_colliding():
			var coll = raycast.get_collider()
			if coll != null and coll.name == "Player":
				coll.bullet_hit(DAMAGE, raycast.get_collision_point())
				damage_timer = 1
	
func bullet_hit(damage, bullet_hit_pos):
	current_health -= damage
	
	# If we're at 0 health or below, we need to spawn the broken target scene
	if current_health <= 0:
		dead = true
		$CollisionShape.disabled = true
		anim_player.play("dead")
		
		

func set_player(p):
	player = p