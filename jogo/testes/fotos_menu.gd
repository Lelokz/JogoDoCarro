extends SceneTree

# Fotos do menu sem abrir janela (rodar com xvfb-run): ./tirar_fotos.sh PASTA

var pasta := ""
var quadro := 0
var pronto_em := -1
var menu: Node


func _initialize() -> void:
	for argumento in OS.get_cmdline_user_args():
		pasta = argumento
	menu = load("res://cenas/menu.tscn").instantiate()
	root.add_child(menu)


func _process(_delta: float) -> bool:
	quadro += 1
	if quadro == 20:
		foto("m0_carregando")
	if pronto_em < 0 and not menu.carregando.visible:
		pronto_em = quadro
	if pronto_em > 0 and quadro == pronto_em + 90:
		foto("m1_menu")
	if pronto_em > 0 and quadro == pronto_em + 200:
		foto("m2_menu_girou")
		menu.mostrar(menu.pagina_jogar)
	if pronto_em > 0 and quadro == pronto_em + 215:
		foto("m3_jogar")
		menu.abrir_entrar(menu.codigo if OS.has_feature("web") else menu.endereco)
	if pronto_em > 0 and quadro == pronto_em + 230:
		foto("m4_entrar")
		menu.mostrar(menu.escolha_solo)
	if pronto_em > 0 and quadro == pronto_em + 245:
		foto("m5_jogar_solo")
		menu.mostrar(menu.inicio)
		menu.abrir_personalizar()
	# a tela do Personalizar em várias abas
	var abas := ["carro", "pintura", "boost", "teto", "aerofolio"]
	for k in abas.size():
		if pronto_em > 0 and quadro == pronto_em + 330 + k * 40:
			var t: Node = menu.tela_personalizar
			t.abrir_aba(abas[k])
			match abas[k]:
				"pintura":
					t.escolher("detalhe", 4)
				"boost":
					t.escolher("boost_cor", 1)
				"teto":
					t.escolher("teto", 1)
				"aerofolio":
					t.escolher("aerofolio", 1)
		if pronto_em > 0 and quadro == pronto_em + 360 + k * 40:
			foto("p%d_%s" % [k, abas[k]])
	if pronto_em > 0 and quadro == pronto_em + 530:
		return true
	return quadro > 3000


func foto(nome: String) -> void:
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [pasta, nome])
