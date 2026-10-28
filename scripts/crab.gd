class_name CrabEnemy
extends CharacterBody2D

signal died(enemy: CrabEnemy)
signal health_changed(current: int, max_val: int)

@export_group("Estatísticas")
@export var max_health: int = 40
@export var damage: int = 15
@export var move_speed: float = 65.0
@export var detection_range: float = 180.0
@export var attack_range: float = 24.0
@export var attack_cooldown: float = 1.0
@export var is_king_crab: bool = false

@export_group("Física")
@export var acceleration: float = 400.0
@export var friction: float = 600.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hit_area: Area2D = $HitArea

enum State { IDLE, CHASE, ATTACK, HURT, DEAD }
var current_state: State = State.IDLE

var current_health: int
var player_target: Node2D = null
var _attack_timer: float = 0.0
var _hurt_timer: float = 0.0


func _ready() -> void:
	add_to_group("enemies")
	
	if is_king_crab:
		max_health = 100
		damage = 25
		move_speed = 50.0
		scale = Vector2(1.6, 1.6)
		modulate = Color(1.3, 0.9, 0.8)

	current_health = max_health

	if hit_area:
		hit_area.body_entered.connect(_on_hit_area_body_entered)

	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animation_finished)
		animated_sprite.play("idle")


func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		move_and_slide()
		return

	if _attack_timer > 0.0:
		_attack_timer -= delta

	if current_state == State.HURT:
		_hurt_timer -= delta
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		move_and_slide()
		if _hurt_timer <= 0.0:
			current_state = State.CHASE
		return

	_ensure_player_target()

	if player_target == null or (player_target is Player and player_target.is_dead):
		current_state = State.IDLE
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		move_and_slide()
		_play_anim("idle")
		return

	var dist_to_player: float = global_position.distance_to(player_target.global_position)
	var dir_to_player: Vector2 = (player_target.global_position - global_position).normalized()

	match current_state:
		State.IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
			move_and_slide()
			_play_anim("idle")
			if dist_to_player <= detection_range:
				current_state = State.CHASE

		State.CHASE:
			if dist_to_player > detection_range * 1.6:
				current_state = State.IDLE
				return

			if dist_to_player <= attack_range and _attack_timer <= 0.0:
				_start_attack(dir_to_player)
				return

			# Persegue o jogador
			velocity = velocity.move_toward(dir_to_player * move_speed, acceleration * delta)
			move_and_slide()
			_update_facing(dir_to_player)
			_play_anim("walk")

		State.ATTACK:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
			move_and_slide()


func _ensure_player_target() -> void:
	if player_target != null and is_instance_valid(player_target):
		return
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		player_target = players[0]


func _update_facing(dir: Vector2) -> void:
	if animated_sprite and absf(dir.x) > 0.1:
		animated_sprite.flip_h = dir.x < 0.0


func _play_anim(anim_name: StringName) -> void:
	if animated_sprite and animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)


func _start_attack(dir: Vector2) -> void:
	current_state = State.ATTACK
	_attack_timer = attack_cooldown
	_update_facing(dir)

	if animated_sprite and animated_sprite.sprite_frames.has_animation(&"attack"):
		animated_sprite.play(&"attack")

	# Dá o golpe no jogador se estiver próximo
	if player_target and is_instance_valid(player_target):
		var dist: float = global_position.distance_to(player_target.global_position)
		if dist <= attack_range + 8.0 and player_target.has_method("take_damage"):
			var knock_dir: Vector2 = (player_target.global_position - global_position).normalized()
			player_target.take_damage(damage, knock_dir)


func _on_animation_finished() -> void:
	if current_state == State.ATTACK:
		current_state = State.CHASE
	elif current_state == State.HURT:
		current_state = State.CHASE


## Causa dano de contato caso o jogador encoste diretamente no caranguejo
func _on_hit_area_body_entered(body: Node2D) -> void:
	if current_state == State.DEAD:
		return
	if body.is_in_group("player") and body.has_method("take_damage") and _attack_timer <= 0.2:
		var knock_dir: Vector2 = (body.global_position - global_position).normalized()
		body.take_damage(damage, knock_dir)
		_attack_timer = attack_cooldown


## Recebe dano do jogador
func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	if current_state == State.DEAD:
		return

	current_health = clampi(current_health - amount, 0, max_health)
	health_changed.emit(current_health, max_health)

	# Efeito de empurrão
	velocity = knockback_dir * 180.0

	# Flash visual
	if animated_sprite:
		var tween := create_tween()
		tween.tween_property(animated_sprite, "modulate", Color(2.5, 0.4, 0.4, 1.0), 0.08)
		tween.tween_property(animated_sprite, "modulate", Color.WHITE if not is_king_crab else Color(1.3, 0.9, 0.8), 0.1)

	if current_health <= 0:
		_die()
	else:
		current_state = State.HURT
		_hurt_timer = 0.25
		if animated_sprite and animated_sprite.sprite_frames.has_animation(&"hurt"):
			animated_sprite.play(&"hurt")


func _die() -> void:
	current_state = State.DEAD
	velocity = Vector2.ZERO

	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if hit_area:
		hit_area.set_deferred("monitoring", false)

	if animated_sprite and animated_sprite.sprite_frames.has_animation(&"die"):
		animated_sprite.play(&"die")

	died.emit(self)

	# Animação de desvanecimento suave
	var death_tween := create_tween()
	death_tween.tween_property(self, "modulate:a", 0.0, 0.6)
	death_tween.finished.connect(queue_free)
