extends CanvasLayer

@export var carro_caminho: NodePath
@export var bola_caminho: NodePath
@export var camera_caminho: NodePath

var carro: RigidBody3D
var bola: RigidBody3D
var camera: Camera3D
var convite := ""
var convite_texto := Label.new()   # canto de cima, na tela de quem hospeda
var copiou := 0.0   # segundos mostrando "link copiado"


func _ready() -> void:
	carro = get_node(carro_caminho)
	bola = get_node(bola_caminho)
	camera = get_node(camera_caminho)
	convite_texto.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 20)
	convite_texto.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	convite_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	convite_texto.add_theme_font_size_override("font_size", 22)
	convite_texto.add_theme_color_override("font_outline_color", Color.BLACK)
	convite_texto.add_theme_constant_override("outline_size", 6)
	add_child(convite_texto)
	montar_controles()


func montar_controles() -> void:
	convite_texto.text = convite
	if copiou > 0.0:
		convite_texto.text = "Link copiado! Manda pros amigos:\n" + Rede.sala.link()
	$Controles.text = "W/S ou RT/LT: acelerar e ré   ·   A/D ou analógico: virar   ·   Shift ou X: freio de mão (no ar: rolar)\nEspaço, botão direito ou A: pulo (de novo no ar = duplo pulo; com direção = mortal)   ·   Botão esquerdo, F ou B: boost\nNo ar: W/S inclina, A/D vira, Q/E rola   ·   C ou Y: câmera da bola   ·   G: bola na frente   ·   R: desvirar   ·   T: início   ·   F1: ajustes   ·   F2: arena / campo de teste   ·   ESC: menu   ·   F11: tela cheia"


func _process(delta: float) -> void:
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
	var v: float = carro.velocidade().length()
	$Velocidade.text = "%d km/h  (%.1f m/s)\nRodas no chão: %d/4\nBola: %d km/h  ·  último toque: %d km/h\nCâmera: %s%s" % [roundi(v * 3.6), v, carro.rodas_no_chao, roundi(bola.velocidade().length() * 3.6), roundi(bola.ultimo_toque * 3.6), "bola" if camera.camera_bola else "carro", "  ·  %d FPS" % Engine.get_frames_per_second() if Opcoes.pegar("mostrar_fps") else ""]
	$Boost.text = ("SUPERSÔNICO\n" if carro.supersonico else "") + "Boost %d" % roundi(carro.boost)
