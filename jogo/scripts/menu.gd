extends Control

# Menu inicial: treinar sozinho, hospedar uma partida ou entrar na de um amigo.
# Pelo terminal também dá: -- --hospedar  ou  -- --entrar=ENDEREÇO (usado nos testes).

const ULTIMO_ENDERECO := "user://ultimo_endereco.txt"

var endereco := LineEdit.new()
var aviso := Label.new()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var fundo := ColorRect.new()
	fundo.color = Color(0.07, 0.08, 0.11)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var caixa := VBoxContainer.new()
	caixa.custom_minimum_size.x = 460
	caixa.add_theme_constant_override("separation", 12)
	centro.add_child(caixa)

	var titulo := Label.new()
	titulo.text = "FUTEBOL DE CARRO"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 46)
	caixa.add_child(titulo)
	var subtitulo := Label.new()
	subtitulo.text = "protótipo · nome provisório"
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitulo.add_theme_color_override("font_color", Color(0.6, 0.63, 0.7))
	caixa.add_child(subtitulo)
	caixa.add_child(HSeparator.new())

	caixa.add_child(botao("Treinar sozinho", func() -> void: Rede.treinar()))
	caixa.add_child(botao("Campo de teste", func() -> void: Rede.treinar("res://cenas/campo_teste.tscn")))
	caixa.add_child(HSeparator.new())
	caixa.add_child(botao("Hospedar partida", hospedar))
	var linha := HBoxContainer.new()
	endereco.placeholder_text = "endereço do host (ex.: 192.168.0.10)"
	endereco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	endereco.custom_minimum_size.y = 40
	endereco.text_submitted.connect(func(_texto: String) -> void: entrar())
	linha.add_child(endereco)
	linha.add_child(botao("Entrar", entrar))
	caixa.add_child(linha)
	caixa.add_child(HSeparator.new())
	caixa.add_child(botao("Sair do jogo", func() -> void: get_tree().quit()))

	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.add_theme_color_override("font_color", Color(1.0, 0.75, 0.4))
	caixa.add_child(aviso)
	aviso.text = Rede.aviso
	Rede.aviso = ""
	if FileAccess.file_exists(ULTIMO_ENDERECO):
		endereco.text = FileAccess.get_file_as_string(ULTIMO_ENDERECO).strip_edges()

	for argumento in OS.get_cmdline_user_args():
		if argumento == "--hospedar":
			hospedar.call_deferred()
		elif argumento.begins_with("--entrar="):
			endereco.text = argumento.trim_prefix("--entrar=")
			entrar.call_deferred()


func botao(texto: String, ao_clicar: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size.y = 44
	b.pressed.connect(ao_clicar)
	return b


func hospedar() -> void:
	if Rede.hospedar() != OK:
		aviso.text = "Não deu pra hospedar: a porta %d já está em uso (o jogo já está aberto hospedando?)." % Rede.PORTA


func entrar() -> void:
	var onde := endereco.text.strip_edges()
	if onde == "":
		aviso.text = "Digita o endereço do host (ele aparece embaixo na tela de quem hospeda)."
		return
	var arquivo := FileAccess.open(ULTIMO_ENDERECO, FileAccess.WRITE)
	if arquivo:
		arquivo.store_string(onde)
	if Rede.entrar(onde) != OK:
		aviso.text = "Endereço inválido: %s" % onde
		return
	aviso.text = "Conectando em %s… (se demorar, confere o endereço)" % onde
