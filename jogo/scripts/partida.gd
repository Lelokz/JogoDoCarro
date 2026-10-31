extends Node

# Regras da partida: saída de bola com contagem, gol, placar, cronômetro, prorrogação e pads de boost.
# Sozinho ou hospedando, a partida roda aqui e o host manda tudo pros outros 60 vezes por segundo.
# Quem entrou na partida de outro mostra o que chega e manda os próprios comandos pro host.
# O próprio carro ele calcula na hora (não espera a internet) e vai corrigindo com o que o host
# calculou pro mesmo comando: se bate, nada muda; se não bate, puxa aos poucos pro certo.
# O Azul ataca o gol laranja (z negativo); o Laranja ataca o gol azul.

@export var carro_caminho: NodePath
@export var bola_caminho: NodePath
@export var hud_caminho: NodePath

const TEMPO_PARTIDA := 300.0
const TEMPO_CONTAGEM := 3.0
const TEMPO_COMEMORACAO := 3.0
const BOOST_SAIDA := 33.0
const RAIO_BOLA := 0.9125
const ALTURA_CARRO := 0.32
# onde os carros do Azul podem começar na saída de bola; o Laranja usa os mesmos lugares espelhados
const SAIDAS := [Vector3(0, 0, 42), Vector3(-2.5, 0, 36), Vector3(2.5, 0, 36), Vector3(-20, 0, 25), Vector3(20, 0, 25)]
# pads: grandes enchem o tanque e voltam em 10 s; pequenos dão 12 e voltam em 4 s
const PADS_GRANDES := [Vector2(-33, -38), Vector2(33, -38), Vector2(-33, 38), Vector2(33, 38), Vector2(-36, 0), Vector2(36, 0)]
const PADS_PEQUENOS := [
	Vector2(0, -12), Vector2(0, 12), Vector2(0, -30), Vector2(0, 30),
	Vector2(-12, -20), Vector2(12, -20), Vector2(-12, 20), Vector2(12, 20), Vector2(-12, 0), Vector2(12, 0),
	Vector2(-24, -10), Vector2(24, -10), Vector2(-24, 10), Vector2(24, 10),
	Vector2(-24, -30), Vector2(24, -30), Vector2(-24, 30), Vector2(24, 30),
	Vector2(-8, -42), Vector2(8, -42), Vector2(-8, 42), Vector2(8, 42),
]
const CENA_CARRO := preload("res://cenas/carro.tscn")
const ID_BOT := 1000
# quem entrou mostra a partida um pouquinho atrás (6 quadros do host = 50 ms),
# pra sempre ter dois estados pra misturar e o movimento ficar liso
const ATRASO_IMAGEM := 6.0
const FRACAO_CORRECAO := 0.3   # quanto da diferença pro host corrige por estado que chega
const ERRO_TELEPORTE := 4.0    # m: mais que isso (ex.: saída de bola) corrige de uma vez
const TEMPO_AJUSTES := 2.0     # s entre um envio e outro dos ajustes do carro
# demolição: carro supersônico batendo num adversário (indo na direção dele a mais que isso) explode ele
const VELOCIDADE_DEMOLIR := 10.0   # m/s
const TEMPO_DEMOLIDO := 3.0        # s até voltar, perto do próprio gol
const VOLTAS := [Vector3(-10, 0, 46), Vector3(10, 0, 46), Vector3(0, 0, 47)]   # lado do azul (o laranja é espelhado)
# explosão do gol: empurra os carros perto, mais forte quanto mais rápida a bola entrou
const RAIO_EXPLOSAO_GOL := 24.0    # m
const EMPURRAO_GOL := 22.0         # m/s pra quem está colado na bola

enum Estado { CONTAGEM, JOGANDO, GOL, FIM }

var carro: RigidBody3D   # o carro de quem joga neste PC
var bola: RigidBody3D
var hud: CanvasLayer
var carros := {}   # id do jogador → carro
var times := {}    # id do jogador → "azul" ou "laranja"
var estado := Estado.CONTAGEM
var tempo_estado := 0.0
var relogio := TEMPO_PARTIDA
var prorrogacao := false
var acabou := false
var placar := {"azul": 0, "laranja": 0}
var texto_placar := ""
var pads := []
var voltam_em := {}            # id do jogador demolido → quando ele volta (tempo_total)
var velocidades_antes := {}    # id → [velocidade, supersônico] do quadro anterior (a batida já freou)
var explosoes := []            # as últimas explosões [número, onde, cor, tamanho]: vão pros amigos
var numero_explosao := 0
var explosao_vista := -1       # amigo: a última explosão que já apareceu aqui
var tempo_total := 0.0
var estados_recebidos := []
var quadro_imagem := -1.0
# host: os comandos de cada amigo esperam numa fila e a física usa um por passo, em ordem
# (pela internet eles chegam em bolos); comando_usado = número do comando que a física usou
const FILA_MAXIMA := 4
var fila_comandos := {}
var comando_usado := {}
var tempo_ajustes := 0.0
var malhas_dos_pads := {}
# quem entrou: o que o próprio carro calculou em cada comando, pra comparar com o host
var historico := {}
var comando_anterior := -1
var erros_medidos := []   # pros testes: tamanho da diferença pro host (m)


func _ready() -> void:
	carro = get_node(carro_caminho)
	bola = get_node(bola_caminho)
	hud = get_node(hud_caminho)
	for p in PADS_GRANDES:
		criar_pad(p, true)
	for p in PADS_PEQUENOS:
		criar_pad(p, false)
	var eu := multiplayer.get_unique_id()
	carros[eu] = carro
	if Rede.modo == "cliente":
		bola.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		bola.freeze = true
		# a bola e os outros carros só aparecem onde o host manda: o meu carro passa por eles aqui,
		# quem bate de verdade é o host (e a correção traz o resultado)
		carro.add_collision_exception_with(bola)
		carro.travado = true
		Rede.estado_chegou.connect(estado_chegou)
		Rede.ajustes_chegaram.connect(aplicar_ajustes)
		if not Rede.ajustes_do_host.is_empty():
			aplicar_ajustes(Rede.ajustes_do_host)
		mensagem("Entrando na partida…")
		return
	times[eu] = "azul"
	carro.definir_time("azul")
	if Rede.modo == "sozinho" and Rede.bot >= 0:
		adicionar_bot.call_deferred(Rede.bot)   # a arena ainda está se montando aqui
	if Rede.modo == "host":
		multiplayer.peer_connected.connect(jogador_entrou)
		multiplayer.peer_disconnected.connect(jogador_saiu)
		Rede.comandos_chegaram.connect(comandos_chegaram)
	saida_de_bola()


func _physics_process(delta: float) -> void:
	if Rede.modo == "cliente":
		if comando_anterior >= 0:
			historico[comando_anterior] = [carro.global_position, carro.global_basis.get_rotation_quaternion(), carro.linear_velocity, carro.angular_velocity, carro.boost]
		var numero := Engine.get_physics_frames()
		var dados: Array = [numero] + carro.comandos.para_rede()
		Rede.enviar(func() -> void: Rede.receber_comandos.rpc_id(1, dados))
		comando_anterior = numero
		mostrar_estado()
		return

	# o estado de agora veio do passo da física que usou os comandos do quadro anterior
	var comandos_do_estado := comando_usado.duplicate()
	usar_comandos_da_fila()
	tempo_estado += delta
	tempo_total += delta
	atualizar_pads()
	reviver_demolidos()
	match estado:
		Estado.CONTAGEM:
			var falta := TEMPO_CONTAGEM - tempo_estado
			mensagem(str(ceili(falta)))
			if falta <= 0.0:
				comecar()
		Estado.JOGANDO:
			if tempo_estado < 0.8:
				mensagem("VAI!")
			elif prorrogacao and tempo_estado < 3.0:
				mensagem("PRORROGAÇÃO\nquem fizer o próximo gol ganha")
			else:
				mensagem("")
			if not prorrogacao:
				relogio = maxf(relogio - delta, 0.0)
			ver_demolicoes()
			ver_gol()
			if estado == Estado.JOGANDO and relogio <= 0.0 and not prorrogacao:
				acabar_tempo()
		Estado.GOL:
			if tempo_estado >= TEMPO_COMEMORACAO:
				if acabou:
					fim_de_jogo()
				else:
					saida_de_bola()
		Estado.FIM:
			if Input.is_action_just_pressed("ui_accept"):
				nova_partida()
	atualizar_placar()
	if Rede.modo == "host":
		if Engine.get_physics_frames() % 2 == 0:
			var estado_agora := montar_estado(comandos_do_estado)
			Rede.enviar(func() -> void: Rede.receber_estado.rpc(estado_agora))
		tempo_ajustes += delta
		if tempo_ajustes >= TEMPO_AJUSTES:
			tempo_ajustes = 0.0
			var ajustes := ajustes_atuais()
			Rede.enviar(func() -> void: Rede.receber_ajustes.rpc(ajustes))


func ver_gol() -> void:
	var b := bola.global_position
	if absf(b.x) > Arena.GOL_LARGURA / 2.0 or b.y > Arena.GOL_ALTURA or absf(b.z) < Arena.COMPRIMENTO / 2.0 + RAIO_BOLA:
		return
	var time := "azul" if b.z < 0.0 else "laranja"
	explodir_gol(b, time)
	placar[time] += 1
	acabou = prorrogacao
	estado = Estado.GOL
	tempo_estado = 0.0
	mensagem("GOL DO %s!" % time.to_upper())
	bola.visible = false
	bola.freeze = true


func explodir_gol(onde: Vector3, time: String) -> void:
	var forca := clampf(bola.linear_velocity.length() / 30.0, 0.5, 1.4)
	nova_explosao(onde, Arena.COR_AZUL if time == "azul" else Arena.COR_LARANJA, 2.5 * forca)
	for c in carros.values():
		if c.explodido:
			continue
		var dif: Vector3 = c.global_position - onde
		var distancia := dif.length()
		if distancia > RAIO_EXPLOSAO_GOL:
			continue
		var perto := 1.0 - distancia / RAIO_EXPLOSAO_GOL
		var direcao := (dif.normalized() + Vector3.UP * 0.5).normalized()
		c.linear_velocity += direcao * EMPURRAO_GOL * forca * perto
		c.angular_velocity += Vector3(randf_range(-3, 3), randf_range(-3, 3), randf_range(-3, 3)) * perto


func ver_demolicoes() -> void:
	# de frente com os dois supersônicos, explodem os dois (por isso junta primeiro e explode depois)
	var demolir := []
	for id in carros:
		var a: RigidBody3D = carros[id]
		var antes: Array = velocidades_antes.get(id, [Vector3.ZERO, false])
		if a.explodido or not antes[1]:
			continue
		for outro in a.get_colliding_bodies():
			var id_outro = carros.find_key(outro)
			if id_outro == null or times.get(id_outro) == times.get(id) or outro.explodido:
				continue
			var para_ele: Vector3 = (outro.global_position - a.global_position).normalized()
			if antes[0].dot(para_ele) > VELOCIDADE_DEMOLIR and not demolir.has(id_outro):
				demolir.append(id_outro)
	for id in demolir:
		var c: RigidBody3D = carros[id]
		nova_explosao(c.global_position, Arena.COR_AZUL if times[id] == "azul" else Arena.COR_LARANJA, 1.0)
		c.explodir()
		voltam_em[id] = tempo_total + TEMPO_DEMOLIDO
	velocidades_antes.clear()
	for id in carros:
		velocidades_antes[id] = [carros[id].linear_velocity, carros[id].supersonico]


func reviver_demolidos() -> void:
	for id in voltam_em.keys():
		if not carros.has(id):
			voltam_em.erase(id)
		elif tempo_total >= voltam_em[id]:
			voltam_em.erase(id)
			carros[id].reviver()
			colocar_na_saida(carros[id], times[id], VOLTAS.pick_random())


func nova_explosao(onde: Vector3, cor: Color, tamanho: float) -> void:
	numero_explosao += 1
	explosoes.append([numero_explosao, onde, cor, tamanho])
	if explosoes.size() > 4:
		explosoes.pop_front()
	Explosao.criar(get_parent(), onde, cor, tamanho)


func acabar_tempo() -> void:
	if placar["azul"] == placar["laranja"]:
		prorrogacao = true
		tempo_estado = 0.0
	else:
		fim_de_jogo()


func fim_de_jogo() -> void:
	estado = Estado.FIM
	tempo_estado = 0.0
	for c in carros.values():
		c.travado = true
	var vencedor := "o Azul venceu!" if placar["azul"] > placar["laranja"] else "o Laranja venceu!"
	var de_novo := "O host aperta Enter pra jogar de novo" if Rede.online() else "Enter: jogar de novo"
	mensagem("FIM DE JOGO\nAzul %d × %d Laranja: %s\n%s" % [placar["azul"], placar["laranja"], vencedor, de_novo])


func nova_partida() -> void:
	placar = {"azul": 0, "laranja": 0}
	relogio = TEMPO_PARTIDA
	prorrogacao = false
	acabou = false
	saida_de_bola()


func saida_de_bola() -> void:
	var lugares := SAIDAS.duplicate()
	lugares.shuffle()
	var quantos := {"azul": 0, "laranja": 0}
	voltam_em.clear()
	for id in carros:
		var time: String = times[id]
		if carros[id].explodido:
			carros[id].reviver()
		colocar_na_saida(carros[id], time, lugares[quantos[time] % lugares.size()])
		quantos[time] += 1
		carros[id].travado = true
	bola.freeze = true
	bola.global_transform = Transform3D(Basis(), Vector3.UP * RAIO_BOLA)
	bola.linear_velocity = Vector3.ZERO
	bola.angular_velocity = Vector3.ZERO
	bola.visible = true
	estado = Estado.CONTAGEM
	tempo_estado = 0.0


func colocar_na_saida(quem: RigidBody3D, time: String, lugar: Vector3) -> void:
	var posicao := lugar if time == "azul" else Vector3(-lugar.x, 0, -lugar.z)
	posicao.y = ALTURA_CARRO
	var para_bola := Vector3(-posicao.x, 0, -posicao.z)
	quem.colocar_em(Transform3D(Basis.looking_at(para_bola), posicao))
	quem.boost = BOOST_SAIDA


func comecar() -> void:
	for c in carros.values():
		c.travado = false
	bola.freeze = false
	estado = Estado.JOGANDO
	tempo_estado = 0.0


func jogador_entrou(id: int) -> void:
	var novo: RigidBody3D = CENA_CARRO.instantiate()
	novo.name = "Carro_%d" % id
	novo.controle_local = false
	get_parent().add_child(novo)
	copiar_ajustes(carro, novo)
	var no_azul := times.values().count("azul")
	var time := "laranja" if no_azul > times.values().count("laranja") else "azul"
	times[id] = time
	carros[id] = novo
	novo.definir_time(time)
	colocar_na_saida(novo, time, SAIDAS[(times.values().count(time) - 1) % SAIDAS.size()])
	novo.travado = estado == Estado.CONTAGEM or estado == Estado.FIM
	var ajustes := ajustes_atuais()
	Rede.enviar(func() -> void: Rede.receber_ajustes.rpc_id(id, ajustes))


func adicionar_bot(nivel: int) -> void:
	# um adversário no laranja, dirigido pelo Bot (que aperta os comandos como um jogador)
	var novo: RigidBody3D = CENA_CARRO.instantiate()
	novo.name = "Carro_bot"
	novo.controle_local = false
	novo.position = Vector3(0, ALTURA_CARRO, -42)
	get_parent().add_child(novo)
	copiar_ajustes(carro, novo)
	times[ID_BOT] = "laranja"
	carros[ID_BOT] = novo
	novo.definir_time("laranja")
	colocar_na_saida(novo, "laranja", SAIDAS[0])
	novo.travado = estado == Estado.CONTAGEM or estado == Estado.FIM
	var bot := Bot.new()
	bot.carro = novo
	bot.bola = bola
	bot.nivel = nivel
	bot.lado = -1.0
	add_child(bot)


func jogador_saiu(id: int) -> void:
	if carros.has(id):
		carros[id].queue_free()
		carros.erase(id)
		times.erase(id)
		fila_comandos.erase(id)
		comando_usado.erase(id)


func comandos_chegaram(id: int, dados: Array) -> void:
	if not carros.has(id) or dados.size() != 8:
		return
	var fila: Array = fila_comandos.get_or_add(id, [])
	if fila.is_empty() or dados[0] > fila[-1][0]:
		fila.append(dados)


func usar_comandos_da_fila() -> void:
	for id in fila_comandos:
		var fila: Array = fila_comandos[id]
		# se juntou demais (a internet travou e depois chegou tudo), pula os velhos;
		# um pulo apertado no meio não se perde: o comando conta quantas vezes apertou
		while fila.size() > FILA_MAXIMA:
			fila.pop_front()
		if fila.is_empty():
			continue   # nada novo: o carro segue com o último comando
		var dados: Array = fila.pop_front()
		carros[id].comandos.de_rede(dados.slice(1))
		comando_usado[id] = dados[0]


func ajustes_atuais() -> Dictionary:
	var ajustes := {"gravidade": PhysicsServer3D.area_get_param(get_viewport().find_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY)}
	for propriedade in carro.get_property_list():
		var uso: int = propriedade["usage"]
		if uso & PROPERTY_USAGE_SCRIPT_VARIABLE and uso & PROPERTY_USAGE_STORAGE:
			ajustes[propriedade["name"]] = carro.get(propriedade["name"])
	return ajustes


func aplicar_ajustes(ajustes: Dictionary) -> void:
	# quem entrou calcula o próprio carro igualzinho ao host
	for nome in ajustes:
		if nome == "gravidade":
			PhysicsServer3D.area_set_param(get_viewport().find_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY, ajustes[nome])
		elif nome in carro:
			carro.set(nome, ajustes[nome])


func copiar_ajustes(de: RigidBody3D, para: RigidBody3D) -> void:
	# os ajustes do carro (os do painel F1) valem pra todo mundo: são os do host
	for propriedade in de.get_property_list():
		var uso: int = propriedade["usage"]
		if uso & PROPERTY_USAGE_SCRIPT_VARIABLE and uso & PROPERTY_USAGE_STORAGE:
			para.set(propriedade["name"], de.get(propriedade["name"]))


func montar_estado(comandos_do_estado: Dictionary) -> Array:
	var lista := []
	for id in carros:
		var c: RigidBody3D = carros[id]
		lista.append([id, times[id], c.global_position, c.global_basis.get_rotation_quaternion(), c.linear_velocity, c.boost, c.boostando, c.supersonico, c.comandos.direcao, c.angular_velocity, comandos_do_estado.get(id, -1), c.travado, c.explodido])
	var acesos := 0
	for i in pads.size():
		if pads[i]["brilho"].visible:
			acesos |= 1 << i
	var dados_bola := [bola.global_position, bola.global_basis.get_rotation_quaternion(), bola.linear_velocity, bola.visible]
	return [Engine.get_physics_frames(), lista, dados_bola, texto_placar, hud.get_node("Mensagem").text, acesos, explosoes]


func estado_chegou(dados: Array) -> void:
	if not estados_recebidos.is_empty() and dados[0] <= estados_recebidos[-1][0]:
		return
	var primeiro := estados_recebidos.is_empty()
	estados_recebidos.append(dados)
	if estados_recebidos.size() > 30:
		estados_recebidos.pop_front()
	# explosões novas (as de antes de eu entrar não aparecem)
	for e in dados[6]:
		if e[0] > explosao_vista:
			explosao_vista = e[0]
			if not primeiro:
				Explosao.criar(get_parent(), e[1], e[2], e[3])
	corrigir_meu_carro(dados)


func corrigir_meu_carro(dados: Array) -> void:
	var eu := multiplayer.get_unique_id()
	for meu in dados[1]:
		if meu[0] != eu:
			continue
		carro.travado = meu[11]
		if meu[12] != carro.explodido:
			if meu[12]:
				carro.explodir()
			else:
				carro.reviver()
		var numero: int = meu[10]
		if not historico.has(numero):
			return
		# compara o que o host calculou com o que eu calculei pro mesmo comando
		var antes: Array = historico[numero]
		var erro: Vector3 = meu[2] - antes[0]
		erros_medidos.append(erro.length())
		var de_uma_vez := erro.length() > ERRO_TELEPORTE
		var fracao := 1.0 if de_uma_vez else FRACAO_CORRECAO
		var posicao := erro * fracao
		var rotacao := Quaternion.IDENTITY.slerp(meu[3] * antes[1].inverse(), fracao)
		var velocidade: Vector3 = (meu[4] - antes[2]) * fracao
		var giro: Vector3 = (meu[9] - antes[3]) * fracao
		var boost: float = (meu[5] - antes[4]) * fracao
		carro.corrigir(posicao, rotacao, velocidade, giro, de_uma_vez)
		carro.boost = clampf(carro.boost + boost, 0.0, 100.0)
		# o que eu calculei depois desse comando anda junto com a correção
		for n in historico.keys():
			if n < numero:
				historico.erase(n)
				continue
			var h: Array = historico[n]
			h[0] += posicao
			h[1] = rotacao * h[1]
			h[2] += velocidade
			h[3] += giro
			h[4] += boost
		return


func mostrar_estado() -> void:
	if estados_recebidos.is_empty():
		return
	var alvo: float = estados_recebidos[-1][0] - ATRASO_IMAGEM
	if quadro_imagem < 0.0 or absf(quadro_imagem - alvo) > 60.0:
		quadro_imagem = alvo
	else:
		# anda um quadro por quadro, corrigindo devagar pra não dar tranco
		quadro_imagem += 1.0 + clampf((alvo - quadro_imagem) * 0.05, -0.5, 0.5)
	var a: Array = estados_recebidos[0]
	var b: Array = []
	for e in estados_recebidos:
		if e[0] <= quadro_imagem:
			a = e
		else:
			b = e
			break
	if b.is_empty():
		b = a
	var t := 0.0 if b[0] == a[0] else clampf((quadro_imagem - a[0]) / float(b[0] - a[0]), 0.0, 1.0)
	aplicar_estado(a, b, t)


func aplicar_estado(a: Array, b: Array, t: float) -> void:
	var em_b := {}
	for dados in b[1]:
		em_b[dados[0]] = dados
	var presentes := {}
	var eu := multiplayer.get_unique_id()
	for da in a[1]:
		var id: int = da[0]
		if id == eu:
			carro_do_jogador(id, da[1])   # só pra saber o meu time (cor e placar)
			presentes[id] = true   # a posição do meu carro eu calculo na hora (e corrijo em corrigir_meu_carro)
			continue
		var db: Array = em_b.get(id, da)
		var c := carro_do_jogador(id, db[1])
		if db[12] != c.explodido:
			if db[12]:
				c.explodir()
			else:
				c.reviver()
		var posicao: Vector3 = da[2].lerp(db[2], t)
		var pulou_longe := c.global_position.distance_to(posicao) > 5.0
		c.global_transform = Transform3D(Basis(da[3].slerp(db[3], t)), posicao)
		if pulou_longe:
			c.reset_physics_interpolation()   # saída de bola: aparece no lugar novo sem deslizar
		c.velocidade_rede = da[4].lerp(db[4], t)
		c.boost = db[5]
		c.boostando = db[6]
		c.supersonico = db[7]
		if not c.controle_local:
			c.comandos.direcao = db[8]
		presentes[id] = true
	for id in carros.keys():
		if not presentes.has(id) and carros[id] != carro:
			carros[id].queue_free()
			carros.erase(id)
			times.erase(id)

	var ba: Array = a[2]
	var bb: Array = b[2]
	var posicao_bola: Vector3 = ba[0].lerp(bb[0], t)
	var bola_pulou := bola.global_position.distance_to(posicao_bola) > 5.0
	bola.global_transform = Transform3D(Basis(ba[1].slerp(bb[1], t)), posicao_bola)
	if bola_pulou:
		bola.reset_physics_interpolation()
	bola.velocidade_rede = ba[2].lerp(bb[2], t)
	bola.visible = bb[3]

	texto_placar = b[3]
	hud.get_node("Placar").text = texto_placar + linha_do_time()
	mensagem(b[4])
	for i in pads.size():
		pads[i]["brilho"].visible = b[5] & (1 << i) != 0


func carro_do_jogador(id: int, time: String) -> RigidBody3D:
	if not carros.has(id):
		var novo: RigidBody3D = CENA_CARRO.instantiate()
		novo.name = "Carro_%d" % id
		novo.controle_local = false
		get_parent().add_child(novo)
		novo.definir_simulacao(false)
		carro.add_collision_exception_with(novo)
		carros[id] = novo
	if times.get(id, "") != time:
		times[id] = time
		carros[id].definir_time(time)
	return carros[id]


func linha_do_time() -> String:
	if Rede.modo == "sozinho" and Rede.bot >= 0:
		return "\ncontra o bot · %s" % Bot.NIVEIS[Rede.bot]
	if not Rede.online():
		return ""
	var meu: String = times.get(multiplayer.get_unique_id(), "")
	return "\ntu: %s" % meu.capitalize() if meu != "" else ""


func criar_pad(onde: Vector2, grande: bool) -> void:
	var raiz := Node3D.new()
	raiz.position = Vector3(onde.x, 0.0, onde.y)
	var malhas := malhas_do_pad(grande)
	var base := MeshInstance3D.new()
	base.mesh = malhas[0]
	var brilho := MeshInstance3D.new()
	brilho.mesh = malhas[1]
	brilho.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var orbe: MeshInstance3D = null
	if grande:
		orbe = MeshInstance3D.new()
		orbe.mesh = malhas[2]
		orbe.position.y = 1.0
		orbe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		brilho.add_child(orbe)
	raiz.add_child(base)
	raiz.add_child(brilho)
	add_child(raiz)
	pads.append({
		"onde": onde,
		"raio": 2.0 if grande else 1.3,
		"quanto": 100.0 if grande else 12.0,
		"espera": 10.0 if grande else 4.0,
		"volta_em": 0.0,
		"brilho": brilho,
		"orbe": orbe,
	})


func malhas_do_pad(grande: bool) -> Array:
	# [base, anel aceso, esfera do pad grande]: montadas uma vez só pra cada tamanho
	# (montar as 34 uma por uma deixava o carregamento do site uns segundos mais lento)
	if malhas_dos_pads.has(grande):
		return malhas_dos_pads[grande]
	# base de metal com borda e um anel aceso (o anel apaga junto quando o pad é pego)
	var r := 1.6 if grande else 0.9
	var metal := Modelagem.nova()
	Modelagem.torno(metal, [Vector2(r, 0.0), Vector2(r, 0.05), Vector2(r - 0.12, 0.07), Vector2(r * 0.72, 0.06), Vector2(0.0, 0.05)], 32)
	var malha_base := ArrayMesh.new()
	Modelagem.adicionar(malha_base, metal, "base", Materiais.liso(Color(0.16, 0.17, 0.19), 0.35, Color.BLACK, 0.0, 0.7))
	var aceso := Modelagem.nova()
	Modelagem.torno(aceso, [Vector2(r * 0.7, 0.072), Vector2(r * 0.58, 0.072)], 32)
	if not grande:
		Modelagem.torno(aceso, [Vector2(0.4, 0.075), Vector2(0.0, 0.075)], 24)
	var luz := Materiais.luz(Color(1.0, 0.55, 0.12), 3.0)
	var malha_brilho := ArrayMesh.new()
	Modelagem.adicionar(malha_brilho, aceso, "brilho", luz)
	var malha_orbe: ArrayMesh = null
	if grande:
		# esfera de energia flutuando em cima do pad grande
		var bola_de_luz := Modelagem.nova()
		Modelagem.torno(bola_de_luz, esfera(0.5, 12), 20)
		malha_orbe = ArrayMesh.new()
		Modelagem.adicionar(malha_orbe, bola_de_luz, "orbe", luz)
	malhas_dos_pads[grande] = [malha_base, malha_brilho, malha_orbe]
	return malhas_dos_pads[grande]


func esfera(raio: float, fatias: int) -> Array:
	# perfil de meia esfera pro Modelagem.torno (de baixo pra cima, lado de fora à direita)
	var perfil := []
	for k in fatias + 1:
		var a := PI * k / fatias - PI / 2.0
		perfil.append(Vector2(cos(a) * raio, sin(a) * raio))
	return perfil


func atualizar_pads() -> void:
	var agora := Time.get_ticks_msec() / 1000.0
	for pad in pads:
		var ativo: bool = tempo_total >= pad["volta_em"]
		pad["brilho"].visible = ativo
		if pad["orbe"]:
			pad["orbe"].position.y = 1.0 + 0.12 * sin(agora * 2.5)
		if not ativo:
			continue
		for c in carros.values():
			var p: Vector3 = c.global_position
			if c.boost >= 100.0 or p.y > 2.5 or c.explodido:
				continue
			if Vector2(p.x, p.z).distance_to(pad["onde"]) < pad["raio"]:
				c.boost = minf(c.boost + pad["quanto"], 100.0)
				pad["volta_em"] = tempo_total + pad["espera"]
				break


func mensagem(texto: String) -> void:
	hud.get_node("Mensagem").text = texto


func atualizar_placar() -> void:
	var tempo := "PRORROGAÇÃO" if prorrogacao else "%d:%02d" % [floori(ceilf(relogio) / 60.0), int(ceilf(relogio)) % 60]
	texto_placar = "AZUL  %d  ×  %d  LARANJA\n%s" % [placar["azul"], placar["laranja"], tempo]
	hud.get_node("Placar").text = texto_placar + linha_do_time()
