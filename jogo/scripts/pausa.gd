class_name Pausa
extends CanvasLayer

# Telinha do ESC na partida: continuar, opções ou voltar pro menu.
# Sozinho o jogo para; online não dá pra parar a partida dos outros, então ela segue por trás
# (e o teu carro fica solto enquanto a telinha está aberta).

var caixa: Control


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	Controles.pausado = true
	if not Rede.online():
		get_tree().paused = true
	caixa = Control.new()
	caixa.set_anchors_preset(Control.PRESET_FULL_RECT)
	caixa.theme = Estilo.tema()
	add_child(caixa)
	caixa.add_child(Estilo.fundo_escuro(0.5))
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	caixa.add_child(centro)
	var painel := PanelContainer.new()
	painel.custom_minimum_size.x = 440
	centro.add_child(painel)
	var lista := VBoxContainer.new()
	lista.add_theme_constant_override("separation", 12)
	painel.add_child(lista)
	var titulo := Estilo.rotulo("PAUSA" if not Rede.online() else "MENU", 44, Estilo.TEXTO, Estilo.titulo())
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lista.add_child(titulo)
	if Rede.online():
		var aviso := Estilo.rotulo("a partida continua rolando por trás", 16, Estilo.TEXTO_APAGADO)
		aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lista.add_child(aviso)
	lista.add_child(HSeparator.new())
	var continuar := Estilo.botao("Continuar jogando", fechar)
	lista.add_child(continuar)
	lista.add_child(Estilo.botao("Opções", abrir_opcoes))
	lista.add_child(Estilo.botao("Sair da sala" if Rede.online() else "Voltar pro menu", func() -> void:
		fechar()
		Rede.sair()))
	continuar.grab_focus.call_deferred()


func abrir_opcoes() -> void:
	var opcoes := TelaOpcoes.new()
	caixa.visible = false
	opcoes.fechou.connect(func() -> void:
		caixa.visible = true
		caixa.find_children("*", "Button", true, false)[0].grab_focus())
	add_child(opcoes)


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("menu") and caixa.visible:
		get_viewport().set_input_as_handled()
		fechar()


func fechar() -> void:
	Controles.pausado = false
	get_tree().paused = false
	queue_free()
