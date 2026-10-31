class_name TelaOpcoes
extends Control

# Tela de opções: a mesma no menu e na pausa da partida. Câmera, gráficos e a lista de controles.
# Cada mudança vale na hora e fica salva (Opcoes).

signal fechou

const CONTROLES := [
	["Acelerar / ré", "W / S", "RT / LT"],
	["Virar", "A / D", "analógico"],
	["Pular (2× = pulo duplo, com direção = mortal)", "Espaço ou botão direito", "A"],
	["Boost", "botão esquerdo ou F", "B"],
	["Freio de mão (no ar: rolar)", "Shift", "X"],
	["No ar: inclinar / rolar", "W / S · Q / E", "analógico · LB / RB"],
	["Câmera da bola", "C", "Y"],
	["Pausa", "ESC", "Start"],
	["Copiar link da sala", "L", ""],
	["Tela cheia", "F11", ""],
	["Treino: desvirar · início · bola na frente", "R · T · G", ""],
	["Treino: arena / campo de teste", "F2", ""],
	["Ajustes da física (só o host)", "F1", ""],
]

var deslizadores := {}
var botoes_qualidade := []
var fps := CheckButton.new()
var tela_cheia := CheckButton.new()
var voltar: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = Estilo.tema()
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(Estilo.fundo_escuro(0.6))
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var painel := PanelContainer.new()
	painel.custom_minimum_size = Vector2(1120, 0)
	centro.add_child(painel)
	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 14)
	painel.add_child(caixa)
	caixa.add_child(Estilo.rotulo("OPÇÕES", 42, Estilo.TEXTO, Estilo.titulo()))

	var colunas := HBoxContainer.new()
	colunas.add_theme_constant_override("separation", 40)
	caixa.add_child(colunas)
	var esquerda := VBoxContainer.new()
	esquerda.custom_minimum_size.x = 470
	esquerda.add_theme_constant_override("separation", 10)
	colunas.add_child(esquerda)
	var direita := VBoxContainer.new()
	direita.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	direita.add_theme_constant_override("separation", 6)
	colunas.add_child(direita)

	esquerda.add_child(secao("CÂMERA"))
	esquerda.add_child(linha_deslizante("fov", "Campo de visão", 70, 120, 1, "%d°"))
	esquerda.add_child(linha_deslizante("distancia", "Distância", 1.5, 5.0, 0.1, "%.1f m"))
	esquerda.add_child(linha_deslizante("altura", "Altura", 0.5, 2.5, 0.05, "%.2f m"))
	esquerda.add_child(secao("GRÁFICOS"))
	var qualidade := HBoxContainer.new()
	qualidade.add_theme_constant_override("separation", 8)
	var grupo := ButtonGroup.new()
	for i in Opcoes.QUALIDADES.size():
		var b := Estilo.botao(Opcoes.QUALIDADES[i], func() -> void: Opcoes.definir("graficos", i), 44)
		b.toggle_mode = true
		b.button_group = grupo
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		qualidade.add_child(b)
		botoes_qualidade.append(b)
	esquerda.add_child(qualidade)
	esquerda.add_child(Estilo.rotulo("Baixo: sem sombra, sem brilho e resolução menor (PC fraco).", 15, Estilo.TEXTO_APAGADO))
	fps.text = "Mostrar FPS"
	fps.toggled.connect(func(ligado: bool) -> void: Opcoes.definir("mostrar_fps", ligado))
	esquerda.add_child(fps)
	tela_cheia.text = "Tela cheia"
	tela_cheia.toggled.connect(func(ligado: bool) -> void: Opcoes.definir("tela_cheia", ligado))
	esquerda.add_child(tela_cheia)

	direita.add_child(secao("CONTROLES"))
	var grade := GridContainer.new()
	grade.columns = 3
	grade.add_theme_constant_override("h_separation", 18)
	grade.add_theme_constant_override("v_separation", 5)
	for titulo in [["", "Teclado e mouse", "Controle"]] + CONTROLES:
		for i in 3:
			var cor := Estilo.TEXTO if i == 0 else Estilo.AZUL.lerp(Color.WHITE, 0.45)
			if titulo[0] == "":
				cor = Estilo.TEXTO_APAGADO
			var l := Estilo.rotulo(titulo[i], 15, cor)
			if i == 0:
				l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				l.custom_minimum_size.x = 250
			grade.add_child(l)
	direita.add_child(grade)

	var rodape := HBoxContainer.new()
	rodape.add_theme_constant_override("separation", 12)
	var padrao := Estilo.botao("Voltar ao padrão", func() -> void: Opcoes.voltar_ao_padrao(); atualizar(), 48)
	padrao.custom_minimum_size.x = 240
	rodape.add_child(padrao)
	var espaco := Control.new()
	espaco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rodape.add_child(espaco)
	voltar = Estilo.botao("Voltar", fechar, 48)
	voltar.custom_minimum_size.x = 240
	rodape.add_child(voltar)
	caixa.add_child(rodape)
	atualizar()
	voltar.grab_focus.call_deferred()


func secao(texto: String) -> Label:
	return Estilo.rotulo(texto, 17, Estilo.AZUL.lerp(Color.WHITE, 0.2))


func linha_deslizante(nome: String, texto: String, minimo: float, maximo: float, passo: float, formato: String) -> HBoxContainer:
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 14)
	var rotulo := Estilo.rotulo(texto, 19)
	rotulo.custom_minimum_size.x = 160
	linha.add_child(rotulo)
	var barra := HSlider.new()
	barra.min_value = minimo
	barra.max_value = maximo
	barra.step = passo
	barra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	barra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	barra.custom_minimum_size.y = 24
	linha.add_child(barra)
	var valor := Estilo.rotulo("", 19)
	valor.custom_minimum_size.x = 76
	valor.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	linha.add_child(valor)
	barra.value_changed.connect(func(v: float) -> void:
		valor.text = formato % v
		if not is_equal_approx(Opcoes.pegar(nome), v):
			Opcoes.definir(nome, v))
	deslizadores[nome] = barra
	return linha


func atualizar() -> void:
	# mostra o que está salvo (sem disparar mudança de novo)
	for nome in deslizadores:
		deslizadores[nome].set_value_no_signal(Opcoes.pegar(nome))
		deslizadores[nome].value_changed.emit(Opcoes.pegar(nome))
	botoes_qualidade[Opcoes.pegar("graficos")].set_pressed_no_signal(true)
	fps.set_pressed_no_signal(Opcoes.pegar("mostrar_fps"))
	tela_cheia.set_pressed_no_signal(Opcoes.tela_cheia_agora())


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("menu"):
		get_viewport().set_input_as_handled()
		fechar()


func fechar() -> void:
	fechou.emit()
	queue_free()
