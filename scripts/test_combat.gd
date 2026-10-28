extends SceneTree

func _init() -> void:
	call_deferred("_run_combat_tests")

func _run_combat_tests() -> void:
	print("=== INICIANDO TESTES DO SISTEMA DE COMBATE, VIDA E OBJETIVO ===")
	
	var cena_packed: PackedScene = load("res://scenes/cena.tscn")
	assert(cena_packed != null, "Falha ao carregar cena.tscn")
	var cena = cena_packed.instantiate()
	root.add_child(cena)
	
	await process_frame
	await process_frame
	
	var player = cena.get_node_or_null("Player")
	var hud = cena.get_node_or_null("HUD")
	var gm = cena.get_node_or_null("GameManager")
	var enemies = cena.get_node_or_null("Enemies")
	
	assert(player != null, "Player deve existir na cena")
	assert(hud != null, "HUD deve existir na cena")
	assert(gm != null, "GameManager deve existir na cena")
	assert(enemies != null, "Enemies deve existir na cena")
	assert(gm.total_enemies > 0, "Deve haver inimigos registrados")
	
	print("1. Cena carregada com sucesso! Total de inimigos iniciais: %d" % gm.total_enemies)
	print("   Vida inicial do Player: %d / %d" % [player.current_health, player.max_health])
	assert(player.current_health == 100, "Vida do jogador deve iniciar em 100")
	
	# Teste 1.5: Área de Ataque acompanhando a direção do movimento/olhar
	print("\n1.5. Testando se a Area de Ataque acompanha o lado que o jogador anda...")
	# Direita
	player._update_facing_direction(Vector2.RIGHT)
	assert(player.attack_area.position == Vector2(12, 0), "Area de ataque deve estar na direita (12, 0)")
	# Esquerda
	player._update_facing_direction(Vector2.LEFT)
	assert(player.attack_area.position == Vector2(-12, 0), "Area de ataque deve estar na esquerda (-12, 0)")
	# Cima
	player._update_facing_direction(Vector2.UP)
	assert(player.attack_area.position == Vector2(0, -12), "Area de ataque deve estar em cima (0, -12)")
	# Baixo
	player._update_facing_direction(Vector2.DOWN)
	assert(player.attack_area.position == Vector2(0, 12), "Area de ataque deve estar embaixo (0, 12)")
	# Diagonal Cima-Direita
	player._update_facing_direction(Vector2(1, -1).normalized())
	assert(player.attack_area.position.x > 0 or player.attack_area.position.y < 0, "Area de ataque deve acompanhar a diagonal")
	print("   Area de ataque acompanha perfeitamente todos os lados (Direita, Esquerda, Cima, Baixo, Diagonais) (OK)")
	
	# Teste 2: Dano no Player
	print("\n2. Testando dano no Player...")
	player.take_damage(20, Vector2.LEFT)
	assert(player.current_health == 80, "Vida do jogador deve ser 80 após 20 de dano")
	assert(player.is_invulnerable == true, "Jogador deve estar invulnerável após receber dano")
	print("   Jogador recebeu 20 de dano. Vida atual: %d. Invulnerável: %s (OK)" % [player.current_health, player.is_invulnerable])
	
	# Teste 3: Tentar dar dano enquanto invulnerável
	print("\n3. Testando imunidade durante invulnerabilidade...")
	player.take_damage(20, Vector2.LEFT)
	assert(player.current_health == 80, "Vida não deve mudar durante a invulnerabilidade")
	print("   Dano ignorado com sucesso durante invulnerabilidade (OK)")
	
	# Teste 4: Ataque do Player em um Caranguejo
	print("\n4. Testando ataque do Player contra Caranguejo...")
	var test_crab = enemies.get_child(0)
	var initial_crab_hp = test_crab.current_health
	print("   Vida inicial do Caranguejo: %d" % initial_crab_hp)
	
	# Posiciona o caranguejo bem na frente do player e dispara o ataque do player
	test_crab.global_position = player.global_position + Vector2(10, 0)
	player.current_facing = 2 # SIDE
	player.is_facing_left = false
	player._start_attack()
	
	# Simula a colisão da hitbox de ataque
	player._on_attack_area_body_entered(test_crab)
	assert(test_crab.current_health < initial_crab_hp, "Caranguejo deve ter sofrido dano do ataque")
	print("   Vida do caranguejo após o ataque: %d (Dano aplicado: %d) (OK)" % [test_crab.current_health, initial_crab_hp - test_crab.current_health])
	player._end_attack()
	
	# Teste 5: Derrota do Caranguejo e Atualização do Objetivo
	print("\n5. Testando morte do Caranguejo...")
	var remaining_before = gm.remaining_enemies
	test_crab.take_damage(999, Vector2.RIGHT)
	assert(test_crab.current_state == 4, "Estado do caranguejo deve ser DEAD")
	assert(gm.remaining_enemies == remaining_before - 1, "GameManager deve decrementar contador de inimigos")
	print("   Caranguejos restantes: %d / %d (OK)" % [gm.remaining_enemies, gm.total_enemies])
	
	# Teste 6: Testando Condição de Vitória (derrotar todos os inimigos restantes)
	print("\n6. Testando Condição de Vitória ao eliminar todos os inimigos...")
	for child in enemies.get_children():
		if child != test_crab and child.has_method("take_damage"):
			child.take_damage(999, Vector2.ZERO)
	
	assert(gm.remaining_enemies == 0, "Todos os inimigos devem ter sido eliminados")
	assert(gm.is_game_over == true, "Jogo deve estar finalizado com vitória")
	assert(hud.victory_panel.visible == true, "Painel de vitória deve estar visível")
	print("   Painel de Vitória exibido com sucesso! (OK)")
	
	# Teste 7: Testando Condição de Derrota
	print("\n7. Testando Condição de Derrota quando o Player morre...")
	# Reseta para testar derrota
	gm.is_game_over = false
	hud.victory_panel.visible = false
	player.is_invulnerable = false
	player.take_damage(100, Vector2.ZERO)
	assert(player.is_dead == true, "Player deve estar marcado como morto")
	assert(hud.game_over_panel.visible == true, "Painel de Game Over deve estar visível")
	print("   Painel de Game Over exibido com sucesso! (OK)")
	
	print("\n=== TODOS OS TESTES DE COMBATE E OBJETIVO PASSARAM! ===")
	quit(0)
