class_name TelaPersonalizar
extends Control

# Personalizar, tipo garagem: o carro no pódio no meio, as abas na esquerda (carro, pintura, rodas,
# boost, rastro, teto, antena, aerofólio, explosão do gol) e as opções da aba na direita, em cartões
# que rolam com a rodinha do mouse. Arrastando no meio gira a câmera em volta do carro; a rodinha
# no meio aproxima. Cada aba leva a câmera pra parte do carro que importa (rodas, traseira, teto...).
# Salva sozinho a cada clique ("Salvo ✓"); DESFAZER volta pro que era quando a tela abriu.

signal fechou

# [aba, título, [[escolha, rótulo, jeito do cartão], ...]]; aba sem nada = "em breve"
const ABAS := [
	["carro", "CARRO", [["modelo", "Modelo", "carros"]]],
	["pintura", "PINTURA", [["detalhe", "Cor dos detalhes (desenho e rodas)", "cores"], ["desenho", "Desenho", "lista"]]],
	["rodas", "RODAS", []],
	["boost", "BOOST", [["boost", "Estilo", "lista"], ["boost_cor", "Cor", "cores"]]],
	["rastro", "RASTRO", []],
	["teto", "TETO", [["teto", "Enfeite de teto", "lista"]]],
	["antena", "ANTENA", [["antena", "Antena", "lista"]]],
	["aerofolio", "AEROFÓLIO", [["aerofolio", "Aerofólio", "lista"]]],
	["gol", "EXPLOSÃO DO GOL", []],
]
# pra onde a câmera olha em cada aba: [giro em volta, altura (rad), distância, altura do alvo]
const VISTAS := {
	"carro": [0.65, 0.22, 3.3, 0.0],
	"pintura": [0.9, 0.3, 3.0, 0.0],
	"rodas": [1.45, 0.06, 2.0, -0.12],
	"boost": [PI - 0.55, 0.2, 2.9, 0.0],
	"rastro": [PI - 0.9, 0.35, 3.2, -0.1],
	"teto": [0.5, 0.55, 2.6, 0.15],
	"antena": [PI - 0.9, 0.35, 2.7, 0.1],
	"aerofolio": [PI - 0.6, 0.32, 2.6, 0.05],
	"gol": [0.65, 0.22, 3.3, 0.0],
}

var carro: Node3D
var menu: Node
var escolha := Aparencia.minha()
var inicial := escolha.duplicate()
var aba := "carro"
var time := "azul"           # só pra ver o carro nas duas cores (a de verdade é a do time em que cair)
var tempo := 0.0
var salvo_ate := 0.0
var cartoes := {}            # escolha → [botões], pra marcar o escolhido
var nomes := {}              # escolha → rótulo com o nome do escolhido
var botoes_aba := {}
var botoes_time := []
var conteudo := VBoxContainer.new()
var rolagem := ScrollContainer.new()
var titulo_aba := Label.new()
var aviso := Label.new()
var arrastando := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# atrás de tudo: arrastar e rodinha no meio da tela mexem a câmera
	var fundo := Control.new()
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.mouse_filter = Control.MOUSE_FILTER_STOP
	fundo.gui_input.connect(mexer_camera)
	add_child(fundo)
	var titulo := Estilo.rotulo("PERSONALIZAR", 40, Estilo.TEXTO, Estilo.titulo())
	titulo.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 22)
	titulo.grow_horizontal = Control.GROW_DIRECTION_BOTH
	titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(titulo)
	montar_abas()
	montar_painel()
	montar_barra()
	carro.vestir(escolha)
	pintar_time()
	abrir_aba("carro")


func montar_abas() -> void:
	var caixa := PanelContainer.new()
	caixa.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT, Control.PRESET_MODE_MINSIZE, 30)
	caixa.grow_vertical = Control.GROW_DIRECTION_BOTH
	caixa.custom_minimum_size.x = 230
	add_child(caixa)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 6)
	caixa.add_child(coluna)
	for a in ABAS:
		var vazia: bool = a[2].is_empty()
		var b := Estilo.botao(a[1] + ("  · em breve" if vazia else ""), func() -> void: abrir_aba(a[0]), 46)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_override("font", Estilo.titulo())
		b.add_theme_font_size_override("font_size", 17 if vazia else 19)
		b.disabled = vazia
		coluna.add_child(b)
		botoes_aba[a[0]] = b


func montar_painel() -> void:
	var caixa := PanelContainer.new()
	caixa.anchor_left = 1.0
	caixa.anchor_right = 1.0
	caixa.anchor_bottom = 1.0
	caixa.offset_left = -440
	caixa.offset_right = -30
	caixa.offset_top = 86
	caixa.offset_bottom = -104
	add_child(caixa)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 10)
	caixa.add_child(coluna)
	titulo_aba.add_theme_font_override("font", Estilo.titulo())
	titulo_aba.add_theme_font_size_override("font_size", 26)
	titulo_aba.add_theme_color_override("font_color", Estilo.LARANJA)
	coluna.add_child(titulo_aba)
	rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	coluna.add_child(rolagem)
	conteudo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	conteudo.add_theme_constant_override("separation", 14)
	rolagem.add_child(conteudo)


func montar_barra() -> void:
	var barra := HBoxContainer.new()
	barra.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 26)
	barra.grow_horizontal = Control.GROW_DIRECTION_BOTH
	barra.grow_vertical = Control.GROW_DIRECTION_BEGIN
	barra.add_theme_constant_override("separation", 10)
	add_child(barra)
	for qual in ["azul", "laranja"]:
		var b := Estilo.botao("VER " + qual.to_upper(), func() -> void:
			time = qual
			pintar_time(), 54)
		b.custom_minimum_size.x = 130
		barra.add_child(b)
		botoes_time.append(b)
	var espaco := Control.new()
	espaco.custom_minimum_size.x = 18
	barra.add_child(espaco)
	var desfazer := Estilo.botao("DESFAZER", func() -> void: trocar_tudo(inicial.duplicate()), 54)
	var pronto := Estilo.botao("PRONTO", sair, 54)
	pronto.add_theme_stylebox_override("normal", Estilo.caixa(Color(0.95, 0.45, 0.1, 0.95), Color(1, 0.8, 0.5, 0.6), 10, 1))
	pronto.add_theme_stylebox_override("hover", Estilo.caixa(Color(1.0, 0.58, 0.2, 1.0), Color.WHITE, 10, 2))
	pronto.add_theme_stylebox_override("pressed", Estilo.caixa(Color(0.85, 0.38, 0.08, 1.0), Color.WHITE, 10, 2))
	for b in [desfazer, pronto]:
		b.custom_minimum_size.x = 150
		b.add_theme_font_override("font", Estilo.titulo())
		barra.add_child(b)
	# "Salvo ✓" (ou o aviso de que o navegador não guarda)
	aviso.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 36)
	aviso.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	aviso.grow_vertical = Control.GROW_DIRECTION_BEGIN
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	aviso.add_theme_font_override("font", Estilo.titulo())
	aviso.add_theme_font_size_override("font_size", 20)
	aviso.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	aviso.add_theme_constant_override("outline_size", 6)
	aviso.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(aviso)
	if not Aparencia.navegador_guarda():
		aviso.text = "Este navegador não está guardando nada\n(aba anônima?): a personalização some ao fechar."
		aviso.add_theme_color_override("font_color", Color(1.0, 0.45, 0.35))


func abrir_aba(qual: String) -> void:
	aba = qual
	for a in ABAS:
		if a[0] == qual:
			titulo_aba.text = a[1]
			montar_cartoes(a[2])
	for nome in botoes_aba:
		var b: Button = botoes_aba[nome]
		if nome == qual:
			b.add_theme_stylebox_override("normal", Estilo.caixa(Color(0.95, 0.45, 0.1, 0.9), Color(1, 0.8, 0.5, 0.6), 10, 1))
		else:
			b.remove_theme_stylebox_override("normal")
	var v: Array = VISTAS[qual]
	menu.mirar(v[0], v[1], v[2], v[3])
	rolagem.scroll_vertical = 0


func montar_cartoes(secoes: Array) -> void:
	for filho in conteudo.get_children():
		filho.queue_free()
	cartoes.clear()
	nomes.clear()
	for secao in secoes:
		var chave: String = secao[0]
		var linha := HBoxContainer.new()
		linha.add_child(Estilo.rotulo(secao[1], 16, Estilo.TEXTO_APAGADO))
		var nome := Estilo.rotulo("", 16, Estilo.TEXTO)
		nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		linha.add_child(nome)
		nomes[chave] = nome
		conteudo.add_child(linha)
		var opcoes := opcoes_de(chave)
		var grade := GridContainer.new()
		grade.add_theme_constant_override("h_separation", 8)
		grade.add_theme_constant_override("v_separation", 8)
		grade.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		conteudo.add_child(grade)
		var lista := []
		match secao[2]:
			"carros":
				grade.columns = 1
				for i in opcoes.size():
					var b := cartao("%s\n%s" % [opcoes[i].to_upper(), Aparencia.SOBRE_MODELOS[i]], chave, i, Vector2(0, 84))
					b.alignment = HORIZONTAL_ALIGNMENT_LEFT
					b.clip_text = false
					b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
					b.add_theme_font_size_override("font_size", 16)
					grade.add_child(b)
					lista.append(b)
			"cores":
				grade.columns = 6
				for i in opcoes.size():
					var b := cartao("", chave, i, Vector2(52, 52))
					b.tooltip_text = opcoes[i][0]
					b.set_meta("cor", opcoes[i][1])
					grade.add_child(b)
					lista.append(b)
			_:
				grade.columns = 2
				for i in opcoes.size():
					var b := cartao(opcoes[i], chave, i, Vector2(0, 58))
					grade.add_child(b)
					lista.append(b)
		cartoes[chave] = lista
	marcar()


func cartao(texto: String, chave: String, valor: int, tamanho: Vector2) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = tamanho
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.clip_text = true
	b.add_theme_font_size_override("font_size", 18)
	b.pressed.connect(func() -> void: escolher(chave, valor))
	return b


func opcoes_de(chave: String) -> Array:
	for e in Aparencia.ESCOLHAS:
		if e[0] == chave:
			return e[1]
	return []


func escolher(chave: String, valor: int) -> void:
	escolha[chave] = valor
	aplicar()


func trocar_tudo(nova: Dictionary) -> void:
	escolha = Aparencia.limpa(nova)
	aplicar()


func aplicar() -> void:
	var modelo_antes: int = carro.aparencia.modelo
	carro.vestir(escolha)
	if carro.aparencia.modelo != modelo_antes:
		menu.assentar_rodas()
	pintar_time()
	marcar()
	# salva na hora: não tem como sair sem salvar
	if Aparencia.salvar(escolha):
		if Aparencia.navegador_guarda():
			aviso.text = "Salvo ✓"
			aviso.add_theme_color_override("font_color", Color(0.55, 1.0, 0.6))
			salvo_ate = tempo + 1.6
	else:
		aviso.text = "Não deu pra salvar!"
		aviso.add_theme_color_override("font_color", Color(1.0, 0.45, 0.35))
		salvo_ate = tempo + 4.0


func marcar() -> void:
	# o escolhido de cada grupo fica com borda branca (e o nome dele aparece do lado do título)
	for chave in cartoes:
		var atual: int = escolha[chave]
		var botoes: Array = cartoes[chave]
		for i in botoes.size():
			var b: Button = botoes[i]
			var marcado := i == atual
			if b.has_meta("cor"):
				var cor: Color = b.get_meta("cor")
				b.add_theme_stylebox_override("normal", Estilo.caixa(cor, Color.WHITE if marcado else Color(1, 1, 1, 0.15), 10, 4 if marcado else 1, 0))
				b.add_theme_stylebox_override("hover", Estilo.caixa(cor.lightened(0.15), Color.WHITE, 10, 4 if marcado else 2, 0))
				b.add_theme_stylebox_override("pressed", Estilo.caixa(cor, Color.WHITE, 10, 4, 0))
			elif marcado:
				b.add_theme_stylebox_override("normal", Estilo.caixa(Color(0.16, 0.3, 0.55, 0.95), Color.WHITE, 10, 3))
			else:
				b.remove_theme_stylebox_override("normal")
		var opcoes := opcoes_de(chave)
		var nome = opcoes[atual]
		nomes[chave].text = nome[0] if nome is Array else nome
	for i in botoes_time.size():
		var b: Button = botoes_time[i]
		if (i == 0) == (time == "azul"):
			b.add_theme_stylebox_override("normal", Estilo.caixa(Color(0.16, 0.3, 0.55, 0.95), Color.WHITE, 10, 3))
		else:
			b.remove_theme_stylebox_override("normal")


func pintar_time() -> void:
	carro.tinta.set_shader_parameter("cor", Color(0.2, 0.45, 0.95) if time == "azul" else Color(1.0, 0.5, 0.12))
	marcar()


func mexer_camera(evento: InputEvent) -> void:
	if evento is InputEventMouseButton:
		if evento.button_index == MOUSE_BUTTON_LEFT:
			arrastando = evento.pressed
		elif evento.pressed and evento.button_index == MOUSE_BUTTON_WHEEL_UP:
			menu.aproximar(0.9)
		elif evento.pressed and evento.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			menu.aproximar(1.1)
	elif evento is InputEventMouseMotion and arrastando:
		menu.girar_camera(-evento.relative.x * 0.008, evento.relative.y * 0.005)


func _process(delta: float) -> void:
	tempo += delta
	# na aba do boost, o boost fica ligado pra ver
	var boostando := aba == "boost"
	carro.rastro.emitting = boostando
	carro.turbina.set_shader_parameter("forca_brilho", 4.0 if boostando else 0.5)
	if salvo_ate > 0.0 and tempo > salvo_ate:
		salvo_ate = 0.0
		aviso.text = ""


func sair() -> void:
	carro.rastro.emitting = false
	carro.turbina.set_shader_parameter("forca_brilho", 0.5)
	carro.vestir(Aparencia.minha())
	fechou.emit()
	queue_free()


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("menu"):
		get_viewport().set_input_as_handled()
		sair()
