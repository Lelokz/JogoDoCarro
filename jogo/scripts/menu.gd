extends Control

# Menu inicial: treinar sozinho, hospedar uma partida ou entrar na de um amigo.
# No PC é pelo endereço; pelo terminal também dá: -- --hospedar  ou  -- --entrar=ENDEREÇO (usado nos testes).
# No navegador é por sala com código; o link site/?sala=ABCD já entra direto (e ?hospedar cria uma, pros testes).

const ULTIMO_ENDERECO := "user://ultimo_endereco.txt"

var endereco := LineEdit.new()
var codigo := LineEdit.new()
var aviso := Label.new()
var opcoes := VBoxContainer.new()
# Tela de carregamento: monta a arena escondida e mostra ela aos poucos (céu, coisas sólidas, vidro,
# rastro do boost, resto), um pedaço por quadro. A placa de vídeo compila os shaders de cada pedaço
# e a barra anda entre um e outro. Depois disso o "Treinar sozinho" abre na hora.
# (No navegador, compilar tudo de uma vez travava 10 a 20 s na primeira vez.)
const ETAPAS := ["Carregando a arena", "Preparando o céu", "Preparando o chão e os carros", "Preparando o vidro", "Preparando o boost", "Preparando o resto", "Pronto"]
var carregando := VBoxContainer.new()
var barra := ProgressBar.new()
var etapa_texto := Label.new()
var janela_escondida: SubViewport
var etapa := -1
var quadro := 0


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

	etapa_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etapa_texto.add_theme_color_override("font_color", Color(0.6, 0.63, 0.7))
	barra.custom_minimum_size.y = 26
	barra.max_value = ETAPAS.size() - 1
	var primeira_vez := Label.new()
	primeira_vez.text = "(na primeira vez demora mais; depois o navegador lembra)"
	primeira_vez.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	primeira_vez.add_theme_font_size_override("font_size", 13)
	primeira_vez.add_theme_color_override("font_color", Color(0.45, 0.48, 0.55))
	carregando.add_child(etapa_texto)
	carregando.add_child(barra)
	carregando.add_child(primeira_vez)
	caixa.add_child(carregando)
	opcoes.add_theme_constant_override("separation", 12)
	caixa.add_child(opcoes)
	var ja_carregou := Rede.cena_arena != null
	carregando.visible = not ja_carregou
	opcoes.visible = ja_carregou
	if not ja_carregou:
		etapa_texto.text = ETAPAS[0] + "…"
	caixa = opcoes

	caixa.add_child(botao("Treinar sozinho", func() -> void: Rede.treinar()))
	caixa.add_child(botao("Campo de teste", func() -> void: Rede.treinar("res://cenas/campo_teste.tscn")))
	caixa.add_child(HSeparator.new())
	if OS.has_feature("web"):
		caixa.add_child(botao("Criar sala (jogar com amigos)", criar_sala))
		var linha_sala := HBoxContainer.new()
		codigo.placeholder_text = "código da sala (ex.: KXPB)"
		codigo.max_length = 4
		codigo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		codigo.custom_minimum_size.y = 40
		codigo.text_submitted.connect(func(_texto: String) -> void: entrar_na_sala())
		linha_sala.add_child(codigo)
		linha_sala.add_child(botao("Entrar na sala", entrar_na_sala))
		caixa.add_child(linha_sala)
		montar_aviso(caixa)
		if ja_carregou:
			pedidos_iniciais()
		return
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
	montar_aviso(caixa)
	if FileAccess.file_exists(ULTIMO_ENDERECO):
		endereco.text = FileAccess.get_file_as_string(ULTIMO_ENDERECO).strip_edges()
	if ja_carregou:
		pedidos_iniciais()


func pedidos_iniciais() -> void:
	# o que veio no terminal ou no link: só na primeira vez que o menu aparece
	# (senão, voltando pro menu com ESC, entrava de novo na hora)
	if Rede.leu_linha_de_comando:
		return
	Rede.leu_linha_de_comando = true
	if OS.has_feature("web"):
		var busca := str(JavaScriptBridge.eval("location.search"))
		print("[sala] link: ", busca)
		for pedaco in busca.trim_prefix("?").split("&", false):
			if pedaco.begins_with("sala="):
				codigo.text = pedaco.trim_prefix("sala=").uri_decode()
				entrar_na_sala()
			elif pedaco == "hospedar":
				criar_sala()
		return
	for argumento in OS.get_cmdline_user_args():
		if argumento == "--hospedar":
			hospedar.call_deferred()
		elif argumento.begins_with("--entrar="):
			endereco.text = argumento.trim_prefix("--entrar=")
			entrar.call_deferred()


func _process(_delta: float) -> void:
	if not carregando.visible:
		return
	# dois quadros leves entre uma etapa pesada e outra: senão o navegador não mostra a barra andando
	quadro += 1
	if quadro % 3 != 0:
		return
	etapa += 1
	match etapa:
		0:
			Rede.cena_arena = load("res://cenas/arena.tscn")
			janela_escondida = SubViewport.new()
			janela_escondida.size = Vector2i(64, 64)
			janela_escondida.own_world_3d = true
			janela_escondida.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			add_child(janela_escondida)
			janela_escondida.add_child(Rede.cena_arena.instantiate())
			mostrar_pedaco(func(_no: Node) -> bool: return false)
		1:
			mostrar_pedaco(func(no: Node) -> bool: return usa_shader(no, Materiais.SOLIDO))
		2:
			mostrar_pedaco(func(no: Node) -> bool: return usa_shader(no, Materiais.TRANSPARENTE))
		3:
			janela_escondida.get_child(0).get_node("Carro").boostando = true
			mostrar_pedaco(func(no: Node) -> bool: return no is CPUParticles3D)
		4:
			mostrar_pedaco(func(_no: Node) -> bool: return true)
			for camada in janela_escondida.find_children("*", "CanvasLayer", true, false):
				camada.visible = true
		_:
			janela_escondida.queue_free()
			janela_escondida = null
			carregando.visible = false
			opcoes.visible = true
			print("[menu] pronto em %.1f s" % (Time.get_ticks_msec() / 1000.0))
			pedidos_iniciais()
			return
	barra.value = etapa + 1
	etapa_texto.text = ETAPAS[etapa + 1] + "…"


func mostrar_pedaco(mostrar: Callable) -> void:
	# deixa visível só o que já foi preparado + o pedaço novo
	for no in janela_escondida.find_children("*", "GeometryInstance3D", true, false):
		no.visible = no.visible or mostrar.call(no)
		if etapa == 0:
			no.visible = false
	if etapa == 0:
		for camada in janela_escondida.find_children("*", "CanvasLayer", true, false):
			camada.visible = false


func usa_shader(no: Node, shader: Shader) -> bool:
	var materiais: Array = [no.material_override if no is GeometryInstance3D else null]
	if no is MeshInstance3D and no.mesh:
		# os modelos montados por código têm um material em cada pedaço
		for i in no.mesh.get_surface_count():
			materiais.append(no.mesh.surface_get_material(i))
	for material in materiais:
		if material is ShaderMaterial and material.shader == shader:
			return true
	return false


func montar_aviso(caixa: VBoxContainer) -> void:
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.add_theme_color_override("font_color", Color(1.0, 0.75, 0.4))
	caixa.add_child(aviso)
	aviso.text = Rede.aviso
	Rede.aviso = ""


func botao(texto: String, ao_clicar: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size.y = 44
	b.pressed.connect(ao_clicar)
	return b


func hospedar() -> void:
	if Rede.hospedar() != OK:
		aviso.text = "Não deu pra hospedar: a porta %d já está em uso (o jogo já está aberto hospedando?)." % Rede.PORTA


func criar_sala() -> void:
	aviso.text = "Criando a sala…"
	Rede.criar_sala()


func entrar_na_sala() -> void:
	var qual := codigo.text.strip_edges().to_upper()
	if qual.length() != 4:
		aviso.text = "O código da sala tem 4 letras (aparece na tela de quem criou a sala)."
		return
	codigo.text = qual
	aviso.text = "Entrando na sala %s…" % qual
	Rede.entrar_na_sala(qual)


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
