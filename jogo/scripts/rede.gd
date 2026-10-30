extends Node

# Multiplayer: um jogador hospeda (o PC dele roda a física de tudo) e os outros entram nele.
# Quem entra só manda os comandos e recebe a posição de tudo.

const PORTA := 7777
const MAXIMO_JOGADORES := 6   # 3 contra 3

signal comandos_chegaram(id: int, dados: Array)
signal estado_chegou(dados: Array)

var modo := "sozinho"   # "sozinho", "host" ou "cliente"
var aviso := ""         # recado pro menu (ex.: "o host fechou a partida")
var leu_linha_de_comando := false   # o -- --hospedar / --entrar só vale quando o jogo abre


func _ready() -> void:
	multiplayer.connected_to_server.connect(func() -> void: get_tree().change_scene_to_file("res://cenas/arena.tscn"))
	multiplayer.connection_failed.connect(func() -> void: sair("Não deu pra conectar no host. Confere o endereço e se ele já clicou em Hospedar."))
	multiplayer.server_disconnected.connect(func() -> void: sair("O host fechou a partida."))


func treinar(cena := "res://cenas/arena.tscn") -> void:
	modo = "sozinho"
	get_tree().change_scene_to_file(cena)


func hospedar() -> Error:
	var conexao := ENetMultiplayerPeer.new()
	var erro := conexao.create_server(PORTA, MAXIMO_JOGADORES - 1)
	if erro != OK:
		return erro
	multiplayer.multiplayer_peer = conexao
	modo = "host"
	get_tree().change_scene_to_file("res://cenas/arena.tscn")
	return OK


func entrar(endereco: String) -> Error:
	var conexao := ENetMultiplayerPeer.new()
	var erro := conexao.create_client(endereco.strip_edges(), PORTA)
	if erro != OK:
		return erro
	multiplayer.multiplayer_peer = conexao
	modo = "cliente"
	return OK


func sair(motivo := "") -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	modo = "sozinho"
	aviso = motivo
	get_tree().change_scene_to_file("res://cenas/menu.tscn")


func online() -> bool:
	return modo != "sozinho"


func enderecos_deste_pc() -> Array:
	# pra mostrar pros amigos: rede de casa (192.168…) e Tailscale/ZeroTier (100…, 10…)
	var lista := []
	for ip in IP.get_local_addresses():
		if ip.count(".") == 3 and not ip.begins_with("127.") and not ip.begins_with("169.254."):
			lista.append(ip)
	return lista


@rpc("any_peer", "call_remote", "unreliable_ordered")
func receber_comandos(dados: Array) -> void:
	comandos_chegaram.emit(multiplayer.get_remote_sender_id(), dados)


@rpc("authority", "call_remote", "unreliable_ordered", 1)
func receber_estado(dados: Array) -> void:
	estado_chegou.emit(dados)
