extends SceneTree

# Roda sem tela: godot --headless --fixed-fps 120 --path jogo -s res://testes/teste_bola.gd
# Testa quique e rolagem da bola e as batidas do carro (andando, com boost e com mortal).

var carro: RigidBody3D
var bola: RigidBody3D


func _initialize() -> void:
	if not InputMap.has_action("acelerar"):
		root.add_child(load("res://scripts/controles.gd").new())
	var cena: Node = load("res://cenas/campo_teste.tscn").instantiate()
	root.add_child(cena)
	carro = cena.get_node("Carro")
	bola = cena.get_node("Bola")
	rodar()


func rodar() -> void:
	await physics_frame   # os botões só existem depois do primeiro quadro
	carro.global_transform = Transform3D(Basis(), Vector3(-300, 0.6, 300))
	colocar_bola(Vector3(200, 10, -200), Vector3.ZERO)
	var picos := []
	var subindo := false
	var anterior := bola.global_position.y
	for i in 1200:
		await physics_frame
		var y := bola.global_position.y
		if subindo and y < anterior:
			picos.append("%.2f" % (anterior - 0.9125))
		subindo = y > anterior
		anterior = y
	print("bola solta de 9,1 m: quicou até %s m" % ", ".join(picos.slice(0, 5)))

	colocar_bola(Vector3(-200, 0.92, -200), Vector3(20, 0, 0))
	await esperar(5.0)
	print("bola rolando a 20 m/s: depois de 5 s está a %.1f m/s" % bola.linear_velocity.length())

	colocar_bola(Vector3(-200, 5, 0), Vector3(100, 0, 0))
	await physics_frame
	await physics_frame
	print("bola jogada a 100 m/s: ficou em %.1f m/s (máximo 60)" % bola.linear_velocity.length())

	for teste in [["andando", 30.0, false, false], ["com boost", 45.0, true, false], ["com mortal", 30.0, false, true]]:
		colocar_bola(Vector3(0, 0.92, 200), Vector3.ZERO)
		carro.global_transform = Transform3D(Basis(), Vector3(0, 0.6, 200 + teste[1]))
		carro.linear_velocity = Vector3.ZERO
		carro.angular_velocity = Vector3.ZERO
		carro.boost = 100.0
		await esperar(1.0)
		Input.action_press("acelerar")
		if teste[2]:
			Input.action_press("boost")
		var velocidade_carro := 0.0
		var mortal_feito := false
		var maior := 0.0
		for i in 600:
			await physics_frame
			var distancia := bola.global_position.distance_to(carro.global_position)
			if teste[3] and not mortal_feito and distancia < 6.0:
				mortal_feito = true
				Input.action_press("pulo")
				await physics_frame
				Input.action_release("pulo")
				await esperar(0.08)
				Input.action_press("nariz_baixo")
				Input.action_press("pulo")
				await physics_frame
				Input.action_release("pulo")
				await esperar(0.05)
				Input.action_release("nariz_baixo")
			if velocidade_carro == 0.0 and distancia < 1.9:
				velocidade_carro = carro.linear_velocity.length()
			maior = maxf(maior, bola.linear_velocity.length())
			if velocidade_carro > 0.0 and i > 0 and bola.global_position.z < 200 - 30:
				break
		Input.action_release("acelerar")
		Input.action_release("boost")
		print("batida %-10s carro a %4.1f m/s (%3d km/h) → bola saiu a %4.1f m/s (%3d km/h), subiu a %.1f m" % [teste[0], velocidade_carro, roundi(velocidade_carro * 3.6), maior, roundi(maior * 3.6), bola.global_position.y])
	quit()


func colocar_bola(posicao: Vector3, velocidade: Vector3) -> void:
	bola.global_transform = Transform3D(Basis(), posicao)
	bola.linear_velocity = velocidade
	bola.angular_velocity = Vector3.ZERO


func esperar(segundos: float) -> void:
	for i in roundi(segundos * 120.0):
		await physics_frame
