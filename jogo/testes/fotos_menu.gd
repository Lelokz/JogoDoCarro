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
	if pronto_em > 0 and quadro == pronto_em + 330:
		foto("m6_personalizar")
		var t: Node = menu.tela_personalizar
		t.escolher("detalhe", 3)
		t.escolher("fogo", 1)
		t.escolher("enfeite", 2)
	if pronto_em > 0 and quadro == pronto_em + 360:
		foto("m7_personalizado")
		var t: Node = menu.tela_personalizar
		t.time = "laranja"
		t.pintar_time()
		t.escolher("detalhe", 2)
		t.escolher("fogo", 3)
		t.escolher("rastro", 2)
		t.escolher("enfeite", 1)
	if pronto_em > 0 and quadro == pronto_em + 372:
		foto("m8_antena_fumaca")
		menu.tela_personalizar.escolher("enfeite", 3)
		menu.tela_personalizar.escolher("rastro", 1)
	if pronto_em > 0 and quadro == pronto_em + 386:
		foto("m9_aerofolio_faiscas")
		menu.tela_personalizar.escolher("enfeite", 0)
		menu.tela_personalizar.escolher("detalhe", 3)
	# os 5 carros, de frente e de trás (o tempo do menu manda no giro)
	for k in 10:
		if pronto_em > 0 and quadro == pronto_em + 400 + k * 12:
			menu.tela_personalizar.escolher("modelo", k % 5)
		if pronto_em > 0 and quadro == pronto_em + 410 + k * 12:
			menu.tempo = 3.6 if k < 5 else 10.5
			menu.girar_carro()
		if pronto_em > 0 and quadro == pronto_em + 411 + k * 12:
			foto("c%d_%s" % [k, Aparencia.MODELOS[k % 5]])
	if pronto_em > 0 and quadro == pronto_em + 530:
		return true
	return quadro > 3000


func foto(nome: String) -> void:
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [pasta, nome])
