extends CanvasLayer

# Painel de ajuste ao vivo (F1): mexe nos valores com o carro andando.

@export var carro_caminho: NodePath
@export var camera_caminho: NodePath
@export var bola_caminho: NodePath

const SALVO_PROJETO := "res://ajustes/carro.json"
const SALVO_JOGO := "user://carro.json"

# [alvo, propriedade, nome, mínimo, máximo, passo] ou ["titulo", texto]
const AJUSTES := [
	["titulo", "Mundo"],
	["mundo", "gravidade", "Gravidade (m/s²)", 1.0, 20.0, 0.1],
	["titulo", "Suspensão"],
	["carro", "mola", "Mola (N/m)", 1000.0, 20000.0, 100.0],
	["carro", "amortecedor", "Amortecedor", 0.0, 3000.0, 10.0],
	["carro", "curso_mola", "Curso da mola (m)", 0.03, 0.3, 0.01],
	["carro", "batente", "Batente", 0.0, 60000.0, 500.0],
	["carro", "grude", "Grude no chão (m/s²)", 0.0, 10.0, 0.05],
	["titulo", "Motor e freio"],
	["carro", "forca_motor", "Força do motor", 0.2, 3.0, 0.05],
	["carro", "velocidade_maxima", "Velocidade máxima (m/s)", 5.0, 40.0, 0.5],
	["carro", "freio", "Freio (m/s²)", 5.0, 80.0, 1.0],
	["carro", "desaceleracao_solto", "Desacelera solto (m/s²)", 0.0, 20.0, 0.25],
	["titulo", "Curva e pneus"],
	["carro", "multiplicador_curva", "Curva", 0.3, 2.0, 0.05],
	["carro", "aderencia", "Aderência (m/s²)", 5.0, 150.0, 1.0],
	["carro", "aderencia_freio_mao", "Aderência no freio de mão", 0.0, 60.0, 0.5],
	["carro", "giro_freio_mao", "Giro no freio de mão", 1.0, 3.0, 0.05],
	["carro", "volta_aderencia", "Volta da aderência (s)", 0.05, 2.0, 0.05],
	["carro", "endireitar", "Endireitar na saída do drift", 0.0, 8.0, 0.1],
	["titulo", "Pulo e mortal"],
	["carro", "forca_pulo", "Pulo (m/s)", 0.5, 8.0, 0.05],
	["carro", "forca_segurando", "Segurando o pulo (m/s²)", 0.0, 40.0, 0.25],
	["carro", "tempo_segurando", "Tempo segurando (s)", 0.03, 0.6, 0.01],
	["carro", "janela_pulo_extra", "Tempo pro 2º pulo (s)", 0.3, 3.0, 0.05],
	["carro", "forca_mortal", "Empurrão do mortal (m/s)", 0.0, 15.0, 0.1],
	["carro", "duracao_mortal", "Giro do mortal (s)", 0.2, 1.5, 0.01],
	["titulo", "Ar e boost"],
	["carro", "controle_no_ar", "Controle no ar", 0.2, 3.0, 0.05],
	["carro", "aceleracao_boost", "Força do boost (m/s²)", 2.0, 30.0, 0.1],
	["carro", "gasto_boost", "Gasto do boost (por s)", 5.0, 100.0, 0.5],
	["carro", "recarga_boost", "Recarga do boost (por s)", 0.0, 100.0, 1.0],
	["titulo", "Bola"],
	["bola", "forca_batida", "Força da batida", 0.2, 2.0, 0.05],
	["bola", "empurrao_extra", "Empurrão extra do toque", 0.0, 3.0, 0.05],
	["bola", "physics_material_override:bounce", "Quique da bola", 0.0, 1.0, 0.01],
	["bola", "physics_material_override:friction", "Atrito da bola", 0.0, 2.0, 0.01],
	["bola", "mass", "Peso da bola", 5.0, 180.0, 1.0],
	["bola", "linear_damp", "Resistência do ar da bola", 0.0, 1.0, 0.01],
	["bola", "velocidade_maxima", "Velocidade máxima da bola (m/s)", 10.0, 150.0, 1.0],
	["titulo", "Câmera"],
	["camera", "distancia", "Distância (m)", 1.5, 6.0, 0.1],
	["camera", "altura", "Altura (m)", 0.3, 3.0, 0.05],
	["camera", "fov", "FOV (graus)", 60.0, 120.0, 1.0],
	["camera", "suavidade", "Suavidade do giro", 1.0, 30.0, 0.5],
]

var gravidade: float:
	get:
		return PhysicsServer3D.area_get_param(get_viewport().find_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY)
	set(valor):
		PhysicsServer3D.area_set_param(get_viewport().find_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY, valor)

var alvos := {}
var deslizadores := {}
var padrao := {}
var caixa := PanelContainer.new()
var aviso := Label.new()
var molas := Label.new()


func _ready() -> void:
	layer = 10
	alvos = {"carro": get_node(carro_caminho), "camera": get_node(camera_caminho), "bola": get_node(bola_caminho), "mundo": self}
	montar()
	padrao = ler_tudo()
	carregar()
	caixa.visible = false


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("painel"):
		caixa.visible = not caixa.visible


func _process(_delta: float) -> void:
	if not caixa.visible:
		return
	var carro: RigidBody3D = alvos["carro"]
	var partes := []
	for i in 4:
		partes.append("%s %d%%" % [["FE", "FD", "TE", "TD"][i], roundi(carro.compressao[i] / carro.curso_mola * 100.0)])
	molas.text = "Molas apertadas: " + "  ".join(partes)


func montar() -> void:
	caixa.position = Vector2(20, 90)
	add_child(caixa)
	var rolagem := ScrollContainer.new()
	rolagem.custom_minimum_size = Vector2(460, 540)
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	caixa.add_child(rolagem)
	var lista := VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolagem.add_child(lista)

	var titulo := Label.new()
	titulo.text = "Ajustes (F1 fecha)"
	titulo.add_theme_font_size_override("font_size", 20)
	lista.add_child(titulo)
	lista.add_child(molas)

	for a in AJUSTES:
		if a[0] == "titulo":
			var secao := Label.new()
			secao.text = a[1]
			secao.add_theme_color_override("font_color", Color(0.95, 0.55, 0.15))
			lista.add_child(secao)
			continue
		var linha := HBoxContainer.new()
		var nome := Label.new()
		nome.text = a[2]
		nome.custom_minimum_size.x = 210
		var deslizador := HSlider.new()
		deslizador.min_value = a[3]
		deslizador.max_value = a[4]
		deslizador.step = a[5]
		deslizador.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		deslizador.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		deslizador.focus_mode = Control.FOCUS_NONE
		var valor := Label.new()
		valor.custom_minimum_size.x = 64
		valor.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		deslizador.value_changed.connect(func(v: float) -> void:
			alvos[a[0]].set_indexed(a[1], v)
			valor.text = formatar(v, a[5]))
		deslizador.value = alvos[a[0]].get_indexed(a[1])
		deslizadores[a[0] + "/" + a[1]] = deslizador
		linha.add_child(nome)
		linha.add_child(deslizador)
		linha.add_child(valor)
		lista.add_child(linha)

	var botoes := HBoxContainer.new()
	for b in [["Salvar", salvar], ["Voltar pro salvo", carregar], ["Valores de partida", func() -> void: aplicar(padrao); aviso.text = "Voltou pros valores de partida."]]:
		var botao := Button.new()
		botao.text = b[0]
		botao.focus_mode = Control.FOCUS_NONE
		botao.pressed.connect(b[1])
		botoes.add_child(botao)
	lista.add_child(botoes)
	lista.add_child(aviso)


func formatar(v: float, passo: float) -> String:
	if passo >= 1.0:
		return "%d" % roundi(v)
	if passo >= 0.1:
		return "%.1f" % v
	return "%.2f" % v


func ler_tudo() -> Dictionary:
	var dados := {}
	for chave in deslizadores:
		var partes: PackedStringArray = chave.split("/")
		if not dados.has(partes[0]):
			dados[partes[0]] = {}
		dados[partes[0]][partes[1]] = alvos[partes[0]].get_indexed(partes[1])
	return dados


func aplicar(dados: Dictionary) -> void:
	for chave in deslizadores:
		var partes: PackedStringArray = chave.split("/")
		if dados.has(partes[0]) and dados[partes[0]].has(partes[1]):
			deslizadores[chave].value = dados[partes[0]][partes[1]]


func caminho_salvo() -> String:
	# rodando do projeto, salva junto dele (vai pro git); no jogo exportado, na pasta do usuário
	return SALVO_PROJETO if OS.has_feature("editor") else SALVO_JOGO


func salvar() -> void:
	if caminho_salvo() == SALVO_PROJETO:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://ajustes"))
	var arquivo := FileAccess.open(caminho_salvo(), FileAccess.WRITE)
	if arquivo == null:
		aviso.text = "Não deu pra salvar."
		return
	arquivo.store_string(JSON.stringify(ler_tudo(), "\t"))
	aviso.text = "Salvo! Abre assim da próxima vez."


func carregar() -> void:
	if not FileAccess.file_exists(caminho_salvo()):
		aviso.text = "Nada salvo ainda: usando os valores de partida."
		return
	var dados = JSON.parse_string(FileAccess.get_file_as_string(caminho_salvo()))
	if dados is Dictionary:
		aplicar(dados)
		aviso.text = "Carregou o ajuste salvo."
