class_name GameManager
extends Node

# Implementa regras do jogo, contagem de abates e spawners da horda

@export var player: Node2D
@export var hud: CanvasLayer
@export var enemy_scene: PackedScene = preload("res://entities/crab.tscn")
@export var target_kills: int = 50

var is_game_over: bool = false
var abates: int = 0

@onready var horda_timer: Timer = get_parent().get_node_or_null("Horda")
@onready var nascedouros: Node2D = get_parent().get_node_or_null("Nascedouros")
@onready var enemies_container: Node2D = get_parent().get_node_or_null("Enemies")


func _ready() -> void:
	# Localiza o Player pelo grupo caso não tenha sido definido no Inspetor
	if player == null:
		player = get_tree().get_first_node_in_group("player")

	if player:
		player.health_changed.connect(_on_player_health_changed)
		player.died.connect(_on_player_died)
		if hud:
			hud.update_health(player.current_health, player.max_health)

	if hud:
		hud.update_kills(abates, target_kills)

	# Conecta timer da horda
	if horda_timer:
		horda_timer.timeout.connect(_on_horda_timeout)


func _on_horda_timeout() -> void:
	if is_game_over:
		return

	# Otimização da Aula 11: limite de inimigos simultâneos na tela para garantir fluidez 20 no maximo
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

		# A horda aperta: cada leva chega mais rápido progressivamente (Aula 09/11)
		if horda_timer:
			horda_timer.wait_time = maxf(0.8, horda_timer.wait_time * 0.95)


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


func _on_enemy_died(_enemy: Node2D) -> void:
	if is_game_over:
		return

	abates += 1
	if hud:
		hud.update_kills(abates, target_kills)

	# Vitória ao atingir a meta de abates
	if abates >= target_kills:
		is_game_over = true
		if horda_timer:
			horda_timer.stop()
		if hud:
			hud.show_victory()
