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
		return true
	return quadro > 3000


func foto(nome: String) -> void:
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [pasta, nome])
