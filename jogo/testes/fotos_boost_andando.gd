extends SceneTree

# O boost com o carro andando de verdade (é aí que dá pra ver se o fluido fica pra trás e curva):
# Godot ... --fixed-fps 60 -s res://testes/fotos_boost_andando.gd -- PASTA [estilos separados por vírgula]
# Pra cada estilo: acelera reto com boost, depois curva. Fotos de trás em reta, de trás na curva e de cima.

var pasta := ""
var estilos := [0, 2, 3, 6]
var quadro := 0
var carro: RigidBody3D
var camera := Camera3D.new()
const QUADROS := 170   # por estilo


func _initialize() -> void:
	var argumentos := OS.get_cmdline_user_args()
	pasta = argumentos[0]
	if argumentos.size() > 1:
		estilos = Array(argumentos[1].split(",")).map(func(t: String) -> int: return t.to_int())
	var campo: Node = load("res://cenas/campo_teste.tscn").instantiate()
	root.add_child(campo)
	carro = campo.get_node("Carro")
	camera.fov = 65.0
	root.add_child(camera)


func _process(_delta: float) -> bool:
	quadro += 1
	if quadro < 20:
		return false
	var passo := (quadro - 20) % QUADROS
	var qual := (quadro - 20) / QUADROS
	if qual >= estilos.size():
		return true
	if passo == 0:
		var escolha: Dictionary = carro.aparencia.duplicate()
		escolha["boost"] = estilos[qual]
		carro.vestir(escolha)
		carro.colocar_em(Transform3D(Basis(), Vector3(0, 0.4, 30)))
		carro.controle_local = false
		carro.boost = 100.0
	carro.comandos.acelerador = 1.0
	carro.comandos.boost = passo > 10
	carro.comandos.direcao = 0.8 if passo > 100 else 0.0
	camera.make_current()
	var t := carro.get_global_transform_interpolated()
	if passo < 140:
		camera.look_at_from_position(t * Vector3(2.2, 1.0, 3.6), t * Vector3(0, 0, 1.2))
	else:
		camera.look_at_from_position(t.origin + Vector3(0, 11, 0.01), t.origin + Vector3(0, 0, 0))
	for foto in [[95, "reta"], [135, "curva"], [168, "cima"]]:
		if passo == foto[0]:
			root.get_viewport().get_texture().get_image().save_png("%s/%d_%s.png" % [pasta, estilos[qual], foto[1]])
	return false
