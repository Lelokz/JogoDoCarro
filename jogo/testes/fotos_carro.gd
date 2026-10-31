extends SceneTree

# Fotos de um carro no pódio do Personalizar, de vários lados (rodar com xvfb-run):
# Godot ... -s res://testes/fotos_carro.gd -- PASTA MODELO [AEROFÓLIO]

var pasta := ""
var modelo := 0
var aerofolio := -1   # -1 = o que estiver salvo
var quadro := 0
var pronto_em := -1
var menu: Node
# câmera em volta do carro (0 = de frente): lado, 3/4 de frente, frente, 3/4 de trás, trás, outro lado
const GIROS := [PI / 2.0, 0.65, 0.0, PI - 0.6, PI, -PI / 2.0]


func _initialize() -> void:
	var argumentos := OS.get_cmdline_user_args()
	pasta = argumentos[0]
	if argumentos.size() > 1:
		modelo = argumentos[1].to_int()
	if argumentos.size() > 2:
		aerofolio = argumentos[2].to_int()
	menu = load("res://cenas/menu.tscn").instantiate()
	root.add_child(menu)


func _process(_delta: float) -> bool:
	quadro += 1
	if pronto_em < 0 and not menu.carregando.visible:
		pronto_em = quadro
		menu.abrir_personalizar()
		menu.tela_personalizar.escolher("modelo", modelo)
		if aerofolio >= 0:
			menu.tela_personalizar.escolher("aerofolio", aerofolio)
		menu.tela_personalizar.visible = false
	if pronto_em < 0:
		return quadro > 3000
	var passo := quadro - pronto_em - 90
	if passo >= 0 and passo % 6 == 0 and passo / 6 < GIROS.size():
		menu.orbita_alvo = Vector4(GIROS[passo / 6], 0.2, 3.3, 0.0)
		menu.orbita = menu.orbita_alvo
		menu.girar_carro()
	if passo >= 0 and passo % 6 == 2 and passo / 6 < GIROS.size():
		root.get_viewport().get_texture().get_image().save_png("%s/g%d.png" % [pasta, passo / 6])
	return passo > GIROS.size() * 6 + 2
