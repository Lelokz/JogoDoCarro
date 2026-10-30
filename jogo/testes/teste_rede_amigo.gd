extends SceneTree

# Teste do multiplayer, lado de quem entra. Com "-- --dirigir" acelera, usa boost e pula.

var rede: Node   # a Rede só existe depois que o jogo abre


func _initialize() -> void:
	rodar()


func rodar() -> void:
	await process_frame
	rede = root.get_node("Rede")
	var dirigir := "--dirigir" in OS.get_cmdline_user_args()
	var nome := "1º amigo" if dirigir else "2º amigo"
	for tentativa in 20:
		if rede.entrar("127.0.0.1") == OK:
			break
		await create_timer(0.5).timeout
	var partida: Node = null
	for i in 2400:
		await physics_frame
		if current_scene and current_scene.has_node("Partida"):
			partida = current_scene.get_node("Partida")
			if partida.estados_recebidos.size() > 10:
				break
	if partida == null:
		print("%s: ERRO, não entrou na partida" % nome)
		quit()
		return
	await create_timer(1.0).timeout
	var meu: RigidBody3D = partida.carro
	print("%s: entrou. Vejo %d carros, placar \"%s\"" % [nome, partida.carros.size(), partida.hud.get_node("Placar").text.replace("\n", " / ")])
	if not dirigir:
		await create_timer(8.0).timeout
		print("%s: saindo da partida" % nome)
		rede.sair()
		await create_timer(1.0).timeout
		quit()
		return
	await create_timer(3.0).timeout   # espera o VAI da saída de bola
	var comeco := meu.global_position
	Input.action_press("acelerar")
	var quadros_pra_andar := 0
	for i in 240:
		await physics_frame
		quadros_pra_andar += 1
		if meu.velocidade().length() > 0.05:
			break
	print("%s: apertei acelerar e o meu carro começou a se mexer em %d ms" % [nome, roundi(quadros_pra_andar * 1000.0 / 120.0)])
	Input.action_press("boost")
	await create_timer(1.5).timeout
	Input.action_release("boost")
	Input.action_press("pulo")
	await create_timer(0.25).timeout
	Input.action_release("pulo")
	var mais_alto := 0.0
	for i in 120:
		await physics_frame
		mais_alto = maxf(mais_alto, meu.global_position.y)
	Input.action_release("acelerar")
	print("%s: no meu PC o meu carro andou %.1f m e subiu até %.1f m; recebi %d estados do host" % [nome, comeco.distance_to(meu.global_position), mais_alto, partida.estados_recebidos.size()])
	var erros: Array = partida.erros_medidos.slice(20)   # depois da entrada e da saída de bola
	erros.sort()
	if not erros.is_empty():
		print("%s: diferença pro host em %d comparações: metade abaixo de %.1f cm, 95%% abaixo de %.1f cm, maior %.1f cm" % [nome, erros.size(), erros[erros.size() / 2] * 100.0, erros[int(erros.size() * 0.95)] * 100.0, erros[-1] * 100.0])
	await create_timer(6.0).timeout
	quit()
