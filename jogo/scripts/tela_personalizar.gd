class_name TelaPersonalizar
extends Control

# Personalizar (aberta pelo menu, com o carro no pódio no meio da tela):
# na esquerda os carros, na direita os detalhes (faixas e rodas, fogo do boost, rastro, enfeite).
# Cada clique já aparece no carro; SALVAR guarda, VOLTAR (ou ESC) desfaz.

signal fechou

var carro: Node3D
var escolha := Aparencia.minha()
var time := "azul"           # só pra ver o carro nas duas cores
var boost_ate := 0.0         # mostra o boost um pouco depois de trocar o fogo ou o rastro
var tempo := 0.0
var grupos := {}             # nome da opção → [botões], pra marcar o escolhido
var nomes := {}              # nome da opção → rótulo com o nome do escolhido
var sobre_modelo := Label.new()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var titulo := Estilo.rotulo("PERSONALIZAR", 40, Estilo.TEXTO, Estilo.titulo())
	titulo.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 28)
	titulo.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(titulo)
	montar_carros()
	montar_detalhes()
	marcar()
	carro.vestir(escolha)
	pintar_time()


func painel(lado_direito: bool, largura: int) -> VBoxContainer:
	var caixa := PanelContainer.new()
	if lado_direito:
		caixa.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT, Control.PRESET_MODE_MINSIZE, 40)
		caixa.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	else:
		caixa.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT, Control.PRESET_MODE_MINSIZE, 40)
	caixa.grow_vertical = Control.GROW_DIRECTION_BOTH
	caixa.custom_minimum_size.x = largura
	add_child(caixa)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 8)
	caixa.add_child(coluna)
	return coluna


func montar_carros() -> void:
	var coluna := painel(false, 250)
	coluna.add_child(Estilo.rotulo("CARROS", 22, Estilo.LARANJA, Estilo.titulo()))
	var botoes := []
	for i in Aparencia.MODELOS.size():
		var b := Estilo.botao(Aparencia.MODELOS[i].to_upper(), func() -> void: escolher("modelo", i), 50)
		b.add_theme_font_override("font", Estilo.titulo())
		coluna.add_child(b)
		botoes.append(b)
	grupos["modelo"] = botoes
	sobre_modelo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sobre_modelo.add_theme_font_size_override("font_size", 16)
	sobre_modelo.custom_minimum_size.y = 44
	coluna.add_child(sobre_modelo)
	coluna.add_child(Estilo.rotulo("cada um tem o seu tamanho de batida;\no resto anda igual", 13, Estilo.TEXTO_APAGADO))


func montar_detalhes() -> void:
	var coluna := painel(true, 360)
	secao(coluna, "time", "VER NO TIME")
	var times := HBoxContainer.new()
	times.add_theme_constant_override("separation", 8)
	var botoes_time := []
	for qual in ["azul", "laranja"]:
		var b := Estilo.botao(qual.to_upper(), func() -> void:
			time = qual
			pintar_time()
			marcar(), 40)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		times.add_child(b)
		botoes_time.append(b)
	grupos["time"] = botoes_time
	coluna.add_child(times)
	paleta(coluna, "detalhe", "DETALHES (faixas e rodas)", Aparencia.DETALHES)
	paleta(coluna, "fogo", "FOGO DO BOOST", Aparencia.FOGOS)
	lista(coluna, "rastro", "RASTRO", Aparencia.RASTROS, 3)
	lista(coluna, "enfeite", "ENFEITE", Aparencia.ENFEITES, 2)
	var espaco := Control.new()
	espaco.custom_minimum_size.y = 6
	coluna.add_child(espaco)
	var fim := HBoxContainer.new()
	fim.add_theme_constant_override("separation", 8)
	var salvar := Estilo.botao("SALVAR", func() -> void:
		Aparencia.salvar(escolha)
		sair(), 54)
	salvar.add_theme_stylebox_override("normal", Estilo.caixa(Color(0.95, 0.45, 0.1, 0.95), Color(1, 0.8, 0.5, 0.6), 10, 1))
	salvar.add_theme_stylebox_override("hover", Estilo.caixa(Color(1.0, 0.58, 0.2, 1.0), Color.WHITE, 10, 2))
	salvar.add_theme_stylebox_override("pressed", Estilo.caixa(Color(0.85, 0.38, 0.08, 1.0), Color.WHITE, 10, 2))
	var voltar := Estilo.botao("VOLTAR", sair, 54)
	for b in [salvar, voltar]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_override("font", Estilo.titulo())
		fim.add_child(b)
	coluna.add_child(fim)


func secao(coluna: VBoxContainer, nome: String, texto: String) -> void:
	var linha := HBoxContainer.new()
	linha.add_child(Estilo.rotulo(texto, 16, Estilo.LARANJA, Estilo.titulo()))
	var escolhido := Estilo.rotulo("", 15, Estilo.TEXTO_APAGADO)
	escolhido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	escolhido.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	linha.add_child(escolhido)
	nomes[nome] = escolhido
	coluna.add_child(linha)


func paleta(coluna: VBoxContainer, nome: String, texto: String, cores: Array) -> void:
	secao(coluna, nome, texto)
	var grade := GridContainer.new()
	grade.columns = cores.size()
	grade.add_theme_constant_override("h_separation", 6)
	coluna.add_child(grade)
	var botoes := []
	for i in cores.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(36, 36)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.tooltip_text = cores[i][0]
		b.pressed.connect(func() -> void: escolher(nome, i))
		b.set_meta("cor", cores[i][1])
		grade.add_child(b)
		botoes.append(b)
	grupos[nome] = botoes


func lista(coluna: VBoxContainer, nome: String, texto: String, opcoes: Array, por_linha: int) -> void:
	secao(coluna, nome, texto)
	var grade := GridContainer.new()
	grade.columns = por_linha
	grade.add_theme_constant_override("h_separation", 6)
	grade.add_theme_constant_override("v_separation", 6)
	coluna.add_child(grade)
	var botoes := []
	for i in opcoes.size():
		var b := Estilo.botao(opcoes[i], func() -> void: escolher(nome, i), 40)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 17)
		grade.add_child(b)
		botoes.append(b)
	grupos[nome] = botoes


func escolher(nome: String, valor: int) -> void:
	escolha[nome] = valor
	carro.vestir(escolha)
	if nome == "modelo":
		get_parent().assentar_rodas()
	if nome == "fogo" or nome == "rastro":
		boost_ate = tempo + 2.5
	marcar()


func marcar() -> void:
	# o escolhido de cada grupo fica com borda branca (e o nome dele aparece do lado do título)
	for nome in grupos:
		var atual: int = (0 if time == "azul" else 1) if nome == "time" else escolha[nome]
		var botoes: Array = grupos[nome]
		for i in botoes.size():
			var b: Button = botoes[i]
			var marcado := i == atual
			if b.has_meta("cor"):
				var cor: Color = b.get_meta("cor")
				b.add_theme_stylebox_override("normal", Estilo.caixa(cor, Color.WHITE if marcado else Color(1, 1, 1, 0.15), 8, 3 if marcado else 1, 0))
				b.add_theme_stylebox_override("hover", Estilo.caixa(cor.lightened(0.15), Color.WHITE, 8, 3 if marcado else 2, 0))
				b.add_theme_stylebox_override("pressed", Estilo.caixa(cor, Color.WHITE, 8, 3, 0))
			elif marcado:
				b.add_theme_stylebox_override("normal", Estilo.caixa(Color(0.16, 0.3, 0.55, 0.95), Color.WHITE, 10, 2))
			else:
				b.remove_theme_stylebox_override("normal")
		if nome == "modelo":
			sobre_modelo.text = Aparencia.SOBRE_MODELOS[atual]
		if nomes.has(nome):
			match nome:
				"detalhe":
					nomes[nome].text = Aparencia.DETALHES[atual][0]
				"fogo":
					nomes[nome].text = Aparencia.FOGOS[atual][0]
				_:
					nomes[nome].text = ""


func pintar_time() -> void:
	carro.tinta.set_shader_parameter("cor", Color(0.2, 0.45, 0.95) if time == "azul" else Color(1.0, 0.5, 0.12))


func _process(delta: float) -> void:
	tempo += delta
	var boostando := tempo < boost_ate
	carro.rastro.emitting = boostando
	carro.turbina.set_shader_parameter("forca_brilho", 4.0 if boostando else 0.5)


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
