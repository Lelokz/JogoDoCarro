extends SceneTree

# Explosão do gol em câmera lenta, em vários momentos (rodar com xvfb-run):
# Godot ... -s res://testes/fotos_explosao.gd -- PASTA

const MOMENTOS := [0.04, 0.12, 0.3, 0.6, 1.2, 2.2]   # segundos depois do gol
var pasta := ""
var quadro := 0
var tempo := -1.0
var foto := 0
var camera := Camera3D.new()


func _initialize() -> void:
	pasta = OS.get_cmdline_user_args()[0]
	root.add_child(load("res://cenas/arena.tscn").instantiate())
	camera.fov = 75.0
	root.add_child(camera)


func _process(delta: float) -> bool:
	quadro += 1
	if quadro == 60:
		root.get_node("Arena/Hud").visible = false
		camera.make_current()
		# de onde um jogador vê o gol, uns 25 m antes
		camera.look_at_from_position(Vector3(7, 4.5, -24), Vector3(0, 3, -50))
		load("res://scripts/explosao.gd").criar(root.get_node("Arena"), Vector3(0, 1.5, -51), Color(1.0, 0.5, 0.12), 2.5)
		Engine.time_scale = 0.05   # câmera lenta: sem placa de vídeo cada quadro demora
		tempo = 0.0
	elif tempo >= 0.0:
		tempo += delta
		if foto < MOMENTOS.size() and tempo >= MOMENTOS[foto]:
			root.get_viewport().get_texture().get_image().save_png("%s/e%d.png" % [pasta, foto])
			foto += 1
	return foto >= MOMENTOS.size() or quadro > 6000
