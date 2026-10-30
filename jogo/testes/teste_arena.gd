extends SceneTree

# Roda sem tela: godot --headless --fixed-fps 120 --path jogo -s res://testes/teste_arena.gd
# Testa a saída de bola, subir na parede, gols, pads de boost, bola presa na arena e prorrogação.

var carro: RigidBody3D
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
	await physics_frame   # os botões só existem depois do primeiro quadro
	await esperar(0.5)
	var antes := carro.global_position
	Input.action_press("acelerar")
	await esperar(1.0)
	print("contagem: carro andou %.2f m antes do VAI (tem que ser 0), mensagem \"%s\"" % [carro.global_position.distance_to(antes), partida.hud.get_node("Mensagem").text])
	await esperar(2.0)
	print("depois do VAI: carro a %.1f m/s, estado %s" % [carro.linear_velocity.length(), partida.Estado.keys()[partida.estado]])
	Input.action_release("acelerar")

	for parede in [["lateral (+X)", Vector3(20, 0.32, 0), Vector3.RIGHT], ["do fundo, ao lado do gol (-Z)", Vector3(20, 0.32, -30), Vector3.FORWARD]]:
		await colocar_carro(parede[1], parede[2])
		Input.action_press("acelerar")
		Input.action_press("boost")
		carro.boost = 100.0
		var mais_alto := 0.0
		var rodas_la_em_cima := 0
		for i in 360:
			await physics_frame
			if carro.global_position.y > mais_alto:
				mais_alto = carro.global_position.y
				rodas_la_em_cima = carro.rodas_no_chao
		Input.action_release("acelerar")
		Input.action_release("boost")
		print("parede %-30s subiu até %.1f m, com %d rodas encostadas lá em cima" % [parede[0], mais_alto, rodas_la_em_cima])

	await colocar_carro(Vector3(-30, 0.32, 10), Vector3.FORWARD)
	for gol in [["no gol laranja (azul marca)", -1.0], ["no gol azul (contra)", 1.0]]:
		partida.estado = partida.Estado.JOGANDO
		bola.freeze = false
		bola.visible = true
		bola.global_transform = Transform3D(Basis(), Vector3(3, 2, gol[1] * 38.0))
		bola.linear_velocity = Vector3(0, 0, gol[1] * 25.0)
		await esperar(1.5)
		print("bola %-28s placar azul %d × %d laranja, estado %s, \"%s\"" % [gol[0], partida.placar["azul"], partida.placar["laranja"], partida.Estado.keys()[partida.estado], partida.hud.get_node("Mensagem").text])
	await esperar(3.0)
	print("depois da comemoração: estado %s, bola no meio: %s, visível: %s" % [partida.Estado.keys()[partida.estado], "sim" if bola.global_position.distance_to(Vector3(0, 0.9125, 0)) < 0.1 else "NÃO", bola.visible])
	await esperar(3.5)

	for pad in [["grande", Vector3(-33, 0.32, -38), 0.0], ["pequeno", Vector3(0, 0.32, -12), 0.0]]:
		await colocar_carro(pad[1] + Vector3(0, 0, 5), Vector3.FORWARD)
		carro.boost = pad[2]
		Input.action_press("acelerar")
		await esperar(1.2)
		Input.action_release("acelerar")
		var depois := roundi(carro.boost)
		var apagou: bool = not partida.pads.filter(func(x): return x["onde"] == Vector2(pad[1].x, pad[1].z))[0]["brilho"].visible
		print("pad %-8s boost 0 → %d, pad apagou: %s" % [pad[0], depois, "sim" if apagou else "NÃO"])

	for jogada in [["pra parede a 60 m/s", Vector3(0, 5, 0), Vector3(60, 0, 0)], ["pro teto a 60 m/s", Vector3(0, 5, 0), Vector3(0, 60, 0)], ["pro canto a 60 m/s", Vector3(0, 5, 0), Vector3(42, 0, 42)], ["pra trave a 60 m/s", Vector3(0, 3, -30), Vector3(15, 0, -58)]]:
		partida.estado = partida.Estado.FIM   # sem gol nesse teste
		bola.freeze = false
		bola.global_transform = Transform3D(Basis(), jogada[1])
		bola.linear_velocity = jogada[2]
		var escapou := false
		for i in 480:
			await physics_frame
			var b := bola.global_position
			if absf(b.x) > 41.0 or b.y > 20.5 or b.y < -1.0 or absf(b.z) > 60.0:
				escapou = true
		print("bola %-22s %s" % [jogada[0], "ESCAPOU da arena" if escapou else "ficou dentro"])

	partida.nova_partida()
	await esperar(3.5)
	partida.relogio = 0.5
	await esperar(1.0)
	print("tempo acabou empatado: prorrogação = %s, \"%s\"" % [partida.prorrogacao, partida.hud.get_node("Placar").text.replace("\n", " / ")])
	bola.global_transform = Transform3D(Basis(), Vector3(0, 2, -45))
	bola.linear_velocity = Vector3(0, 0, -20)
	await esperar(5.0)
	print("gol na prorrogação: estado %s, \"%s\"" % [partida.Estado.keys()[partida.estado], partida.hud.get_node("Mensagem").text.replace("\n", " / ")])
	quit()


func colocar_carro(posicao: Vector3, direcao: Vector3) -> void:
	carro.colocar_em(Transform3D(Basis.looking_at(direcao), posicao))
	carro.travado = false
	await esperar(1.0)


func esperar(segundos: float) -> void:
	for i in roundi(segundos * 120.0):
		await physics_frame
