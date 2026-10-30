extends SceneTree

# Roda sem tela: godot --headless --fixed-fps 120 --path jogo -s res://testes/teste_carro.gd
# Aperta os botões sozinho e mostra o que o carro fez.

var carro: RigidBody3D
var quadro := 0
var yaw_anterior := 0.0


func _initialize() -> void:
	if not InputMap.has_action("acelerar"):
		root.add_child(load("res://scripts/controles.gd").new())
	var cena: Node = load("res://cenas/campo_teste.tscn").instantiate()
	root.add_child(cena)
	carro = cena.get_node("Carro")


func _physics_process(_delta: float) -> bool:
	quadro += 1
	var t := quadro / 120.0
	Input.action_release("acelerar")
	Input.action_release("re")
	Input.action_release("direita")
	Input.action_release("freio_mao")
	if t > 2.0 and t <= 12.0:
		Input.action_press("acelerar")
	if t > 12.0 and t <= 16.0:
		Input.action_press("acelerar")
		Input.action_press("direita")
	if t > 16.0 and t <= 17.0:
		Input.action_press("acelerar")
		Input.action_press("direita")
		Input.action_press("freio_mao")
	if t > 17.0 and t <= 19.0:
		Input.action_press("re")
	if quadro % 60 == 0:
		var v := carro.linear_velocity
		var yaw := carro.global_rotation.y
		var giro := absf(wrapf(yaw - yaw_anterior, -PI, PI)) / 0.5
		yaw_anterior = yaw
		var raio := v.length() / giro if giro > 0.01 else INF
		print("t=%5.1fs  vel=%5.2f m/s  altura=%.3f  rodas=%d  giro=%.2f rad/s  raio=%s  pos=%s" % [t, v.length(), carro.global_position.y, carro.rodas_no_chao, giro, ("%.1f m" % raio) if raio < 1000 else "-", carro.global_position.snapped(Vector3.ONE * 0.1)])
	return t > 19.0
