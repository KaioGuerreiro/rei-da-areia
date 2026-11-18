class_name Player
extends CharacterBody2D

signal health_changed(current_health: int, max_health: int)
signal died

@export_group("Movimento")
@export var walk_speed: float = 110.0
@export var run_speed: float = 175.0
@export var acceleration: float = 950.0
@export var friction: float = 1100.0

@export_group("Combate")
@export var max_health: int = 100
@export var attack_damage: int = 25
@export var attack_friction: float = 850.0
@export var invulnerability_duration: float = 0.8

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var golpe: ColorRect = $AttackArea/Golpe
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

enum State { MOVE, ATTACK, DEAD }
var current_state: State = State.MOVE

var current_health: int
var is_invulnerable: bool = false
var is_dead: bool = false

var _facing: String = "frente"
var _hit_enemies: Array[Node2D] = []


func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)

	attack_area.position = Vector2.ZERO
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.play("idle_frente")


func _physics_process(delta: float) -> void:
	match current_state:
		State.MOVE:
			_process_move(delta)
		State.ATTACK:
			velocity = velocity.move_toward(Vector2.ZERO, attack_friction * delta)
			move_and_slide()
		State.DEAD:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
			move_and_slide()


func _process_move(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if input_dir != Vector2.ZERO:
		_update_facing(input_dir)

	if Input.is_action_just_pressed("attack"):
		_start_attack()
		return

	if input_dir != Vector2.ZERO:
		var target_speed := run_speed if Input.is_action_pressed("run") else walk_speed
		velocity = velocity.move_toward(input_dir * target_speed, acceleration * delta)
		var speed_scale := clampf(1.6 * (velocity.length() / maxf(walk_speed, 1.0)), 0.5, 3.0)
		_play_anim("andar_" + _facing, speed_scale)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		_play_anim("idle_" + _facing)

	move_and_slide()


func _start_attack() -> void:
	current_state = State.ATTACK
	_hit_enemies.clear()

	# Mostra o clarão do golpe rapidamente
	golpe.visible = true
	get_tree().create_timer(0.1).timeout.connect(func():
		if is_instance_valid(golpe):
			golpe.visible = false
	)

	# Acerta inimigos que já estão dentro da área
	for body in attack_area.get_overlapping_bodies():
		_hit_enemy(body)

	animated_sprite.speed_scale = 1.6
	animated_sprite.play("ataque_" + _facing)


func _on_animation_finished() -> void:
	if current_state == State.ATTACK:
		_hit_enemies.clear()
		current_state = State.MOVE


func _on_attack_area_body_entered(body: Node2D) -> void:
	if current_state == State.ATTACK:
		_hit_enemy(body)


func _hit_enemy(body: Node2D) -> void:
	if body == self or _hit_enemies.has(body):
		return
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		_hit_enemies.append(body)
		var knock_dir := global_position.direction_to(body.global_position)
		body.take_damage(attack_damage, knock_dir)


func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	if is_dead or is_invulnerable:
		return

	current_health = maxi(current_health - amount, 0)
	health_changed.emit(current_health, max_health)
	velocity = knockback_dir * 220.0

	if current_health == 0:
		_die()
	else:
		_start_invulnerability()


func _start_invulnerability() -> void:
	is_invulnerable = true
	var tween := create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(2.0, 0.3, 0.3), 0.08)

	var blinks := maxi(int((invulnerability_duration - 0.08) / 0.16), 1)
	for i in range(blinks):
		tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 0.3), 0.08)
		tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.08)

	tween.finished.connect(func(): is_invulnerable = false)


func _die() -> void:
	is_dead = true
	current_state = State.DEAD
	attack_area.set_deferred("monitoring", false)
	collision_shape.set_deferred("disabled", true)

	var tween := create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(0.8, 0.1, 0.1, 0.0), 0.8)
	died.emit()


func _update_facing(dir: Vector2) -> void:
	if absf(dir.x) >= absf(dir.y):
		_facing = "lado"
		animated_sprite.flip_h = dir.x < 0.0
	else:
		_facing = "atras" if dir.y < 0.0 else "frente"
		animated_sprite.flip_h = false


func _play_anim(anim_name: String, speed_scale: float = 1.0) -> void:
	if animated_sprite.animation != anim_name or not animated_sprite.is_playing():
		animated_sprite.play(anim_name)
	animated_sprite.speed_scale = speed_scale
