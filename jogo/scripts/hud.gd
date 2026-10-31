extends CanvasLayer

# HUD da partida: placar em cima, velocímetro + boost embaixo à direita, código da sala no canto.
# Os textos "Placar" e "Mensagem" continuam existindo (a partida e os testes usam): o placar
# bonito é montado a partir do texto do "Placar", que fica escondido. Os números de teste
# (rodas no chão, velocidade da bola...) só aparecem com o painel F1 aberto.

@export var carro_caminho: NodePath
@export var bola_caminho: NodePath
@export var camera_caminho: NodePath

var carro: RigidBody3D
var bola: RigidBody3D
var camera: Camera3D
var painel: Node
var convite := ""
var convite_texto := Label.new()   # canto de cima, na tela de quem hospeda
var copiou := 0.0   # segundos mostrando "link copiado"
var velocimetro := Velocimetro.new()
var fps := Label.new()
var dica := Label.new()
var tempo := 0.0
# placar: [caixa azul, relógio, caixa laranja] + "tu: Laranja"
var placar_caixa := HBoxContainer.new()
var gols_azul := Label.new()
var gols_laranja := Label.new()
var relogio := Label.new()
var meu_time := Label.new()


func _ready() -> void:
	carro = get_node(carro_caminho)
	bola = get_node(bola_caminho)
	camera = get_node(camera_caminho)
	painel = get_node_or_null("../Painel")
	$Boost.visible = false
	$Controles.visible = false
	if has_node("Placar"):
		$Placar.visible = false
		montar_placar()
	if has_node("Mensagem"):
		$Mensagem.add_theme_font_override("font", Estilo.titulo())
		$Mensagem.add_theme_font_size_override("font_size", 78)
		$Mensagem.add_theme_constant_override("outline_size", 14)

	velocimetro.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 12)
	velocimetro.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	velocimetro.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(velocimetro)

	convite_texto.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 20)
	convite_texto.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	convite_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	contorno(convite_texto, 22)
	add_child(convite_texto)

	fps.position = Vector2(20, 14)
	contorno(fps, 16)
	add_child(fps)
	dica.text = "ESC: pausa, opções e controles"
	dica.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 20)
	dica.grow_vertical = Control.GROW_DIRECTION_BEGIN
	contorno(dica, 17)
	add_child(dica)
	$Velocidade.position = Vector2(20, 50)
	montar_controles()


func contorno(rotulo: Label, tamanho: int) -> void:
	rotulo.add_theme_font_override("font", Estilo.forte())
	rotulo.add_theme_font_size_override("font_size", tamanho)
	rotulo.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	rotulo.add_theme_constant_override("outline_size", 6)


func montar_placar() -> void:
	var em_cima := VBoxContainer.new()
	em_cima.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 12)
	em_cima.grow_horizontal = Control.GROW_DIRECTION_BOTH
	em_cima.add_theme_constant_override("separation", 2)
	add_child(em_cima)
	placar_caixa.add_theme_constant_override("separation", 0)
	placar_caixa.alignment = BoxContainer.ALIGNMENT_CENTER
	em_cima.add_child(placar_caixa)
	placar_caixa.add_child(caixinha(gols_azul, Color(0.12, 0.35, 0.85, 0.92), [12, 0, 0, 12], 46, 86))
	placar_caixa.add_child(caixinha(relogio, Color(0.04, 0.05, 0.09, 0.88), [0, 0, 0, 0], 32, 150))
	placar_caixa.add_child(caixinha(gols_laranja, Color(0.95, 0.45, 0.1, 0.92), [0, 12, 12, 0], 46, 86))
	meu_time.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	contorno(meu_time, 16)
	em_cima.add_child(meu_time)


func caixinha(rotulo: Label, cor: Color, cantos: Array, tamanho: int, largura: int) -> PanelContainer:
	var caixa := PanelContainer.new()
	var estilo := Estilo.caixa(cor, Color(1, 1, 1, 0.12), 0, 1, 6)
	estilo.corner_radius_top_left = cantos[0]
	estilo.corner_radius_top_right = cantos[1]
	estilo.corner_radius_bottom_right = cantos[2]
	estilo.corner_radius_bottom_left = cantos[3]
	caixa.add_theme_stylebox_override("panel", estilo)
	caixa.custom_minimum_size = Vector2(largura, 64)
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rotulo.add_theme_font_override("font", Estilo.titulo())
	rotulo.add_theme_font_size_override("font_size", tamanho)
	rotulo.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	rotulo.add_theme_constant_override("outline_size", 6)
	caixa.add_child(rotulo)
	return caixa


func atualizar_placar() -> void:
	# o texto vem da partida (no amigo, vem do host): "AZUL  1  ×  0  LARANJA\n4:32\ntu: Laranja"
	var linhas: PackedStringArray = $Placar.text.split("\n")
	var gols := linhas[0].split("×") if linhas.size() > 0 else PackedStringArray()
	if gols.size() == 2:
		gols_azul.text = gols[0].replace("AZUL", "").strip_edges()
		gols_laranja.text = gols[1].replace("LARANJA", "").strip_edges()
	relogio.text = linhas[1].strip_edges() if linhas.size() > 1 else ""
	relogio.add_theme_font_size_override("font_size", 20 if relogio.text.length() > 6 else 32)
	meu_time.text = linhas[2].strip_edges() if linhas.size() > 2 else ""


func montar_controles() -> void:
	convite_texto.text = convite
	if copiou > 0.0:
		convite_texto.text = "Link copiado! Manda pros amigos:\n" + Rede.sala.link()


func _process(delta: float) -> void:
	tempo += delta
	# o código da sala chega depois que a arena abre
	var agora := Rede.convite()
	var apagou := copiou > 0.0 and copiou - delta <= 0.0
	copiou = maxf(copiou - delta, 0.0)
	if agora != convite or apagou:
		convite = agora
		montar_controles()
	if Input.is_action_just_pressed("copiar_link") and Rede.sala and Rede.sala.link() != "":
		DisplayServer.clipboard_set(Rede.sala.link())
		copiou = 4.0
		montar_controles()
	if has_node("Placar"):
		atualizar_placar()

	var v: float = carro.velocidade().length()
	velocimetro.velocidade = v
	velocimetro.maxima = carro.velocidade_maxima
	velocimetro.supersonico = carro.supersonico
	velocimetro.boost = carro.boost
	velocimetro.boostando = carro.boostando
	velocimetro.camera_bola = camera.camera_bola
	fps.visible = Opcoes.pegar("mostrar_fps")
	fps.text = "%d FPS" % Engine.get_frames_per_second()
	dica.modulate.a = clampf(12.0 - tempo, 0.0, 1.0)
	# números de teste: só com o painel F1 aberto
	$Velocidade.visible = painel != null and painel.caixa.visible
	if $Velocidade.visible:
		$Velocidade.text = "%.1f m/s\nRodas no chão: %d/4\nBola: %d km/h  ·  último toque: %d km/h" % [v, carro.rodas_no_chao, roundi(bola.velocidade().length() * 3.6), roundi(bola.ultimo_toque * 3.6)]
