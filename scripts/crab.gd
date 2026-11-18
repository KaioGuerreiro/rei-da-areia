class_name CrabEnemy
extends CharacterBody2D

signal died(enemy: CrabEnemy)

@export_group("Estatísticas")
@export var max_health: int = 40
@export var damage: int = 15
@export var move_speed: float = 65.0
@export var attack_range: float = 24.0
@export var attack_cooldown: float = 1.0

@export_group("Física")
@export var acceleration: float = 400.0
@export var friction: float = 600.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var navigation_agent: NavigationAgent2D = get_node_or_null("NavigationAgent2D")

enum State { CHASE, ATTACK, HURT, DEAD }
var current_state: State = State.CHASE

var current_health: int
var player_target: Node2D = null
var _attack_timer: float = 0.0
var _nav_update_timer: float = 0.0
var _flash_tween: Tween = null


func _ready() -> void:
	add_to_group("enemies")
	current_health = max_health
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.play("walk")


func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return

	_attack_timer = maxf(_attack_timer - delta, 0.0)

	match current_state:
		State.CHASE:
			_process_chase(delta)
		State.ATTACK, State.HURT:
			_stop(delta)


func _process_chase(delta: float) -> void:
	if not is_instance_valid(player_target):
		player_target = get_tree().get_first_node_in_group("player")

	if player_target == null or (player_target is Player and player_target.is_dead):
		_stop(delta)
		_play_anim("idle")
		return

	var dist := global_position.distance_to(player_target.global_position)
	var dir_to_player := global_position.direction_to(player_target.global_position)

	if dist <= attack_range and _attack_timer <= 0.0:
		_attack(dir_to_player)
		return

	var move_dir := _get_move_direction(delta, dir_to_player)
	velocity = velocity.move_toward(move_dir * move_speed, acceleration * delta)
	move_and_slide()

	_update_facing(move_dir.x)
	_play_anim("walk")


## Calcula a direção contornando obstáculos com NavigationAgent2D (recalcula 5x/s)
func _get_move_direction(delta: float, fallback_dir: Vector2) -> Vector2:
	if not navigation_agent:
		return fallback_dir

	_nav_update_timer -= delta
	if _nav_update_timer <= 0.0:
		_nav_update_timer = 0.2
		navigation_agent.target_position = player_target.global_position

	var nav_dir := global_position.direction_to(navigation_agent.get_next_path_position())
	return nav_dir if nav_dir != Vector2.ZERO else fallback_dir


func _attack(dir: Vector2) -> void:
	current_state = State.ATTACK
	_attack_timer = attack_cooldown
	_update_facing(dir.x)
	animated_sprite.play("attack")

	if player_target.has_method("take_damage"):
		player_target.take_damage(damage, dir)


func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	if current_state == State.DEAD:
		return

	current_health = maxi(current_health - amount, 0)
	velocity = knockback_dir * 180.0
	_flash_red()

	if current_health == 0:
		_die()
	else:
		current_state = State.HURT
		animated_sprite.play("hurt")


func _die() -> void:
	current_state = State.DEAD
	velocity = Vector2.ZERO
	remove_from_group("enemies")
	collision_shape.set_deferred("disabled", true)

	animated_sprite.play("die")
	died.emit(self)

	# Desaparece suavemente antes de sair da cena
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.6)
	tween.finished.connect(queue_free)


func _on_animation_finished() -> void:
	if current_state in [State.ATTACK, State.HURT]:
		current_state = State.CHASE


func _stop(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	move_and_slide()


func _update_facing(dir_x: float) -> void:
	if absf(dir_x) > 0.1:
		animated_sprite.flip_h = dir_x < 0.0


func _play_anim(anim_name: String) -> void:
	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)


func _flash_red() -> void:
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_property(animated_sprite, "modulate", Color(2.5, 0.4, 0.4), 0.08)
	_flash_tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.1)
