extends Node

# Opções de cada jogador (câmera, gráficos, FPS, tela cheia). Ficam salvas no PC / navegador de cada um
# e não vão pela rede. A física (painel F1) continua sendo só do host.

signal mudou

const ARQUIVO := "user://opcoes.json"
const QUALIDADES := ["Baixo", "Médio", "Alto"]
const PADRAO := {
	"fov": 100.0,
	"distancia": 2.5,
	"altura": 1.3,
	"graficos": 2,   # 0 baixo, 1 médio, 2 alto
	"mostrar_fps": false,
	"tela_cheia": false,
}

var valores := PADRAO.duplicate()


func _ready() -> void:
	if FileAccess.file_exists(ARQUIVO):
		var salvo = JSON.parse_string(FileAccess.get_file_as_string(ARQUIVO))
		if salvo is Dictionary:
			for nome in salvo:
				if PADRAO.has(nome):
					valores[nome] = type_convert(salvo[nome], typeof(PADRAO[nome]))
	# no navegador a tela cheia só pode abrir com um clique: não volta sozinha
	if valores.tela_cheia and not OS.has_feature("web"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func pegar(nome: String) -> Variant:
	return valores[nome]


func definir(nome: String, valor: Variant) -> void:
	valores[nome] = valor
	if nome == "tela_cheia":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if valor else DisplayServer.WINDOW_MODE_WINDOWED)
	salvar()
	mudou.emit()


func voltar_ao_padrao() -> void:
	for nome in PADRAO:
		if nome != "tela_cheia":
			valores[nome] = PADRAO[nome]
	salvar()
	mudou.emit()


func salvar() -> void:
	var arquivo := FileAccess.open(ARQUIVO, FileAccess.WRITE)
	if arquivo:
		arquivo.store_string(JSON.stringify(valores, "\t"))


func aplicar_graficos(cena: Node) -> void:
	# baixo: sem sombra, brilho e névoa, resolução 75%; médio: sem brilho; alto: tudo
	var q: int = valores.graficos
	for sol in cena.find_children("*", "DirectionalLight3D", true, false):
		sol.shadow_enabled = q >= 1
	for ambiente in cena.find_children("*", "WorldEnvironment", true, false):
		ambiente.environment.glow_enabled = q >= 2
		ambiente.environment.fog_enabled = q >= 1
	var tela := cena.get_viewport()
	tela.scaling_3d_scale = 0.75 if q == 0 else 1.0
	tela.msaa_3d = Viewport.MSAA_DISABLED if q == 0 else Viewport.MSAA_2X


func tela_cheia_agora() -> bool:
	return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
