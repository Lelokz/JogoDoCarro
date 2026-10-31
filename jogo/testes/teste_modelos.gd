extends SceneTree

# Roda sem tela: godot --headless --fixed-fps 120 --path jogo -s res://testes/teste_modelos.gd
# Cada carro (cada um tem a sua caixa de batida e o lugar das rodas): anda, faz curva, pula, dá mortal,
# sobe na parede do campo de teste e bate na bola. Pra ver que nenhum ficou torto ou roubado.

var carro: RigidBody3D
var cena: Node


func _initialize() -> void:
	if not InputMap.has_action("acelerar"):
		root.add_child(load("res://scripts/controles.gd").new())
	cena = load("res://cenas/campo_teste.tscn").instantiate()
	root.add_child(cena)
	carro = cena.get_node("Carro")
	rodar()


func rodar() -> void:
	await physics_frame
	var aparencia: GDScript = load("res://scripts/aparencia.gd")
	for modelo in aparencia.MODELOS.size():
		carro.vestir({"modelo": modelo})
		await colocar(Vector3(300, 0.6, 300), Basis())
		var parado: float = carro.global_position.y
		Input.action_press("acelerar")
		await esperar(4.0)
		var reta: float = carro.linear_velocity.length()
		Input.action_press("direita")
		await esperar(3.0)
		var curva: float = carro.linear_velocity.length() / maxf(carro.angular_velocity.length(), 0.01)
		var rodas_curva: int = carro.rodas_no_chao
		Input.action_release("direita")
		Input.action_release("acelerar")
		await colocar(Vector3(300, 0.6, 300), Basis())
		await apertar("pulo", 36)
		var pulo: float = await maior_altura(2.0) - parado
		await esperar(1.0)
		await apertar("pulo", 1)
		await esperar(0.1)
		Input.action_press("nariz_baixo")
		await apertar("pulo", 1)
		await esperar(1.2)
		Input.action_release("nariz_baixo")
		await esperar(1.0)
		var em_pe: bool = carro.global_basis.y.dot(Vector3.UP) > 0.9 and carro.rodas_no_chao == 4
		print("%-8s parado a %.3f m · reta %.1f m/s · curva raio %.1f m (%d rodas no chão) · pulo %.2f m · mortal termina de rodas pra baixo: %s" % [aparencia.MODELOS[modelo], parado, reta, curva, rodas_curva, pulo, "sim" if em_pe else "NÃO"])
	quit()


func colocar(posicao: Vector3, base: Basis) -> void:
	for acao in ["acelerar", "re", "direita", "esquerda", "nariz_baixo", "nariz_cima", "boost", "pulo", "freio_mao"]:
		Input.action_release(acao)
	carro.global_transform = Transform3D(base, posicao)
	carro.linear_velocity = Vector3.ZERO
	carro.angular_velocity = Vector3.ZERO
	carro.teleportou = true
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
	var maior := -INF
	for i in roundi(segundos * 120.0):
		await physics_frame
		maior = maxf(maior, carro.global_position.y)
	return maior
