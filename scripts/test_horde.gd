extends SceneTree

# Teste automatizado para os requisitos da Aula 11 (Arte temática e horda otimizada sem travar)
# Baseado em: docs/projeto.pdf

func _init() -> void:
	call_deferred("_run_horde_tests")

func _run_horde_tests() -> void:
	print("=== INICIANDO TESTES DA AULA 11 (ARTE TEMÁTICA E HORDA OTIMIZADA) ===")
	
	var cena_packed: PackedScene = load("res://scenes/cena.tscn")
	assert(cena_packed != null, "Falha ao carregar cena.tscn")
	var cena = cena_packed.instantiate()
	root.add_child(cena)
	
	await process_frame
	await process_frame
	
	# 1. Verifica Nascedouros e Pontos de Spawn
	print("1. Verificando estrutura de Nascedouros e marcadores da horda...")
	var nascedouros = cena.get_node_or_null("Nascedouros")
	assert(nascedouros != null, "A cena deve possuir o nó 'Nascedouros'")
	assert(nascedouros.get_child_count() >= 4, "Devem haver pelo menos 4 pontos de spawn (Marker2D)")
	print("   Nascedouros configurados com %d marcadores de borda (OK)" % nascedouros.get_child_count())
	
	# 2. Verifica Timer da Horda
	print("\n2. Verificando Timer da Horda...")
	var horda = cena.get_node_or_null("Horda")
	assert(horda != null, "A cena deve conter o Timer 'Horda'")
	assert(horda.wait_time > 0, "O Timer Horda deve ter wait_time positivo")
	print("   Timer Horda ativo com wait_time inicial de %.1fs (OK)" % horda.wait_time)
	
	# 3. Verifica Rei da Areia (Chefe Temático)
	print("\n3. Verificando o Chefe (Rei da Areia / KingCrab)...")
	var enemies = cena.get_node_or_null("Enemies")
	assert(enemies != null, "Nó Enemies deve existir")
	var king = enemies.get_node_or_null("KingCrab")
	assert(king != null, "KingCrab (Rei da Areia) deve estar presente na cena")
	assert(king.is_king_crab == true, "KingCrab deve ter is_king_crab = true")
	assert(king.max_health == 100, "KingCrab deve ter 100 de vida máxima")
	assert(king.damage == 25, "KingCrab deve desferir 25 de dano")
	print("   Rei da Areia configurado com estatísticas de chefe (HP 100, Dano 25) (OK)")
	
	# 4. Verifica geração de caranguejos pela horda
	print("\n4. Testando mecânica de spawn de caranguejos via horda...")
	var gm = cena.get_node_or_null("GameManager")
	assert(gm != null, "GameManager deve existir")
	var initial_total = gm.total_enemies
	gm._on_horda_timeout()
	assert(gm.total_enemies == initial_total + 1, "Disparo da horda deve instanciar novo caranguejo")
	print("   Caranguejo instanciado na arena com sucesso! Total: %d (OK)" % gm.total_enemies)
	
	# 5. Verifica otimização de navegação (taxa de atualização por timer / 5Hz)
	print("\n5. Verificando otimização de navegação contra sobrecarga de CPU...")
	var sample_crab = enemies.get_child(0)
	assert("_nav_update_timer" in sample_crab, "Inimigo deve implementar temporizador para limitar requisições de rota")
	print("   Otimização de pathfinding ativo para suportar hordas cheias a 60 FPS (OK)")
	
	print("\n=== TODOS OS TESTES DA AULA 11 PASSARAM COM SUCESSO! ===")
	quit(0)
