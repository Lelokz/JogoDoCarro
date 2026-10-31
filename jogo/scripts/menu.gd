extends Control

# Menu inicial: JOGAR, opções e sair. O JOGAR abre criar sala / entrar na de um amigo, jogar solo
# e o campo de treinamento; ESC ou VOLTAR voltam uma tela.
# No PC é pelo endereço; pelo terminal também dá: -- --hospedar  ou  -- --entrar=ENDEREÇO (usado nos testes).
# No navegador é por sala com código; o link site/?sala=ABCD já entra direto (e ?hospedar cria uma, pros testes).
#
# Tela de carregamento: monta a arena escondida e mostra ela aos poucos (céu, coisas sólidas, vidro,
# rastro do boost, resto), um pedaço por quadro. A placa de vídeo compila os shaders de cada pedaço
# e a barra anda entre um e outro. (No navegador, compilar tudo de uma vez travava 10 a 20 s.)
# Quando termina, essa mesma arena vira o fundo do menu: o carro girando no meio do campo.

const ULTIMO_ENDERECO := "user://ultimo_endereco.txt"
const ETAPAS := ["Carregando a arena", "Preparando o céu", "Preparando o chão e os carros", "Preparando o vidro", "Preparando o boost", "Preparando o resto", "Pronto"]
const AZUL := Color(0.2, 0.45, 0.95)
const LARANJA := Color(1.0, 0.5, 0.12)
const ONDE_CARRO := Vector3(0.0, 0.0, 3.0)
const CAMERA := Vector3(1.0, 0.85, 6.1)
const OLHAR := Vector3(-1.05, 0.42, 2.7)

var endereco := LineEdit.new()
var codigo := LineEdit.new()
var aviso := Label.new()
var inicio := VBoxContainer.new()         # JOGAR, opções, sair
var pagina_jogar := VBoxContainer.new()   # depois do JOGAR: sala, solo, campo de treinamento
var escolha_solo := VBoxContainer.new()   # depois do JOGAR SOLO: treino livre ou contra o bot
var linha_entrar := HBoxContainer.new()   # campo do código (ou endereço) + ENTRAR, aparece no ENTRAR NA SALA
var lado := Control.new()          # título + botões (aparece no fim do carregamento)
var carregando := VBoxContainer.new()
var barra := ProgressBar.new()
var etapa_texto := Label.new()
var fundo := ColorRect.new()
var vitrine := SubViewportContainer.new()
var janela := SubViewport.new()    # a arena de fundo
var arena: Node3D
var carro: Node3D
var altura_carro := 0.32
var etapa := -1
var quadro := 0
var tempo := 0.0
var aparecendo := -1.0             # de 0 a 1 quando o menu aparece (o fundo escuro some)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = Estilo.tema()
	vitrine.stretch = true
	vitrine.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vitrine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	janela.own_world_3d = true
	janela.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	janela.msaa_3d = Viewport.MSAA_2X
	vitrine.add_child(janela)
	add_child(vitrine)
	fundo.color = Color(0.05, 0.06, 0.09)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
	montar_carregamento()
	montar_lado()

	if Rede.cena_arena != null:
		# já carregou antes (voltou da partida): monta o fundo direto
		arena = Rede.cena_arena.instantiate()
		janela.add_child(arena)
		virar_vitrine()
		mostrar_menu(true)
	else:
		lado.visible = false
		etapa_texto.text = ETAPAS[0] + "…"


func montar_carregamento() -> void:
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	carregando.custom_minimum_size.x = 520
	carregando.add_theme_constant_override("separation", 10)
	centro.add_child(carregando)
	var titulo := Estilo.rotulo("FUTEBOL DE CARRO", 54, Estilo.TEXTO, Estilo.titulo())
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	carregando.add_child(titulo)
	etapa_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etapa_texto.add_theme_color_override("font_color", Estilo.TEXTO_APAGADO)
	carregando.add_child(etapa_texto)
	barra.custom_minimum_size.y = 22
	barra.max_value = ETAPAS.size() - 1
	barra.show_percentage = false
	carregando.add_child(barra)
	var primeira_vez := Estilo.rotulo("(na primeira vez demora mais; depois o navegador lembra)", 14, Color(0.45, 0.48, 0.55))
	primeira_vez.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	carregando.add_child(primeira_vez)


func montar_lado() -> void:
	lado.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lado.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lado)
	# sombra da esquerda pra direita, pra ler os botões em cima do estádio
	var gradiente := Gradient.new()
	gradiente.set_color(0, Color(0.02, 0.03, 0.07, 0.94))
	gradiente.set_color(1, Color(0.02, 0.03, 0.07, 0.0))
	gradiente.add_point(0.55, Color(0.02, 0.03, 0.07, 0.75))
	var textura := GradientTexture2D.new()
	textura.gradient = gradiente
	textura.width = 256
	textura.height = 4
	var sombra := TextureRect.new()
	sombra.texture = textura
	sombra.stretch_mode = TextureRect.STRETCH_SCALE
	sombra.anchor_right = 0.62
	sombra.anchor_bottom = 1.0
	sombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lado.add_child(sombra)

	var coluna := VBoxContainer.new()
	# preso em cima: o título fica no mesmo lugar quando troca de tela (só os botões mudam)
	coluna.anchor_top = 0.11
	coluna.anchor_bottom = 1.0
	coluna.offset_left = 70
	coluna.offset_right = 70 + 420
	coluna.add_theme_constant_override("separation", 0)
	lado.add_child(coluna)
	coluna.add_child(Estilo.rotulo("FUTEBOL", 66, Estilo.TEXTO, Estilo.titulo()))
	var de_carro := Estilo.rotulo("DE CARRO", 66, Estilo.LARANJA, Estilo.titulo())
	de_carro.add_theme_constant_override("line_spacing", -20)
	coluna.add_child(de_carro)
	coluna.add_child(Estilo.rotulo("protótipo · nome provisório", 16, Estilo.TEXTO_APAGADO))
	var espaco := Control.new()
	espaco.custom_minimum_size.y = 22
	coluna.add_child(espaco)
	for pagina in [inicio, pagina_jogar, escolha_solo]:
		pagina.add_theme_constant_override("separation", 10)
		coluna.add_child(pagina)

	# tela inicial: só o JOGAR grande, opções e sair
	inicio.add_child(botao_grande("JOGAR", func() -> void: mostrar(pagina_jogar)))
	inicio.add_child(botao("OPÇÕES", func() -> void: add_child(TelaOpcoes.new())))
	if not OS.has_feature("web"):
		inicio.add_child(botao("SAIR DO JOGO", func() -> void: get_tree().quit()))

	# depois do JOGAR: sala, solo e campo de treinamento
	pagina_jogar.add_child(Estilo.rotulo("JOGAR", 20, Estilo.LARANJA, Estilo.titulo()))
	linha_entrar.visible = false
	linha_entrar.add_theme_constant_override("separation", 8)
	if OS.has_feature("web"):
		pagina_jogar.add_child(botao("CRIAR SALA", criar_sala))
		pagina_jogar.add_child(botao("ENTRAR NA SALA", func() -> void: abrir_entrar(codigo)))
		codigo.placeholder_text = "código da sala"
		codigo.max_length = 4
		codigo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		codigo.text_submitted.connect(func(_texto: String) -> void: entrar_na_sala())
		linha_entrar.add_child(codigo)
		var entrar_sala := botao("ENTRAR", entrar_na_sala)
		entrar_sala.custom_minimum_size.x = 130
		linha_entrar.add_child(entrar_sala)
	else:
		pagina_jogar.add_child(botao("HOSPEDAR PARTIDA", hospedar))
		pagina_jogar.add_child(botao("ENTRAR NA PARTIDA", func() -> void: abrir_entrar(endereco)))
		endereco.placeholder_text = "endereço do host"
		endereco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		endereco.text_submitted.connect(func(_texto: String) -> void: entrar())
		linha_entrar.add_child(endereco)
		var entrar_host := botao("ENTRAR", entrar)
		entrar_host.custom_minimum_size.x = 130
		linha_entrar.add_child(entrar_host)
		if FileAccess.file_exists(ULTIMO_ENDERECO):
			endereco.text = FileAccess.get_file_as_string(ULTIMO_ENDERECO).strip_edges()
	codigo.custom_minimum_size.y = 52
	endereco.custom_minimum_size.y = 52
	pagina_jogar.add_child(linha_entrar)
	pagina_jogar.add_child(botao("JOGAR SOLO", func() -> void: mostrar(escolha_solo)))
	pagina_jogar.add_child(botao("CAMPO DE TREINAMENTO", func() -> void: Rede.treinar("res://cenas/campo_teste.tscn")))
	pagina_jogar.add_child(botao("VOLTAR", voltar))
	montar_escolha_solo()

	var espaco_aviso := Control.new()
	espaco_aviso.custom_minimum_size.y = 10
	coluna.add_child(espaco_aviso)
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aviso.add_theme_color_override("font_color", Color(1.0, 0.75, 0.4))
	aviso.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	aviso.add_theme_constant_override("outline_size", 5)
	coluna.add_child(aviso)
	aviso.text = Rede.aviso
	Rede.aviso = ""
	mostrar(inicio)


func montar_escolha_solo() -> void:
	escolha_solo.add_child(Estilo.rotulo("CONTRA O BOT", 20, Estilo.LARANJA, Estilo.titulo()))
	var niveis := HBoxContainer.new()
	niveis.add_theme_constant_override("separation", 8)
	for i in Bot.NIVEIS.size():
		var b := botao(Bot.NIVEIS[i].to_upper(), func() -> void: Rede.treinar("res://cenas/arena.tscn", i))
		b.alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		niveis.add_child(b)
	escolha_solo.add_child(niveis)
	var dica := Estilo.rotulo("1 contra 1, o bot no laranja", 15, Estilo.TEXTO_APAGADO)
	escolha_solo.add_child(dica)
	var espaco := Control.new()
	espaco.custom_minimum_size.y = 6
	escolha_solo.add_child(espaco)
	escolha_solo.add_child(botao("TREINO LIVRE (sem adversário)", func() -> void: Rede.treinar()))
	escolha_solo.add_child(botao("VOLTAR", voltar))


func mostrar(pagina: VBoxContainer) -> void:
	for outra in [inicio, pagina_jogar, escolha_solo]:
		outra.visible = outra == pagina
	linha_entrar.visible = false
	# foco no primeiro botão, pra dar pra jogar no controle
	for filho in pagina.find_children("*", "Button", true, false):
		filho.grab_focus.call_deferred()
		break


func voltar() -> void:
	aviso.text = ""
	mostrar(pagina_jogar if escolha_solo.visible else inicio)


func abrir_entrar(campo: LineEdit) -> void:
	linha_entrar.visible = not linha_entrar.visible
	if linha_entrar.visible:
		campo.grab_focus.call_deferred()


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("menu") and lado.visible and not inicio.visible:
		get_viewport().set_input_as_handled()
		voltar()


func botao_grande(texto: String, ao_clicar: Callable) -> Button:
	var b := botao(texto, ao_clicar)
	b.add_theme_stylebox_override("normal", Estilo.caixa(Color(0.95, 0.45, 0.1, 0.95), Color(1, 0.8, 0.5, 0.6), 10, 1, 22))
	b.add_theme_stylebox_override("hover", Estilo.caixa(Color(1.0, 0.58, 0.2, 1.0), Color.WHITE, 10, 2, 22))
	b.add_theme_stylebox_override("pressed", Estilo.caixa(Color(0.85, 0.38, 0.08, 1.0), Color.WHITE, 10, 2, 22))
	b.custom_minimum_size.y = 72
	b.add_theme_font_override("font", Estilo.titulo())
	b.add_theme_font_size_override("font_size", 34)
	return b


func botao(texto: String, ao_clicar: Callable) -> Button:
	var b := Estilo.botao(texto, ao_clicar, 52)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_override("font", Estilo.titulo())
	b.add_theme_font_size_override("font_size", 22)
	return b


func _process(delta: float) -> void:
	tempo += delta
	if aparecendo >= 0.0 and aparecendo < 1.0:
		aparecendo = minf(aparecendo + delta * 1.5, 1.0)
		fundo.modulate.a = 1.0 - aparecendo
		lado.modulate.a = aparecendo
	girar_carro()
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
			arena = Rede.cena_arena.instantiate()
			janela.add_child(arena)
			mostrar_pedaco(func(_no: Node) -> bool: return false)
		1:
			mostrar_pedaco(func(no: Node) -> bool: return usa_shader(no, Materiais.SOLIDO))
		2:
			mostrar_pedaco(func(no: Node) -> bool: return usa_shader(no, Materiais.TRANSPARENTE))
		3:
			arena.get_node("Carro").boostando = true
			mostrar_pedaco(func(no: Node) -> bool: return no is CPUParticles3D)
		4:
			mostrar_pedaco(func(_no: Node) -> bool: return true)
			for camada in arena.find_children("*", "CanvasLayer", true, false):
				camada.visible = true
		_:
			virar_vitrine()
			mostrar_menu(false)
			print("[menu] pronto em %.1f s" % (Time.get_ticks_msec() / 1000.0))
			return
	barra.value = etapa + 1
	etapa_texto.text = ETAPAS[etapa + 1] + "…"


func mostrar_menu(na_hora: bool) -> void:
	carregando.visible = false
	lado.visible = true
	aparecendo = 1.0 if na_hora else 0.0
	fundo.modulate.a = 0.0 if na_hora else 1.0
	lado.modulate.a = 1.0 if na_hora else 0.0
	pedidos_iniciais()


func virar_vitrine() -> void:
	# a arena do carregamento vira enfeite: sem partida, sem HUD, carro e bola parados
	for nome in ["Partida", "Hud", "Painel", "Camera"]:
		var no := arena.get_node_or_null(nome)
		if no:
			no.process_mode = Node.PROCESS_MODE_DISABLED
			if no is CanvasLayer:
				no.visible = false
	for camada in arena.find_children("*", "CanvasLayer", true, false):
		camada.visible = false
	carro = arena.get_node("Carro")
	carro.boostando = false
	carro.rastro.emitting = false
	carro.process_mode = Node.PROCESS_MODE_DISABLED
	altura_carro = carro.global_position.y if carro.global_position.y > 0.2 else 0.32
	var bola: Node3D = arena.get_node("Bola")
	bola.process_mode = Node.PROCESS_MODE_DISABLED
	bola.global_position = ONDE_CARRO + Vector3(0.6, 0.9125, -5.0)
	var camera: Camera3D = arena.get_node("Camera")
	camera.fov = 55.0
	camera.global_position = CAMERA
	camera.look_at(OLHAR)
	camera.make_current()
	girar_carro()


func girar_carro() -> void:
	if carro == null or not is_instance_valid(carro) or carro.process_mode != Node.PROCESS_MODE_DISABLED:
		return
	carro.global_transform = Transform3D(Basis(Vector3.UP, tempo * 0.4 + 2.2), ONDE_CARRO + Vector3.UP * altura_carro)
	# a pintura vai do azul pro laranja e volta
	var mistura := smoothstep(0.35, 0.65, 0.5 + 0.5 * sin(tempo * 0.5))
	carro.tinta.set_shader_parameter("cor", AZUL.lerp(LARANJA, mistura))
	var camera: Camera3D = arena.get_node("Camera")
	camera.global_position = CAMERA + Vector3(sin(tempo * 0.15) * 0.25, sin(tempo * 0.21) * 0.06, 0.0)
	camera.look_at(OLHAR)


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


func mostrar_pedaco(mostrar: Callable) -> void:
	# deixa visível só o que já foi preparado + o pedaço novo
	for no in arena.find_children("*", "GeometryInstance3D", true, false):
		no.visible = no.visible or mostrar.call(no)
		if etapa == 0:
			no.visible = false
	if etapa == 0:
		for camada in arena.find_children("*", "CanvasLayer", true, false):
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
