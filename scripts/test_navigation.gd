extends SceneTree

# Teste automatizado para os requisitos da Aula 10 (Navegação, A*, Desvio de Obstáculos e Ataque)
# Baseado em: docs/roteiro-pratica-10.pdf

func _init() -> void:
	call_deferred("_run_navigation_tests")

func _run_navigation_tests() -> void:
	print("=== INICIANDO TESTES DA AULA 10 (NAVEGAÇÃO E ATAQUE) ===")
	
	var cena_packed: PackedScene = load("res://scenes/cena.tscn")
	assert(cena_packed != null, "Falha ao carregar cena.tscn")
	var cena = cena_packed.instantiate()
	root.add_child(cena)
	
	await process_frame
	await process_frame
	
	# 1. Verifica existência da NavigationRegion2D (Navegacao)
	print("1. Verificando NavigationRegion2D na cena...")
	var nav = cena.get_node_or_null("Navegacao")
	assert(nav != null, "A cena deve conter um nó NavigationRegion2D chamado 'Navegacao'")
	assert(nav is NavigationRegion2D, "O nó 'Navegacao' deve ser do tipo NavigationRegion2D")
	assert(nav.navigation_polygon != null, "Navegacao deve possuir um NavigationPolygon configurado")
	assert(nav.navigation_polygon.get_polygon_count() > 0, "NavigationPolygon deve possuir polígonos navegáveis assados")
	print("   NavigationRegion2D configurada e malha de navegação presente! Polígonos: %d (OK)" % nav.navigation_polygon.get_polygon_count())
	
	# 2. Verifica camadas dos TileMaps dentro da Navegação
	print("\n2. Verificando se camadas de colisão estão sob a Navegação...")
	var terreno = nav.get_node_or_null("terreno")
	var decoracao = nav.get_node_or_null("decoracao")
	assert(terreno != null, "Camada de terreno deve estar dentro de Navegacao")
	assert(decoracao != null, "Camada de decoracao deve estar dentro de Navegacao")
	print("   Camadas de terreno e decoracao organizadas sob Navegacao (OK)")
	
	# 3. Verifica NavigationAgent2D no inimigo
	print("\n3. Verificando NavigationAgent2D no inimigo...")
	var enemies = cena.get_node_or_null("Enemies")
	assert(enemies != null and enemies.get_child_count() > 0, "Devem existir inimigos na cena")
	var crab = enemies.get_child(0)
	var agent = crab.get_node_or_null("NavigationAgent2D")
	assert(agent != null, "O inimigo deve conter um filho NavigationAgent2D")
	assert(agent.path_desired_distance == 4.0, "path_desired_distance deve ser 4.0")
	assert(agent.target_desired_distance == 4.0, "target_desired_distance deve ser 4.0")
	print("   Inimigo possui NavigationAgent2D com distâncias calibradas para 4.0 (OK)")
	
	# 4. Verifica cálculo de rota com obstáculo
	print("\n4. Verificando cálculo de rota via NavigationAgent2D...")
	var player = cena.get_node_or_null("Player")
	assert(player != null, "Player deve existir na cena")
	
	crab.player_target = player
	crab.current_state = crab.State.CHASE
	agent.target_position = player.global_position
	
	# Aguarda sincronização do servidor de navegação
	await physics_frame
	await physics_frame
	
	var next_pos = agent.get_next_path_position()
	assert(next_pos != Vector2.ZERO, "NavigationAgent2D deve calcular próximo ponto no caminho")
	print("   Próximo ponto de rota calculado com sucesso: %s (OK)" % next_pos)
	
	# 5. Verifica camadas de colisão
	print("\n5. Verificando camadas de colisão (Mundo=1, Jogador=2, Inimigo=3)...")
	assert(player.collision_layer == 2, "Jogador deve estar na Layer 2")
	assert(crab.collision_layer == 4, "Inimigo deve estar na Layer 3 (bitmask 4)")
	print("   Camadas de física 2D configuradas corretamente (OK)")
	
	# 6. Verifica clarão do ataque do jogador (Aula 10)
	print("\n6. Verificando clarão visual do ataque do jogador...")
	var attack_area = player.get_node_or_null("AttackArea")
	assert(attack_area != null, "Player deve possuir AttackArea")
	var golpe = attack_area.get_node_or_null("Golpe")
	assert(golpe != null, "AttackArea deve possuir o efeito de clarão 'Golpe' (ColorRect)")
	assert(golpe is ColorRect, "Golpe deve ser um ColorRect")
	print("   Clarão do golpe (Golpe) configurado em AttackArea (OK)")
	
	print("\n=== TODOS OS TESTES DA AULA 10 PASSARAM COM SUCESSO! ===")
	quit(0)
