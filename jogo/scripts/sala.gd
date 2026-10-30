class_name Sala
extends Node

# Salas com código pelo navegador. O banco do Firebase é só um quadro de recados: o host cria a sala,
# cada amigo que entra deixa um recado com um número dele, e pelos recados os dois trocam o "aperto de
# mão" do WebRTC (oferta, resposta e os caminhos possíveis pela internet). Depois disso o jogo conversa
# direto, navegador com navegador, e o banco não é mais usado.

const BANCO := "https://rocketwar-2a302-default-rtdb.firebaseio.com/"
const LETRAS := "ABCDEFGHJKLMNPQRSTUVWXYZ"   # sem I e O pra não confundir com 1 e 0
const AGORA := {".sv": "timestamp"}   # o Firebase troca pela hora dele
const SERVIDORES := [{"urls": ["stun:stun.l.google.com:19302", "stun:stun1.l.google.com:19302"]}]
# canais 1 e 2 das mensagens (estado do jogo e ajustes do host), os mesmos do ENet
const CANAIS := [MultiplayerPeer.TRANSFER_MODE_UNRELIABLE_ORDERED, MultiplayerPeer.TRANSFER_MODE_RELIABLE]
const ESPERA_MAXIMA := 25.0   # segundos tentando conectar antes de desistir
const SALA_VELHA := 12 * 3600 * 1000   # sala esquecida aberta há mais de 12 h pode ter o código reusado

signal pronta
signal falhou(motivo: String)

var conexao := WebRTCMultiplayerPeer.new()
var codigo := ""
var host := false
var ativa := false
var tempo := 0.0
var proxima_olhada := 0.0
var olhando := false   # tem uma leitura do banco em andamento
# host: amigos ainda no aperto de mão {id: {par, vistos, respondeu, desde}} e os que já foram resolvidos
var pendentes := {}
var resolvidos := {}
# amigo
var meu_id := 0
var par: WebRTCPeerConnection
var recebeu_oferta := false
var vistos := {}


func criar() -> void:
	host = true
	conexao.create_server(CANAIS)
	conexao.peer_connected.connect(amigo_conectou)
	tentar_codigo(5)


func tentar_codigo(tentativas: int) -> void:
	codigo = ""
	for i in 4:
		codigo += LETRAS[randi() % LETRAS.length()]
	pedir(HTTPClient.METHOD_GET, "salas/%s/host" % codigo, null, func(ok: bool, dados: Variant) -> void:
		if not ok:
			falhou.emit("Sem conexão com o servidor das salas. Confere a internet e tenta de novo.")
			return
		var agora := Time.get_unix_time_from_system() * 1000.0
		if dados is Dictionary and agora - float(dados.get("criada", 0)) < SALA_VELHA and tentativas > 0:
			tentar_codigo(tentativas - 1)
			return
		pedir(HTTPClient.METHOD_PUT, "salas/" + codigo, {"host": {"criada": AGORA}}, func(gravou: bool, _d: Variant) -> void:
			if not gravou:
				falhou.emit("Não deu pra criar a sala. Tenta de novo.")
				return
			print("[sala] criada: ", codigo)
			ativa = true
			pronta.emit()))


func entrar(qual: String) -> void:
	codigo = qual
	meu_id = randi_range(2, 2147483647)
	conexao.create_client(meu_id, CANAIS)
	par = nova_conexao(1, meu_id)
	pedir(HTTPClient.METHOD_GET, "salas/%s/host" % codigo, null, func(ok: bool, dados: Variant) -> void:
		if not ok:
			falhou.emit("Sem conexão com o servidor das salas. Confere a internet e tenta de novo.")
		elif dados == null:
			falhou.emit("A sala %s não existe. Confere o código (ou o host fechou ela)." % codigo)
		else:
			pedir(HTTPClient.METHOD_PUT, "salas/%s/jogadores/%d" % [codigo, meu_id], {"entrou": AGORA}, func(gravou: bool, _d: Variant) -> void:
				if gravou:
					ativa = true
				else:
					falhou.emit("Não deu pra entrar na sala. Tenta de novo.")))


func fechar() -> void:
	ativa = false
	conexao.close()
	if codigo == "" or (not host and meu_id == 0):
		queue_free()
		return
	var caminho := "salas/" + codigo if host else "salas/%s/jogadores/%d" % [codigo, meu_id]
	pedir(HTTPClient.METHOD_DELETE, caminho, null, func(_ok: bool, _d: Variant) -> void: queue_free())


func link() -> String:
	if codigo == "" or not OS.has_feature("web"):
		return ""
	return str(JavaScriptBridge.eval("location.origin + location.pathname")) + "?sala=" + codigo


func _process(delta: float) -> void:
	tempo += delta
	if not ativa:
		return
	if not host and conexao.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		print("[sala] conectado no host")
		ativa = false
		return
	if not host and tempo > ESPERA_MAXIMA:
		falhou.emit("Não deu pra conectar no host da sala %s. Ele ainda está na partida? Tenta de novo." % codigo)
		ativa = false
		return
	if host:
		desistir_dos_demorados()
	if olhando or tempo < proxima_olhada:
		return
	olhando = true
	proxima_olhada = tempo + (1.0 if host else 0.5)
	if host:
		pedir(HTTPClient.METHOD_GET, "salas/%s/jogadores" % codigo, null, olhar_jogadores)
	else:
		pedir(HTTPClient.METHOD_GET, "salas/%s/jogadores/%d" % [codigo, meu_id], null, olhar_recado)


func nova_conexao(id: int, quem: int) -> WebRTCPeerConnection:
	# quem: o número do amigo, que é onde ficam os recados dessa conversa
	var novo := WebRTCPeerConnection.new()
	novo.initialize({"iceServers": SERVIDORES})
	var caminho := "salas/%s/jogadores/%d/" % [codigo, quem]
	novo.session_description_created.connect(func(tipo: String, sdp: String) -> void:
		novo.set_local_description(tipo, sdp)
		pedir(HTTPClient.METHOD_PUT, caminho + ("oferta" if host else "resposta"), sdp))
	novo.ice_candidate_created.connect(func(midia: String, indice: int, nome: String) -> void:
		pedir(HTTPClient.METHOD_POST, caminho + ("candidatos_host" if host else "candidatos_amigo"), {"m": midia, "i": indice, "n": nome}))
	conexao.add_peer(novo, id)
	return novo


func olhar_jogadores(ok: bool, dados: Variant) -> void:
	olhando = false
	if not ok or not dados is Dictionary or not ativa:
		return
	for chave in dados:
		var id := int(chave)
		var recado: Variant = dados[chave]
		if resolvidos.has(id) or not recado is Dictionary:
			continue
		if not pendentes.has(id):
			if conexao.get_peers().size() >= Rede.MAXIMO_JOGADORES - 1:
				resolvidos[id] = true
				pedir(HTTPClient.METHOD_PUT, "salas/%s/jogadores/%d/cheia" % [codigo, id], true)
				continue
			print("[sala] amigo chegando: ", id)
			pendentes[id] = {"par": nova_conexao(id, id), "vistos": {}, "respondeu": false, "desde": tempo}
			pendentes[id].par.create_offer()
		var amigo: Dictionary = pendentes[id]
		if recado.get("resposta") is String and not amigo.respondeu:
			amigo.respondeu = true
			amigo.par.set_remote_description("answer", recado.resposta)
		if amigo.respondeu:
			usar_candidatos(amigo.par, recado.get("candidatos_amigo"), amigo.vistos)


func olhar_recado(ok: bool, dados: Variant) -> void:
	olhando = false
	if not ok or not dados is Dictionary or not ativa:
		return
	if dados.get("cheia", false):
		falhou.emit("A sala %s está cheia (%d jogadores)." % [codigo, Rede.MAXIMO_JOGADORES])
		ativa = false
		return
	if dados.get("oferta") is String and not recebeu_oferta:
		# a resposta sai sozinha pelo session_description_created
		recebeu_oferta = true
		par.set_remote_description("offer", dados.oferta)
	if recebeu_oferta:
		usar_candidatos(par, dados.get("candidatos_host"), vistos)


func usar_candidatos(com: WebRTCPeerConnection, candidatos: Variant, ja_vistos: Dictionary) -> void:
	if not candidatos is Dictionary:
		return
	for chave in candidatos:
		var c: Variant = candidatos[chave]
		if ja_vistos.has(chave) or not c is Dictionary:
			continue
		ja_vistos[chave] = true
		com.add_ice_candidate(str(c.get("m", "")), int(c.get("i", 0)), str(c.get("n", "")))


func amigo_conectou(id: int) -> void:
	print("[sala] amigo conectou: ", id)
	pendentes.erase(id)
	resolvidos[id] = true
	pedir(HTTPClient.METHOD_DELETE, "salas/%s/jogadores/%d" % [codigo, id])


func desistir_dos_demorados() -> void:
	for id in pendentes.keys():
		if tempo - pendentes[id].desde > ESPERA_MAXIMA + 5.0:
			print("[sala] amigo não conseguiu conectar: ", id)
			pendentes.erase(id)
			resolvidos[id] = true
			if conexao.has_peer(id):
				conexao.remove_peer(id)
			pedir(HTTPClient.METHOD_DELETE, "salas/%s/jogadores/%d" % [codigo, id])


func pedir(metodo: int, caminho: String, dados: Variant = null, depois := Callable()) -> void:
	# uma conversa com o banco pela API REST do Firebase (funciona igual no navegador e no PC)
	var http := HTTPRequest.new()
	http.timeout = 10.0
	add_child(http)
	http.request_completed.connect(func(resultado: int, codigo_http: int, _cabecalhos: PackedStringArray, corpo: PackedByteArray) -> void:
		http.queue_free()
		if depois.is_valid():
			var ok := resultado == HTTPRequest.RESULT_SUCCESS and codigo_http == 200
			depois.call(ok, JSON.parse_string(corpo.get_string_from_utf8()) if ok else null))
	http.request(BANCO + caminho + ".json", [], metodo, "" if dados == null else JSON.stringify(dados))
