extends Camera2D
var alvo: Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	buscar_alvo()
	if alvo != null:
		global_position = alvo.global_position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	if alvo == null:
		return
	global_position = alvo.global_position

func buscar_alvo() -> void:
	var nos := get_tree().get_nodes_in_group("player")
	if nos.is_empty():
		push_error("Camera2D: nenhum nó no grupo 'player'")
		return
	alvo = nos[0]
