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
	var times: Array = ids.map(func(id: int) -> String: return partida.times[id])
	print("host: entraram 2 amigos. Times: host %s, amigos %s" % [partida.times[1], " e ".join(times)])
	# o amigo que dirige é o que se mexer (o número de cada jogador é sorteado)
	var comeco := {}
	for id in ids:
		comeco[id] = partida.carros[id].global_position
	var mais_alto := {}
	var usou_boost := {}
	for i in 1200:
		await physics_frame
		for id in ids:
			if partida.carros.has(id):
				var c: RigidBody3D = partida.carros[id]
				mais_alto[id] = maxf(mais_alto.get(id, 0.0), c.global_position.y)
				usou_boost[id] = usou_boost.get(id, false) or c.boostando
	var quem: int = ids[0]
	for id in ids:
		if partida.carros.has(id) and (not partida.carros.has(quem) or partida.carros[id].global_position.distance_to(comeco[id]) > partida.carros[quem].global_position.distance_to(comeco[quem])):
			quem = id
	var andou: float = partida.carros[quem].global_position.distance_to(comeco[quem]) if partida.carros.has(quem) else 0.0
	print("host: o carro do amigo que dirigiu (%s) andou %.1f m no meu PC, subiu até %.1f m (pulo), usou boost: %s" % [partida.times.get(quem, "?"), andou, mais_alto.get(quem, 0.0), "sim" if usou_boost.get(quem, false) else "NÃO"])
	for i in 600:
		await physics_frame
		if partida.carros.size() < 3:
			break
	print("host: depois que um amigo saiu, ficaram %d carros" % partida.carros.size())
	quit()
