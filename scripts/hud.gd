class_name HUD
extends CanvasLayer

signal restart_requested

@onready var hp_bar: ProgressBar = $MarginContainer/HBoxContainer/HealthBar
@onready var hp_label: Label = $MarginContainer/HBoxContainer/HealthBar/HPLabel
@onready var enemies_label: Label = $MarginContainer/HBoxContainer/EnemiesLabel

@onready var victory_panel: Control = $VictoryPanel
@onready var victory_restart_btn: Button = $VictoryPanel/CenterContainer/Panel/VBoxContainer/RestartButton

@onready var game_over_panel: Control = $GameOverPanel
@onready var game_over_restart_btn: Button = $GameOverPanel/CenterContainer/Panel/VBoxContainer/RestartButton


func _ready() -> void:
	victory_panel.visible = false
	game_over_panel.visible = false

	if victory_restart_btn:
		victory_restart_btn.pressed.connect(_on_restart_pressed)
	if game_over_restart_btn:
		game_over_restart_btn.pressed.connect(_on_restart_pressed)


func update_health(current: int, max_val: int) -> void:
	if hp_bar:
		hp_bar.max_value = max_val
		hp_bar.value = current
	if hp_label:
		hp_label.text = "%d / %d" % [current, max_val]


func update_enemies_remaining(remaining: int, total: int) -> void:
	if enemies_label:
		if remaining > 0:
			enemies_label.text = "🦀 Caranguejos: %d / %d" % [remaining, total]
		else:
			enemies_label.text = "👑 Arena Conquistada!"


func show_victory() -> void:
	victory_panel.visible = true
	if victory_restart_btn:
		victory_restart_btn.grab_focus()


func show_game_over() -> void:
	game_over_panel.visible = true
	if game_over_restart_btn:
		game_over_restart_btn.grab_focus()


func _on_restart_pressed() -> void:
	restart_requested.emit()
	get_tree().reload_current_scene()
