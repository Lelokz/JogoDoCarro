extends SceneTree

# Teste do multiplayer, lado do host. Roda junto com o teste_rede_amigo.gd (ver testar_rede.sh).

var rede: Node   # a Rede só existe depois que o jogo abre


func _initialize() -> void:
	rodar()


func rodar() -> void:
	await process_frame
	rede = root.get_node("Rede")
	print("host: hospedar → %s" % ("ok" if rede.hospedar() == OK else "ERRO"))
	var partida: Node = null
	for i in 2400:
		await physics_frame
		if current_scene and current_scene.has_node("Partida"):
			partida = current_scene.get_node("Partida")
		if partida and partida.carros.size() >= 3:
			break
	if partida == null or partida.carros.size() < 3:
		print("host: ERRO, os dois amigos não entraram (carros: %d)" % (partida.carros.size() if partida else 0))
		quit()
		return
	var ids: Array = partida.carros.keys().filter(func(id: int) -> bool: return id != 1)
	ids.sort()
	var amigo: RigidBody3D = partida.carros[ids[0]]
	print("host: entraram 2 amigos. Times: host %s, 1º amigo %s, 2º amigo %s" % [partida.times[1], partida.times[ids[0]], partida.times[ids[1]]])
	var comeco := amigo.global_position
	var mais_alto := 0.0
	var usou_boost := false
	for i in 1200:
		await physics_frame
		mais_alto = maxf(mais_alto, amigo.global_position.y)
		usou_boost = usou_boost or amigo.boostando
	print("host: o carro do 1º amigo andou %.1f m no meu PC, subiu até %.1f m (pulo), usou boost: %s" % [comeco.distance_to(amigo.global_position), mais_alto, "sim" if usou_boost else "NÃO"])
	for i in 600:
		await physics_frame
		if partida.carros.size() < 3:
			break
	print("host: depois que um amigo saiu, ficaram %d carros" % partida.carros.size())
	quit()
