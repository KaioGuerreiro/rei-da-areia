class_name Player
extends CharacterBody2D

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
## Efeito sutil de squash & stretch ao iniciar e frear
@export var enable_squash_stretch: bool = true
## Leve inclinação lateral dinâmica na direção do movimento
@export var enable_tilt: bool = true
@export var max_tilt_degrees: float = 3.5

## Combate
@export_group("Combate")
@export var attack_friction: float = 850.0
@export var attack_anim_speed_scale: float = 1.6

## Referência dos Nós Filhos
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

## Estados e Direções
enum State { MOVE, ATTACK }
enum Facing { DOWN, UP, SIDE }

var current_state: State = State.MOVE
var current_facing: Facing = Facing.DOWN
var is_facing_left: bool = false

# Controles internos de dinamismo
var _was_moving: bool = false
var _target_rotation: float = 0.0


func _ready() -> void:
	_setup_input_actions()
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

	_apply_visual_dynamics(delta)


## Processa movimentação, aceleração, desaceleração e transição de animações
func _process_move_state(delta: float) -> void:
	# Gatilho de ataque
	if _is_attack_pressed():
		_start_attack()
		return

	var input_vector: Vector2 = _get_input_vector()
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
		# Estiramento sutil na arrancada
		_trigger_squash_stretch(Vector2(0.88, 1.12))
	elif not is_moving and _was_moving:
		# Achatamento suave na frenagem
		_trigger_squash_stretch(Vector2(1.12, 0.88))
	_was_moving = is_moving

	# Atualiza direção e reproduz a animação dinâmica correspondente
	if is_moving:
		_update_facing_direction(input_vector)
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


## Inicia ataque na direção atual com feedback visual
func _start_attack() -> void:
	current_state = State.ATTACK
	_apply_sprite_orientation()

	var anim_name: StringName = _get_animation_name("ataque")
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.speed_scale = attack_anim_speed_scale
		animated_sprite.play(anim_name)
	else:
		current_state = State.MOVE
		return

	# Pequeno impacto elástico no início do ataque
	_trigger_squash_stretch(Vector2(1.15, 0.9))


func _on_animation_finished() -> void:
	if current_state == State.ATTACK:
		current_state = State.MOVE
		var input_vector: Vector2 = _get_input_vector()
		if input_vector != Vector2.ZERO:
			_play_walk_animation(run_speed if _is_run_pressed() else walk_speed)
		else:
			_play_idle_animation()


func _on_animation_looped() -> void:
	if current_state == State.ATTACK:
		_on_animation_finished()


## Obtém o vetor de movimento a partir das ações configuradas ou teclas físicas
func _get_input_vector() -> Vector2:
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
	return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)


## Define a orientação do personagem com base no vetor de entrada
func _update_facing_direction(input_vector: Vector2) -> void:
	var abs_x: float = absf(input_vector.x)
	var abs_y: float = absf(input_vector.y)

	# Se o movimento for predominantemente horizontal
	if abs_x > abs_y + 0.15:
		current_facing = Facing.SIDE
		is_facing_left = input_vector.x < 0.0
	# Se for predominantemente vertical
	elif abs_y > abs_x + 0.15:
		if input_vector.y > 0.0:
			current_facing = Facing.DOWN
		else:
			current_facing = Facing.UP
	else:
		# Em diagonais, preserva a orientação do lado se estiver se movendo no eixo X
		if abs_x > 0.1:
			is_facing_left = input_vector.x < 0.0


## Executa animação de caminhada com velocidade dinâmica sincronizada aos passos reais
func _play_walk_animation(max_speed: float) -> void:
	_apply_sprite_orientation()
	var anim_name: StringName = _get_animation_name("andar")
	if animated_sprite.animation != anim_name or not animated_sprite.is_playing():
		animated_sprite.play(anim_name)

	# Dinamismo de passada: velocidade de reprodução escala com a velocidade real do personagem
	var speed: float = velocity.length()
	var speed_factor: float = speed / max(walk_speed, 1.0)
	animated_sprite.speed_scale = clampf(walk_anim_speed_scale * speed_factor, 0.5, 3.0)


## Executa animação de repouso (idle) mantendo a última direção observada
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


## Garante que as ações de input necessárias existam mesmo sem configuração prévia no editor
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
