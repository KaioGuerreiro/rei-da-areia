class_name GameManager
extends Node

# Gerenciador da partida para a disciplina de Jogos Digitais II
# Implementa regras do jogo, contagem de abates, spawners da horda e confronto contra o Rei da Areia (Chefe)

@export var player: Node2D
@export var hud: CanvasLayer
@export var enemy_scene: PackedScene = preload("res://entities/crab.tscn")

var total_enemies: int = 0
var remaining_enemies: int = 0
var is_game_over: bool = false
var abates: int = 0

@onready var horda_timer: Timer = get_parent().get_node_or_null("Horda")
@onready var relogio_timer: Timer = get_parent().get_node_or_null("Relogio")
@onready var nascedouros: Node2D = get_parent().get_node_or_null("Nascedouros")
@onready var enemies_container: Node2D = get_parent().get_node_or_null("Enemies")

var king_crab: Node2D = null
var boss_spawned: bool = false


func _ready() -> void:
	# Localiza o Player
	if player == null:
		var players := get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			player = players[0]

	if player:
		player.health_changed.connect(_on_player_health_changed)
		player.died.connect(_on_player_died)
		if hud:
			hud.update_health(player.current_health, player.max_health)

	# Registra todos os inimigos presentes inicialmente na cena
	call_deferred("_setup_enemies")

	# Conecta timers de horda e relógio do chefe
	if horda_timer:
		horda_timer.timeout.connect(_on_horda_timeout)
	if relogio_timer:
		relogio_timer.timeout.connect(_on_relogio_timeout)


func _setup_enemies() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	total_enemies = enemies.size()
	remaining_enemies = total_enemies

	# Identifica o KingCrab inicial, se houver
	for enemy in enemies:
		if enemy is CrabEnemy and enemy.is_king_crab:
			king_crab = enemy
		if enemy.has_signal("died") and not enemy.died.is_connected(_on_enemy_died):
			enemy.died.connect(_on_enemy_died)

	if hud:
		hud.update_enemies_remaining(remaining_enemies, total_enemies)


func _on_horda_timeout() -> void:
	if is_game_over:
		return

	# Otimização da Aula 11: limite de inimigos simultâneos na tela para garantir fluidez (60 FPS)
	var active_enemies := get_tree().get_nodes_in_group("enemies").size()
	if active_enemies >= 20:
		return

	if nascedouros and nascedouros.get_child_count() > 0 and enemy_scene:
		var markers := nascedouros.get_children()
		var spawn_point: Marker2D = markers.pick_random()
		var new_enemy = enemy_scene.instantiate()
		new_enemy.global_position = spawn_point.global_position

		if new_enemy.has_signal("died"):
			new_enemy.died.connect(_on_enemy_died)

		if enemies_container:
			enemies_container.add_child(new_enemy)
		else:
			get_parent().add_child(new_enemy)

		total_enemies += 1
		remaining_enemies += 1

		if hud:
			hud.update_enemies_remaining(remaining_enemies, total_enemies)

		# A horda aperta: cada leva chega mais rápido progressivamente (Aula 09/11)
		if horda_timer:
			horda_timer.wait_time = maxf(0.8, horda_timer.wait_time * 0.95)


func _on_relogio_timeout() -> void:
	if is_game_over or boss_spawned or king_crab != null:
		return
	_spawn_king_crab()


func _spawn_king_crab() -> void:
	boss_spawned = true
	var spawn_pos := Vector2(360, 48)
	if nascedouros and nascedouros.has_node("Cima"):
		spawn_pos = nascedouros.get_node("Cima").global_position

	var boss = enemy_scene.instantiate()
	if boss is CrabEnemy:
		boss.is_king_crab = true
	boss.global_position = spawn_pos
	boss.name = "KingCrab"

	if boss.has_signal("died"):
		boss.died.connect(_on_enemy_died)

	king_crab = boss

	if enemies_container:
		enemies_container.add_child(boss)
	else:
		get_parent().add_child(boss)

	total_enemies += 1
	remaining_enemies += 1
	if hud:
		hud.update_enemies_remaining(remaining_enemies, total_enemies)


func _on_player_health_changed(current: int, max_val: int) -> void:
	if hud:
		hud.update_health(current, max_val)


func _on_player_died() -> void:
	if is_game_over:
		return
	is_game_over = true
	if horda_timer:
		horda_timer.stop()
	if hud:
		hud.show_game_over()


func _on_enemy_died(enemy: Node2D) -> void:
	if is_game_over:
		return

	abates += 1
	remaining_enemies = maxi(remaining_enemies - 1, 0)
	if hud:
		hud.update_enemies_remaining(remaining_enemies, total_enemies)

	# Vitória se derrotar os caranguejos da rodada ou eliminar o Rei da Areia
	if remaining_enemies == 0 or (enemy == king_crab and remaining_enemies <= 1):
		is_game_over = true
		if horda_timer:
			horda_timer.stop()
		if hud:
			hud.show_victory()
