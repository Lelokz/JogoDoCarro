extends SceneTree

# Fotos do visual sem abrir janela na tela (rodar com xvfb-run): ./tirar_fotos.sh PASTA
# Cada foto: [nome, posição da câmera, pra onde olha] (null = câmera do jogo; "pausa"/"opcoes" = abre a tela).
# Nas fotos "carro_" as posições são em volta do carro (a frente dele é o -Z).

const FOTOS := [
	["1_jogo", null, null],
	["2_carro_frente", Vector3(1.0, 0.35, -1.3), Vector3(0, 0.0, 0)],
	["3_carro_tras", Vector3(-0.9, 0.5, 1.4), Vector3(0, 0.0, 0)],
	["3b_carro_lado", Vector3(1.9, 0.25, 0.0), Vector3(0, 0.0, 0)],
	["4_bola", Vector3(2.4, 1.3, 2.6), Vector3(0, 0.9, 0)],
	["5_geral", Vector3(34, 17, 62), Vector3(0, 0, 0)],
	["6_gol", Vector3(9, 4, 30), Vector3(0, 3, 50)],
	["7_arquibancada", Vector3(-10, 3, 5), Vector3(40, 14, 20)],
	["1b_hud_rapido", "hud", null],
	["8_pausa", "pausa", null],
	["9_opcoes", "opcoes", null],
]

var pasta := ""
var quadro := 0
var foto := 0
var camera := Camera3D.new()


func _initialize() -> void:
	for argumento in OS.get_cmdline_user_args():
		pasta = argumento
	root.add_child(load("res://cenas/arena.tscn").instantiate())
	camera.fov = 70.0
	root.add_child(camera)


func _process(_delta: float) -> bool:
	quadro += 1
	if quadro < 40 or quadro % 15 != 0:
		return false
	if foto > 0:
		root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [pasta, FOTOS[foto - 1][0]])
	if foto == FOTOS.size():
		return true
	var f: Array = FOTOS[foto]
	if f[1] is String:
		root.get_node("Arena/Camera").make_current()
		if f[1] == "hud":
			# só os números do mostrador (o carro está parado na contagem)
			var hud: Node = root.get_node("Arena/Hud")
			hud.set_process(false)
			hud.velocimetro.velocidade = 22.4
			hud.velocimetro.supersonico = true
			hud.velocimetro.boost = 64.0
			hud.velocimetro.boostando = true
		elif f[1] == "pausa":
			root.get_node("Arena/Hud").set_process(true)
			# carregado na hora: scripts -s não enxergam os autoloads que a Pausa usa na compilação
			var pausa: Node = load("res://scripts/pausa.gd").new()
			pausa.name = "Pausa"
			root.get_node("Arena").add_child(pausa)
		else:
			root.get_node("Arena/Pausa").abrir_opcoes()
	elif f[1] == null:
		root.get_node("Arena/Camera").make_current()
	elif f[0].contains("carro_"):
		var carro: Node3D = root.get_node("Arena/Carro")
		camera.make_current()
		camera.look_at_from_position(carro.global_transform * f[1], carro.global_transform * f[2])
	else:
		camera.make_current()
		camera.look_at_from_position(f[1], f[2])
	foto += 1
	return false
