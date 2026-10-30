extends Node

# Teclado e controle. Os botões do controle seguem o padrão Xbox.

func _ready() -> void:
	adicionar("acelerar", [KEY_W, KEY_UP], [], [[JOY_AXIS_TRIGGER_RIGHT, 1.0]])
	adicionar("re", [KEY_S, KEY_DOWN], [], [[JOY_AXIS_TRIGGER_LEFT, 1.0]])
	adicionar("esquerda", [KEY_A, KEY_LEFT], [], [[JOY_AXIS_LEFT_X, -1.0]])
	adicionar("direita", [KEY_D, KEY_RIGHT], [], [[JOY_AXIS_LEFT_X, 1.0]])
	adicionar("freio_mao", [KEY_SHIFT], [JOY_BUTTON_X], [])
	adicionar("pulo", [KEY_SPACE], [JOY_BUTTON_A], [], [MOUSE_BUTTON_RIGHT])
	adicionar("boost", [KEY_CTRL], [JOY_BUTTON_B], [], [MOUSE_BUTTON_LEFT])
	# no ar: W/S e o analógico pra cima/baixo inclinam o nariz
	adicionar("nariz_baixo", [KEY_W, KEY_UP], [], [[JOY_AXIS_LEFT_Y, -1.0]])
	adicionar("nariz_cima", [KEY_S, KEY_DOWN], [], [[JOY_AXIS_LEFT_Y, 1.0]])
	adicionar("rolar_esquerda", [KEY_Q], [JOY_BUTTON_LEFT_SHOULDER], [])
	adicionar("rolar_direita", [KEY_E], [JOY_BUTTON_RIGHT_SHOULDER], [])
	adicionar("desvirar", [KEY_R], [JOY_BUTTON_BACK], [])
	adicionar("voltar_inicio", [KEY_T], [], [])
	adicionar("tela_cheia", [KEY_F11], [], [])
	adicionar("painel", [KEY_F1], [], [])


func adicionar(nome: String, teclas: Array, botoes: Array, eixos: Array, mouse: Array = []) -> void:
	if not InputMap.has_action(nome):
		InputMap.add_action(nome, 0.15)
	for tecla in teclas:
		var evento := InputEventKey.new()
		evento.physical_keycode = tecla
		InputMap.action_add_event(nome, evento)
	for botao in botoes:
		var evento := InputEventJoypadButton.new()
		evento.button_index = botao
		InputMap.action_add_event(nome, evento)
	for eixo in eixos:
		var evento := InputEventJoypadMotion.new()
		evento.axis = eixo[0]
		evento.axis_value = eixo[1]
		InputMap.action_add_event(nome, evento)
	for botao in mouse:
		var evento := InputEventMouseButton.new()
		evento.button_index = botao
		InputMap.action_add_event(nome, evento)


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("tela_cheia"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
