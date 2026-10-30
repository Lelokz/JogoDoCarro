extends Node

# Multiplayer: um jogador hospeda (o PC dele roda a física de tudo) e os outros entram nele.
# Quem entra manda os comandos e recebe a posição de tudo; o próprio carro ele calcula na hora
# (pra não sentir o atraso da internet) e vai corrigindo com o que o host manda.

const PORTA := 7777
const MAXIMO_JOGADORES := 6   # 3 contra 3

signal comandos_chegaram(id: int, dados: Array)
signal estado_chegou(dados: Array)
signal ajustes_chegaram(dados: Dictionary)

var modo := "sozinho"   # "sozinho", "host" ou "cliente"
var aviso := ""         # recado pro menu (ex.: "o host fechou a partida")
var leu_linha_de_comando := false   # o -- --hospedar / --entrar só vale quando o jogo abre
var cena_arena: PackedScene   # carregada no menu e guardada: o "Treinar sozinho" não espera carregar
var ajustes_do_host := {}   # quem entrou guarda os ajustes do carro que o host mandou
# teste: finge internet lenta segurando cada mensagem que sai (-- --atraso=60 = 60 ms)
var atraso := 0.0
var fila := []


func _ready() -> void:
	multiplayer.connected_to_server.connect(func() -> void: get_tree().change_scene_to_file("res://cenas/arena.tscn"))
	multiplayer.connection_failed.connect(func() -> void: sair("Não deu pra conectar no host. Confere o endereço e se ele já clicou em Hospedar."))
	multiplayer.server_disconnected.connect(func() -> void: sair("O host fechou a partida."))
	for argumento in OS.get_cmdline_user_args():
		if argumento.begins_with("--atraso="):
			atraso = argumento.trim_prefix("--atraso=").to_float() / 1000.0


func _physics_process(_delta: float) -> void:
	var agora := Time.get_ticks_msec() / 1000.0
	while not fila.is_empty() and fila[0][0] <= agora:
		fila.pop_front()[1].call()


func enviar(mensagem: Callable) -> void:
	if atraso <= 0.0:
		mensagem.call()
	else:
		fila.append([Time.get_ticks_msec() / 1000.0 + atraso, mensagem])


func treinar(cena := "res://cenas/arena.tscn") -> void:
	modo = "sozinho"
	if cena == "res://cenas/arena.tscn" and cena_arena:
		get_tree().change_scene_to_packed(cena_arena)
	else:
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
	ajustes_do_host = {}
	fila.clear()
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


@rpc("authority", "call_remote", "reliable", 2)
func receber_ajustes(dados: Dictionary) -> void:
	ajustes_do_host = dados
	ajustes_chegaram.emit(dados)
