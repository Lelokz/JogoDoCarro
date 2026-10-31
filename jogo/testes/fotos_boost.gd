extends SceneTree

# Cada estilo de boost ligado no pódio (rodar com xvfb-run): Godot ... -s res://testes/fotos_boost.gd -- PASTA
# Não salva nada: mexe só no carro do pódio.

var pasta := ""
var quadro := 0
var pronto_em := -1
var menu: Node
const CORES := [0, 1, 6, 3, 8, 4, 0]   # uma cor diferente pra cada estilo


func _initialize() -> void:
	pasta = OS.get_cmdline_user_args()[0]
	menu = load("res://cenas/menu.tscn").instantiate()
	root.add_child(menu)


func _process(_delta: float) -> bool:
	quadro += 1
	if pronto_em < 0 and not menu.carregando.visible:
		pronto_em = quadro
		menu.abrir_personalizar()
		menu.tela_personalizar.abrir_aba("boost")
		menu.tela_personalizar.visible = false
		menu.tela_personalizar.set_process(false)
		menu.carro.chama.ligado = true
	if pronto_em < 0:
		return quadro > 3000
	var passo := quadro - pronto_em - 60
	var estilos: int = load("res://scripts/aparencia.gd").BOOSTS.size()
	if passo >= 0 and passo % 20 == 0 and passo / 20 < estilos:
		var escolha: Dictionary = menu.carro.aparencia.duplicate()
		escolha["boost"] = passo / 20
		escolha["boost_cor"] = CORES[passo / 20]
		menu.carro.vestir(escolha)
		menu.carro.chama.ligado = true
		menu.orbita_alvo = Vector4(PI - 0.75, 0.18, 2.6, 0.0)
		menu.orbita = menu.orbita_alvo
	if passo >= 0 and passo % 20 == 16 and passo / 20 < estilos:
		root.get_viewport().get_texture().get_image().save_png("%s/b%d.png" % [pasta, passo / 20])
	return passo > estilos * 20
