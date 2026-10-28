class_name GameManager
extends Node

@export var player: Node2D
@export var hud: CanvasLayer

var total_enemies: int = 0
var remaining_enemies: int = 0
var is_game_over: bool = false


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

	# Registra todos os inimigos presentes na cena
	call_deferred("_setup_enemies")


func _setup_enemies() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	total_enemies = enemies.size()
	remaining_enemies = total_enemies

	if hud:
		hud.update_enemies_remaining(remaining_enemies, total_enemies)

	for enemy in enemies:
		if enemy.has_signal("died"):
			enemy.died.connect(_on_enemy_died)


func _on_player_health_changed(current: int, max_val: int) -> void:
	if hud:
		hud.update_health(current, max_val)


func _on_player_died() -> void:
	if is_game_over:
		return
	is_game_over = true
	if hud:
		hud.show_game_over()


func _on_enemy_died(_enemy: Node2D) -> void:
	if is_game_over:
		return

	remaining_enemies = maxi(remaining_enemies - 1, 0)
	if hud:
		hud.update_enemies_remaining(remaining_enemies, total_enemies)

	if remaining_enemies == 0:
		is_game_over = true
		if hud:
			hud.show_victory()
