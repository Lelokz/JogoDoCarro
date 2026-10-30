extends Node

# Teclado e controle. Os botões do controle seguem o padrão Xbox.

func _ready() -> void:
	adicionar("acelerar", [KEY_W, KEY_UP], [], [[JOY_AXIS_TRIGGER_RIGHT, 1.0]])
	adicionar("re", [KEY_S, KEY_DOWN], [], [[JOY_AXIS_TRIGGER_LEFT, 1.0]])
	adicionar("esquerda", [KEY_A, KEY_LEFT], [], [[JOY_AXIS_LEFT_X, -1.0]])
	adicionar("direita", [KEY_D, KEY_RIGHT], [], [[JOY_AXIS_LEFT_X, 1.0]])
	adicionar("freio_mao", [KEY_SHIFT], [JOY_BUTTON_X], [])
	adicionar("desvirar", [KEY_R], [JOY_BUTTON_BACK], [])
	adicionar("voltar_inicio", [KEY_T], [], [])
	adicionar("tela_cheia", [KEY_F11], [], [])


func adicionar(nome: String, teclas: Array, botoes: Array, eixos: Array) -> void:
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


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("tela_cheia"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
