extends SceneTree

# Roda sem tela: godot --headless --fixed-fps 120 --path jogo -s res://testes/teste_explosoes.gd
# Testa a demolição (supersônico batendo no adversário), a volta do demolido e a explosão do gol.

var carro: RigidBody3D
var outro: RigidBody3D
var bola: RigidBody3D
var partida: Node


func _initialize() -> void:
	if not InputMap.has_action("acelerar"):
		root.add_child(load("res://scripts/controles.gd").new())
	var cena: Node = load("res://cenas/arena.tscn").instantiate()
	root.add_child(cena)
	carro = cena.get_node("Carro")
	bola = cena.get_node("Bola")
	partida = cena.get_node("Partida")
	rodar()


func rodar() -> void:
	await physics_frame
	# um adversário laranja, como se fosse um amigo que entrou
	outro = partida.CENA_CARRO.instantiate()
	outro.controle_local = false
	outro.position = Vector3(-25, 0.32, 0)   # criado em (0, 0, 0) ele nasce enterrado no chão e pula quando sai
	partida.get_parent().add_child(outro)
	partida.copiar_ajustes(carro, outro)
	partida.times[99] = "laranja"
	partida.carros[99] = outro
	outro.definir_time("laranja")
	await esperar(0.3)
	partida.comecar()
	bola.freeze = true
	bola.global_position = Vector3(0, 0.9125, -30)

	await batida(Vector3(-20, 0.32, 14), Vector3(-20, 0.32, 4), false, "azul supersônico bate no laranja parado")
	print("laranja explodiu: %s · azul explodiu: %s" % [outro.explodido, carro.explodido])
	await esperar(partida.TEMPO_DEMOLIDO + 0.3)
	print("depois de %.0f s: laranja voltou: %s, em z = %.1f (perto do gol laranja = perto de -50), boost %d" % [partida.TEMPO_DEMOLIDO, not outro.explodido and outro.visible, outro.global_position.z, roundi(outro.boost)])

	await batida(Vector3(20, 0.32, 14), Vector3(20, 0.32, 0), true, "os dois supersônicos de frente")
	print("laranja explodiu: %s · azul explodiu: %s" % [outro.explodido, carro.explodido])
	await esperar(partida.TEMPO_DEMOLIDO + 0.3)

	partida.times[99] = "azul"
	await batida(Vector3(-20, 0.32, 14), Vector3(-20, 0.32, 4), false, "azul supersônico bate num azul (mesmo time)")
	print("o outro explodiu: %s (tem que ser false)" % outro.explodido)
	partida.times[99] = "laranja"

	partida.saida_de_bola()
	partida.comecar()
	await colocar(carro, Vector3(2, 0.32, -40), Basis())
	await colocar(outro, Vector3(-25, 0.32, 0), Basis())
	var explosoes_antes: int = partida.numero_explosao
	bola.freeze = false
	bola.visible = true
	bola.global_transform = Transform3D(Basis(), Vector3(0, 2, -42))
	bola.linear_velocity = Vector3(0, 0, -28)
	# o carro vem a toda atrás da bola, na direção do gol (como ele testou com o G)
	carro.linear_velocity = Vector3(0, 0, -22)
	var z_antes: float = carro.global_position.z
	var mais_alto := 0.0
	var mais_longe := 0.0
	var mais_rapido := 0.0
	var onde_explodiu := Vector3.ZERO
	for i in 600:
		await physics_frame
		mais_alto = maxf(mais_alto, carro.global_position.y)
		mais_longe = maxf(mais_longe, carro.global_position.z - z_antes)
		mais_rapido = maxf(mais_rapido, carro.linear_velocity.length())
		if partida.explosoes.size() > 0:
			onde_explodiu = partida.explosoes[-1][1]
	print("gol: explosões novas %d, em z = %.1f (o gol é z = -50) · carro vindo a 80 km/h atrás da bola: voou %.1f m pra trás e subiu até %.1f m · carro longe a %.1f m/s" % [partida.numero_explosao - explosoes_antes, onde_explodiu.z, mais_longe, mais_alto, outro.linear_velocity.length()])
	quit()


func batida(de: Vector3, alvo: Vector3, os_dois: bool, nome: String) -> void:
	await colocar(carro, de, Basis())
	await colocar(outro, alvo, Basis(Vector3.UP, PI) if os_dois else Basis(Vector3.UP, PI / 2.0))
	carro.boost = 100.0
	outro.boost = 100.0
	carro.linear_velocity = Vector3(0, 0, -23)
	if os_dois:
		outro.linear_velocity = Vector3(0, 0, 23)
	Input.action_press("acelerar")
	Input.action_press("boost")
	outro.comandos.acelerador = 1.0 if os_dois else 0.0
	outro.comandos.boost = os_dois
	var batida_em := -1.0
	for i in 150:
		await physics_frame
		if outro.explodido or carro.explodido:
			break
		if batida_em < 0.0 and carro.global_position.distance_to(outro.global_position) < 1.3:
			batida_em = i / 120.0
	Input.action_release("acelerar")
	Input.action_release("boost")
	outro.comandos.acelerador = 0.0
	outro.comandos.boost = false
	print("%s (azul a %.1f m/s, supersônico: %s)" % [nome, carro.linear_velocity.length(), carro.supersonico])


func colocar(quem: RigidBody3D, onde: Vector3, giro: Basis) -> void:
	if quem.explodido:
		quem.reviver()
	quem.colocar_em(Transform3D(giro, onde))
	await esperar(0.6)   # assentar nas molas antes da batida


func esperar(segundos: float) -> void:
	for i in int(segundos * 120.0):
		await physics_frame
