class_name HUD
extends CanvasLayer

@onready var hp_bar: ProgressBar = $MarginContainer/HBoxContainer/HealthBar
@onready var hp_label: Label = $MarginContainer/HBoxContainer/HealthBar/HPLabel
@onready var kills_label: Label = $MarginContainer/HBoxContainer/KillsLabel

@onready var end_panel: Control = $EndPanel
@onready var end_title: Label = $EndPanel/CenterContainer/Panel/VBoxContainer/Title
@onready var end_subtitle: Label = $EndPanel/CenterContainer/Panel/VBoxContainer/Subtitle
@onready var restart_btn: Button = $EndPanel/CenterContainer/Panel/VBoxContainer/RestartButton


func _ready() -> void:
	end_panel.visible = false
	restart_btn.pressed.connect(func(): get_tree().reload_current_scene())


func update_health(current: int, max_val: int) -> void:
	hp_bar.max_value = max_val
	hp_bar.value = current
	hp_label.text = "%d / %d" % [current, max_val]


func update_kills(kills: int, target: int = 50) -> void:
	kills_label.text = "Abatidos: %d / %d" % [kills, target]


func show_victory() -> void:
	_show_end("VITÓRIA!", "Você derrotou todos os 50 caranguejos!\n", "Jogar Novamente")


func show_game_over() -> void:
	_show_end("DERROTA", "Você foi derrotado pelas criaturas da areia...\n", "Tentar Novamente")


func _show_end(title: String, subtitle: String, button_text: String) -> void:
	end_title.text = title
	end_subtitle.text = subtitle
	restart_btn.text = button_text
	end_panel.visible = true
	restart_btn.grab_focus()
