extends SceneTree

# Roda sem tela: godot --headless --fixed-fps 120 --path jogo -s res://testes/teste_ar.gd
# Testa pulo, duplo pulo, mortal, boost, desvirar pulando e controle no ar.

var carro: RigidBody3D


func _initialize() -> void:
	if not InputMap.has_action("acelerar"):
		root.add_child(load("res://scripts/controles.gd").new())
	var cena: Node = load("res://cenas/campo_teste.tscn").instantiate()
	root.add_child(cena)
	carro = cena.get_node("Carro")
	rodar()


func rodar() -> void:
	await physics_frame   # os botões só existem depois do primeiro quadro
	await colocar(Vector3(300, 0.6, 300), Basis())
	var chao := carro.global_position.y

	await apertar("pulo", 1)
	print("pulo rápido (toque):  subiu %.2f m" % (await maior_altura(2.0) - chao))
	await esperar(1.0)
	await apertar("pulo", 36)
	print("pulo segurando:       subiu %.2f m" % (await maior_altura(2.0) - chao))
	await esperar(1.0)
	await apertar("pulo", 30)
	await esperar(0.1)
	await apertar("pulo", 1)
	print("duplo pulo:           subiu %.2f m" % (await maior_altura(2.5) - chao))
	await esperar(1.5)

	for teste in [["nariz_baixo", "pra frente", "x"], ["direita", "pro lado", "z"], ["nariz_cima", "pra trás", "x"]]:
		await colocar(Vector3(300, 0.6, 300), Basis())
		Input.action_press("acelerar")
		await esperar(3.0)
		var antes := carro.linear_velocity.length()
		await apertar("pulo", 1)
		await esperar(0.15)
		Input.action_press(teste[0])
		await apertar("pulo", 1)
		await esperar(0.05)
		Input.action_release(teste[0])
		Input.action_release("acelerar")
		var maior := 0.0
		var girou := 0.0
		for i in 240:
			await physics_frame
			maior = maxf(maior, carro.linear_velocity.length())
			var eixo: Vector3 = carro.global_basis.x if teste[2] == "x" else carro.global_basis.z
			girou += absf(carro.angular_velocity.dot(eixo)) / 120.0
		print("mortal %-10s velocidade %4.1f -> %4.1f m/s, girou %3d°, terminou de rodas pra baixo: %s" % [teste[1], antes, maior, roundi(rad_to_deg(girou)), "sim" if carro.global_basis.y.y > 0.9 else "NÃO"])

	await colocar(Vector3(300, 0.6, 300), Basis())
	carro.boost = 100.0
	Input.action_press("boost")
	var supersonico := -1.0
	var maxima := -1.0
	for i in 600:
		await physics_frame
		if supersonico < 0.0 and carro.supersonico:
			supersonico = i / 120.0
		if maxima < 0.0 and carro.linear_velocity.length() > 22.9:
			maxima = i / 120.0
		if carro.boost <= 0.0:
			break
	Input.action_release("boost")
	print("boost parado → supersônico em %.2f s, 23 m/s em %.2f s, tanque acabou em %.2f s" % [supersonico, maxima, (await tempo_ate_vazio())])

	await colocar(Vector3(300, 0.4, 340), Basis(Vector3.BACK, PI))
	print("de teto no chão:      rodas %d, em pé: %s" % [carro.rodas_no_chao, "sim" if carro.global_basis.y.y > 0.9 else "não"])
	await apertar("pulo", 1)
	await esperar(2.5)
	print("depois de pular:      rodas %d, em pé: %s" % [carro.rodas_no_chao, "sim" if carro.global_basis.y.y > 0.9 else "NÃO"])

	carro.global_transform = Transform3D(Basis(), Vector3(300, 40, 300))
	carro.linear_velocity = Vector3.ZERO
	carro.angular_velocity = Vector3.ZERO
	await esperar(0.1)
	Input.action_press("nariz_baixo")
	var chegou := -1.0
	for i in 120:
		await physics_frame
		if chegou < 0.0 and absf(carro.angular_velocity.dot(carro.global_basis.x)) > 5.4:
			chegou = i / 120.0
	Input.action_release("nariz_baixo")
	var antes_de_soltar := absf(carro.angular_velocity.dot(carro.global_basis.x))
	await esperar(1.0)
	print("no ar inclinando:     chegou no giro máximo (5,5 rad/s) em %.2f s; solto 1 s depois: %.2f → %.2f rad/s" % [chegou, antes_de_soltar, absf(carro.angular_velocity.dot(carro.global_basis.x))])
	quit()


func tempo_ate_vazio() -> float:
	# boost gasto em 33,3/s: 100 dura ~3 s
	return 100.0 / carro.gasto_boost


func colocar(posicao: Vector3, base: Basis) -> void:
	for acao in ["acelerar", "re", "direita", "esquerda", "nariz_baixo", "nariz_cima", "boost", "pulo", "freio_mao"]:
		Input.action_release(acao)
	carro.global_transform = Transform3D(base, posicao)
	carro.linear_velocity = Vector3.ZERO
	carro.angular_velocity = Vector3.ZERO
	await esperar(1.5)


func apertar(acao: String, quadros: int) -> void:
	Input.action_press(acao)
	for i in quadros:
		await physics_frame
	Input.action_release(acao)


func esperar(segundos: float) -> void:
	for i in roundi(segundos * 120.0):
		await physics_frame


func maior_altura(segundos: float) -> float:
	var maior := carro.global_position.y
	for i in roundi(segundos * 120.0):
		await physics_frame
		maior = maxf(maior, carro.global_position.y)
	return maior
