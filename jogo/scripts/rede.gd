extends Node

# Multiplayer: um jogador hospeda (o PC dele roda a física de tudo) e os outros entram nele.
# Quem entra manda os comandos e recebe a posição de tudo; o próprio carro ele calcula na hora
# (pra não sentir o atraso da internet) e vai corrigindo com o que o host manda.
# No PC a conexão é ENet pelo endereço; no navegador é WebRTC, com salas com código (ver sala.gd).

const PORTA := 7777
const MAXIMO_JOGADORES := 6   # 3 contra 3

signal comandos_chegaram(id: int, dados: Array)
signal estado_chegou(dados: Array)
signal ajustes_chegaram(dados: Dictionary)
signal aparencia_chegou(id: int, codigo: PackedByteArray)

var modo := "sozinho"   # "sozinho", "host" ou "cliente"
var aviso := ""         # recado pro menu (ex.: "o host fechou a partida")
var leu_linha_de_comando := false   # o -- --hospedar / --entrar só vale quando o jogo abre
var cena_arena: PackedScene   # carregada no menu e guardada: o "Jogar solo" não espera carregar
var bot := -1                  # jogar solo contra o bot: 0 fácil, 1 médio, 2 difícil (-1 = sem bot)
var ajustes_do_host := {}   # quem entrou guarda os ajustes do carro que o host mandou
var sala: Sala   # sala com código (navegador)
# teste: finge internet lenta segurando cada mensagem que sai (-- --atraso=60 = 60 ms)
var atraso := 0.0
var fila := []


func _ready() -> void:
	multiplayer.connected_to_server.connect(abrir_arena)
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


func treinar(cena := "res://cenas/arena.tscn", nivel_bot := -1) -> void:
	modo = "sozinho"
	bot = nivel_bot
	if cena == "res://cenas/arena.tscn":
		abrir_arena()
	else:
		get_tree().change_scene_to_file(cena)


func abrir_arena() -> void:
	if cena_arena:
		get_tree().change_scene_to_packed(cena_arena)
	else:
		get_tree().change_scene_to_file("res://cenas/arena.tscn")


func hospedar() -> Error:
	bot = -1
	var conexao := ENetMultiplayerPeer.new()
	var erro := conexao.create_server(PORTA, MAXIMO_JOGADORES - 1)
	if erro != OK:
		return erro
	multiplayer.multiplayer_peer = conexao
	modo = "host"
	abrir_arena()
	return OK


func entrar(endereco: String) -> Error:
	var conexao := ENetMultiplayerPeer.new()
	var erro := conexao.create_client(endereco.strip_edges(), PORTA)
	if erro != OK:
		return erro
	multiplayer.multiplayer_peer = conexao
	modo = "cliente"
	return OK


func criar_sala() -> void:
	bot = -1
	nova_sala().criar()
	multiplayer.multiplayer_peer = sala.conexao
	modo = "host"
	abrir_arena()


func entrar_na_sala(codigo: String) -> void:
	# a arena só abre quando conectar no host (connected_to_server)
	nova_sala().entrar(codigo)
	multiplayer.multiplayer_peer = sala.conexao
	modo = "cliente"


func nova_sala() -> Sala:
	fechar_sala()
	sala = Sala.new()
	sala.falhou.connect(sair)
	add_child(sala)
	return sala


func convite() -> String:
	# o que aparece na tela de quem hospeda pros amigos entrarem
	if modo != "host":
		return ""
	if not sala:
		return "HOSPEDANDO · teus amigos entram em: %s" % "  ou  ".join(enderecos_deste_pc())
	if sala.codigo == "" or not sala.ativa:
		return "Criando a sala…"
	return "SALA %s\nteus amigos entram com esse código no site\nL: copiar o link" % sala.codigo


func fechar_sala() -> void:
	# primeiro desliga o jogo da conexão (senão o "host saiu" dispara de novo) e depois fecha a sala
	if not sala:
		return
	var velha := sala
	sala = null
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	velha.falhou.disconnect(sair)
	velha.fechar()


func sair(motivo := "") -> void:
	fechar_sala()
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


@rpc("any_peer", "call_remote", "reliable", 2)
func receber_aparencia(codigo: PackedByteArray) -> void:
	# quem entrou conta pro host como personalizou o carro (o host repassa no estado)
	aparencia_chegou.emit(multiplayer.get_remote_sender_id(), codigo)
