extends SceneTree

# Fotos de um carro no pódio do Personalizar, de vários lados (rodar com xvfb-run):
# Godot ... -s res://testes/fotos_carro.gd -- PASTA MODELO [AEROFÓLIO] [baixo]
# "baixo": o carro sobe um pouco acima do pódio e a câmera olha por baixo (suspensão, assoalho)

var pasta := ""
var modelo := 0
var aerofolio := -1   # -1 = o que estiver salvo
var quadro := 0
var pronto_em := -1
var menu: Node
var baixo := false
var salvo := ""   # a personalização de quem joga: trocar o modelo pra foto salva por cima, então devolve no fim
# câmera em volta do carro (0 = de frente): lado, 3/4 de frente, frente, 3/4 de trás, trás, outro lado
const GIROS := [PI / 2.0, 0.65, 0.0, PI - 0.6, PI, -PI / 2.0]


func _initialize() -> void:
	var argumentos := OS.get_cmdline_user_args()
	pasta = argumentos[0]
	if argumentos.size() > 1:
		modelo = argumentos[1].to_int()
	if argumentos.size() > 2:
		aerofolio = argumentos[2].to_int()
	baixo = argumentos.size() > 3 and argumentos[3] == "baixo"
	if FileAccess.file_exists("user://personalizacao.json"):
		salvo = FileAccess.get_file_as_string("user://personalizacao.json")
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
		if baixo:
			menu.altura_carro += 1.0
	if pronto_em < 0:
		return quadro > 3000
	var passo := quadro - pronto_em - 90
	if baixo and passo >= 0:
		# cada roda numa altura: uma no fim do curso, uma solta, duas como parado (a suspensão acompanha)
		menu.carro.compressao = [0.0, 0.12, 0.055, 0.0]
		menu.carro.atualizar_rodas_desenhadas(0.0)
	if passo >= 0 and passo % 6 == 0 and passo / 6 < GIROS.size():
		menu.orbita_alvo = Vector4(GIROS[passo / 6], [-0.05, -0.2, -0.05, -0.2, -0.05, -0.25][passo / 6] if baixo else 0.2, 1.8 if baixo else 3.3, -0.12 if baixo else 0.0)
		menu.orbita = menu.orbita_alvo
		menu.girar_carro()
	if passo >= 0 and passo % 6 == 2 and passo / 6 < GIROS.size():
		root.get_viewport().get_texture().get_image().save_png("%s/g%d.png" % [pasta, passo / 6])
	if passo > GIROS.size() * 6 + 2:
		if salvo != "":
			var arquivo := FileAccess.open("user://personalizacao.json", FileAccess.WRITE)
			arquivo.store_string(salvo)
			arquivo.close()
		return true
	return false
