class_name Player
extends CharacterBody2D

## Sinais de Combate
signal health_changed(current_health: int, max_health: int)
signal died

## Configurações de Movimento
@export_group("Movimento")
@export var walk_speed: float = 110.0
@export var run_speed: float = 175.0
@export var acceleration: float = 950.0
@export var friction: float = 1100.0

## Dinamismo das Animações
@export_group("Dinamismo das Animações")
## Escala de velocidade base da animação de caminhada (~8 FPS)
@export var walk_anim_speed_scale: float = 1.6
## Efeito sutil de squash & stretch ao iniciar, frear e atacar
@export var enable_squash_stretch: bool = true
## Leve inclinação lateral dinâmica na direção do movimento
@export var enable_tilt: bool = true
@export var max_tilt_degrees: float = 3.5

## Combate e Vida
@export_group("Combate")
@export var max_health: int = 100
@export var attack_damage: int = 25
@export var attack_friction: float = 850.0
@export var attack_anim_speed_scale: float = 1.6
@export var invulnerability_duration: float = 0.8
@export var attack_range_offset: float = 12.0

## Referências aos Nós Filhos
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

## Estados e Direções
enum State { MOVE, ATTACK, DEAD }
enum Facing { DOWN, UP, SIDE }

var current_state: State = State.MOVE
var current_facing: Facing = Facing.DOWN
var is_facing_left: bool = false

# Saúde e Invulnerabilidade
var current_health: int
var is_invulnerable: bool = false
var is_dead: bool = false

# Controles internos de dinamismo
var _was_moving: bool = false
var _target_rotation: float = 0.0
var _hit_enemies: Array[Node2D] = []
var _invulnerability_tween: Tween


func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)
	_setup_input_actions()

	if attack_area:
		attack_area.monitoring = true
		attack_area.body_entered.connect(_on_attack_area_body_entered)
		_update_attack_hitbox_position()

	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animation_finished)
		animated_sprite.animation_looped.connect(_on_animation_looped)
		_ensure_attack_animations_no_loop()
		_play_idle_animation()


func _physics_process(delta: float) -> void:
	match current_state:
		State.MOVE:
			_process_move_state(delta)
		State.ATTACK:
			_process_attack_state(delta)
		State.DEAD:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
			move_and_slide()

	_apply_visual_dynamics(delta)


## Processa movimentação, aceleração, desaceleração e transição de animações
func _process_move_state(delta: float) -> void:
	var input_vector: Vector2 = _get_input_vector()

	# Se houver comando de movimento, atualiza imediatamente a direção do personagem e da área de ataque
	if input_vector != Vector2.ZERO:
		_update_facing_direction(input_vector)

	# Gatilho de ataque
	if _is_attack_pressed():
		_start_attack()
		return

	var is_moving: bool = input_vector != Vector2.ZERO
	var is_running: bool = _is_run_pressed() and is_moving
	var target_speed: float = run_speed if is_running else walk_speed

	# Aceleração e desaceleração suaves
	if is_moving:
		velocity = velocity.move_toward(input_vector * target_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()

	# Dinamismo de Squash & Stretch na transição de movimento
	if is_moving and not _was_moving:
		_trigger_squash_stretch(Vector2(0.88, 1.12))
	elif not is_moving and _was_moving:
		_trigger_squash_stretch(Vector2(1.12, 0.88))
	_was_moving = is_moving

	# Atualiza animação com base na velocidade
	if is_moving:
		_play_walk_animation(target_speed)
	else:
		_play_idle_animation()

	# Inclinação lateral dinâmica (tilt)
	if enable_tilt:
		if absf(velocity.x) > 10.0:
			var dir_sign: float = -1.0 if velocity.x < 0.0 else 1.0
			var tilt_ratio: float = clampf(absf(velocity.x) / run_speed, 0.0, 1.0)
			_target_rotation = deg_to_rad(dir_sign * max_tilt_degrees * tilt_ratio)
		else:
			_target_rotation = 0.0


## Processa desaceleração durante o ataque
func _process_attack_state(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, attack_friction * delta)
	move_and_slide()


## Inicia ataque na direção atual com ativação da hitbox
func _start_attack() -> void:
	current_state = State.ATTACK
	_apply_sprite_orientation()
	_update_attack_hitbox_position()

	# Limpa lista de inimigos atingidos neste golpe
	_hit_enemies.clear()

	# Imediatamente checa quaisquer inimigos que já estejam dentro da área de ataque
	if attack_area:
		for body in attack_area.get_overlapping_bodies():
			_damage_enemy_if_valid(body)

	var anim_name: StringName = _get_animation_name("ataque")
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.speed_scale = attack_anim_speed_scale
		animated_sprite.play(anim_name)
	else:
		_end_attack()
		return

	# Pequeno impacto elástico no início do ataque
	_trigger_squash_stretch(Vector2(1.15, 0.9))


## Finaliza o estado de ataque
func _end_attack() -> void:
	_hit_enemies.clear()

	if current_state == State.ATTACK:
		current_state = State.MOVE
		var input_vector: Vector2 = _get_input_vector()
		if input_vector != Vector2.ZERO:
			_update_facing_direction(input_vector)
			_play_walk_animation(run_speed if _is_run_pressed() else walk_speed)
		else:
			_play_idle_animation()


func _on_animation_finished() -> void:
	if current_state == State.ATTACK:
		_end_attack()


func _on_animation_looped() -> void:
	if current_state == State.ATTACK:
		_end_attack()


## Callback da área de ataque ao colidir com corpos
func _on_attack_area_body_entered(body: Node2D) -> void:
	if current_state != State.ATTACK:
		return
	_damage_enemy_if_valid(body)


## Aplica dano a um inimigo caso seja válido e ainda não tenha sido atingido neste ataque
func _damage_enemy_if_valid(body: Node2D) -> void:
	if body == self or _hit_enemies.has(body):
		return

	if body.is_in_group("enemies") and body.has_method("take_damage"):
		_hit_enemies.append(body)
		var knockback_dir: Vector2 = (body.global_position - global_position).normalized()
		if knockback_dir == Vector2.ZERO:
			knockback_dir = _get_facing_vector()
		body.take_damage(attack_damage, knockback_dir)


## Recebe dano de inimigos ou perigos
func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	if is_dead or is_invulnerable:
		return

	current_health = clampi(current_health - amount, 0, max_health)
	health_changed.emit(current_health, max_health)

	# Efeito de impacto no corpo
	_trigger_squash_stretch(Vector2(1.2, 0.8))

	# Aplica empurrão (knockback)
	if knockback_dir != Vector2.ZERO:
		velocity = knockback_dir * 220.0

	# Flash vermelho de dano
	if animated_sprite:
		var flash_tween := create_tween()
		flash_tween.tween_property(animated_sprite, "modulate", Color(2.0, 0.3, 0.3, 1.0), 0.08)
		flash_tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.1)

	if current_health <= 0:
		_die()
	else:
		_start_invulnerability()


## Inicia período de invulnerabilidade com piscar visual
func _start_invulnerability() -> void:
	is_invulnerable = true
	if _invulnerability_tween and _invulnerability_tween.is_valid():
		_invulnerability_tween.kill()

	_invulnerability_tween = create_tween()
	var loops: int = int(invulnerability_duration / 0.16)
	for i in range(loops):
		_invulnerability_tween.tween_property(animated_sprite, "modulate:a", 0.3, 0.08)
		_invulnerability_tween.tween_property(animated_sprite, "modulate:a", 1.0, 0.08)

	_invulnerability_tween.finished.connect(func():
		is_invulnerable = false
		if animated_sprite:
			animated_sprite.modulate = Color.WHITE
	)


## Lógica de morte do jogador
func _die() -> void:
	is_dead = true
	current_state = State.DEAD
	if attack_area:
		attack_area.monitoring = false

	# Desativa colisão para não sofrer novos danos
	if collision_shape:
		collision_shape.set_deferred("disabled", true)

	# Feedback visual de derrota (fade out suave)
	if animated_sprite:
		var death_tween := create_tween()
		death_tween.tween_property(animated_sprite, "modulate", Color(0.8, 0.1, 0.1, 0.0), 0.8)

	died.emit()


## Posiciona a hitbox de ataque na frente do personagem
func _update_attack_hitbox_position() -> void:
	if not attack_area:
		return
	attack_area.position = _get_facing_vector() * attack_range_offset


func _get_facing_vector() -> Vector2:
	match current_facing:
		Facing.DOWN:
			return Vector2.DOWN
		Facing.UP:
			return Vector2.UP
		Facing.SIDE:
			return Vector2.LEFT if is_facing_left else Vector2.RIGHT
	return Vector2.DOWN


## Obtém o vetor de movimento a partir das ações configuradas ou teclas físicas
func _get_input_vector() -> Vector2:
	if is_dead:
		return Vector2.ZERO

	var vector: Vector2 = Vector2.ZERO
	if InputMap.has_action("move_left") and InputMap.has_action("move_right") \
			and InputMap.has_action("move_up") and InputMap.has_action("move_down"):
		vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if vector == Vector2.ZERO and InputMap.has_action("ui_left"):
		vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# Fallback direto por teclas físicas (garante funcionamento com WASD e Setas)
	if vector == Vector2.ZERO:
		var x: float = 0.0
		var y: float = 0.0
		if Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_A) \
				or Input.is_physical_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_LEFT):
			x -= 1.0
		if Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_D) \
				or Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_RIGHT):
			x += 1.0
		if Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_W) \
				or Input.is_physical_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_UP):
			y -= 1.0
		if Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_S) \
				or Input.is_physical_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_DOWN):
			y += 1.0
		vector = Vector2(x, y)

	return vector.normalized()


func _is_run_pressed() -> bool:
	if InputMap.has_action("run") and Input.is_action_pressed("run"):
		return true
	return Input.is_physical_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_SHIFT)


func _is_attack_pressed() -> bool:
	if InputMap.has_action("attack") and Input.is_action_just_pressed("attack"):
		return true
	if InputMap.has_action("ui_accept") and Input.is_action_just_pressed("ui_accept"):
		return true
	return false


## Define a orientação do personagem com base no vetor de entrada
func _update_facing_direction(input_vector: Vector2) -> void:
	if input_vector == Vector2.ZERO:
		return

	var abs_x: float = absf(input_vector.x)
	var abs_y: float = absf(input_vector.y)

	if abs_x > abs_y:
		current_facing = Facing.SIDE
		is_facing_left = input_vector.x < 0.0
	elif abs_y > abs_x:
		if input_vector.y > 0.0:
			current_facing = Facing.DOWN
		else:
			current_facing = Facing.UP
	else:
		# Em caso de diagonal exata (abs_x == abs_y)
		# Se a direção anterior já faz parte da diagonal atual, preserva para evitar oscilações
		if current_facing == Facing.SIDE and ((is_facing_left and input_vector.x < 0.0) or (not is_facing_left and input_vector.x > 0.0)):
			pass
		elif current_facing == Facing.UP and input_vector.y < 0.0:
			pass
		elif current_facing == Facing.DOWN and input_vector.y > 0.0:
			pass
		else:
			# Prioriza o lado horizontal na diagonal
			current_facing = Facing.SIDE
			is_facing_left = input_vector.x < 0.0

	_apply_sprite_orientation()
	_update_attack_hitbox_position()


## Executa animação de caminhada com velocidade dinâmica
func _play_walk_animation(max_speed: float) -> void:
	_apply_sprite_orientation()
	var anim_name: StringName = _get_animation_name("andar")
	if animated_sprite.animation != anim_name or not animated_sprite.is_playing():
		animated_sprite.play(anim_name)

	var speed: float = velocity.length()
	var speed_factor: float = speed / max(walk_speed, 1.0)
	animated_sprite.speed_scale = clampf(walk_anim_speed_scale * speed_factor, 0.5, 3.0)


## Executa animação de repouso (idle) mantendo a última direção
func _play_idle_animation() -> void:
	_apply_sprite_orientation()
	var anim_name: StringName = _get_animation_name("idle")
	if animated_sprite.animation != anim_name or not animated_sprite.is_playing():
		animated_sprite.play(anim_name)

	animated_sprite.speed_scale = 1.0


## Aplica espelhamento horizontal no sprite quando olhando para a esquerda
func _apply_sprite_orientation() -> void:
	if current_facing == Facing.SIDE:
		animated_sprite.flip_h = is_facing_left
	else:
		animated_sprite.flip_h = false


## Retorna o nome da animação correspondente à direção atual
func _get_animation_name(action_prefix: String) -> StringName:
	match current_facing:
		Facing.DOWN:
			return StringName(action_prefix + "_frente")
		Facing.UP:
			return StringName(action_prefix + "_atras")
		Facing.SIDE:
			return StringName(action_prefix + "_lado")
	return StringName(action_prefix + "_frente")


## Aplica o dinamismo visual de squash & stretch e tilt a cada quadro
func _apply_visual_dynamics(delta: float) -> void:
	if enable_squash_stretch:
		animated_sprite.scale = animated_sprite.scale.lerp(Vector2.ONE, 12.0 * delta)
	else:
		animated_sprite.scale = Vector2.ONE

	if enable_tilt:
		animated_sprite.rotation = lerpf(animated_sprite.rotation, _target_rotation, 14.0 * delta)
	else:
		animated_sprite.rotation = 0.0


func _trigger_squash_stretch(target: Vector2) -> void:
	if enable_squash_stretch and animated_sprite:
		animated_sprite.scale = target


func _ensure_attack_animations_no_loop() -> void:
	if animated_sprite and animated_sprite.sprite_frames:
		for anim: StringName in [&"ataque_frente", &"ataque_atras", &"ataque_lado"]:
			if animated_sprite.sprite_frames.has_animation(anim):
				animated_sprite.sprite_frames.set_animation_loop(anim, false)


## Garante que as ações de input necessárias existam
func _setup_input_actions() -> void:
	_ensure_action("move_left", [KEY_A, KEY_LEFT])
	_ensure_action("move_right", [KEY_D, KEY_RIGHT])
	_ensure_action("move_up", [KEY_W, KEY_UP])
	_ensure_action("move_down", [KEY_S, KEY_DOWN])
	_ensure_action("run", [KEY_SHIFT])
	_ensure_action("attack", [KEY_SPACE, KEY_J], [MOUSE_BUTTON_LEFT])


func _ensure_action(action_name: StringName, keys: Array[Key] = [], mouse_buttons: Array[MouseButton] = []) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
		for key: Key in keys:
			var event := InputEventKey.new()
			event.physical_keycode = key
			event.keycode = key
			InputMap.action_add_event(action_name, event)
		for mb: MouseButton in mouse_buttons:
			var event := InputEventMouseButton.new()
			event.button_index = mb
			InputMap.action_add_event(action_name, event)
