class_name Bot
extends Node

# Bot do "Jogar solo": aperta os mesmos comandos que um jogador (acelerar, virar, freio de mão, boost,
# pulo, mortal) — não tem nenhuma vantagem de física. Joga no laranja (defende o gol do -Z).
#   Fácil: reage atrasado, não usa boost, só corre atrás da bola.
#   Médio: prevê a bola, se posiciona atrás dela pra chutar pro gol, volta pra defender, boost em reta
#          longa, pula em bola alta.
#   Difícil: o mesmo com previsão melhor, mais boost e mortal na bola quando chega perto.

const NIVEIS := ["Fácil", "Médio", "Difícil"]
const ACELERADOR := [0.8, 1.0, 1.0]
const PREVISAO := [0.0, 0.6, 1.0]          # quanto olha pra frente na trajetória da bola
const BOOST_A_PARTIR_DE := [INF, 14.0, 5.0]   # m até o alvo pra valer a pena usar boost
const VIRAR := [1.8, 2.5, 3.0]             # quão forte corrige a direção

var carro: RigidBody3D
var bola: RigidBody3D
var nivel := 1
var lado := -1.0           # z do gol que o bot defende (÷ 50)
var alvo_lento := Vector3.ZERO
var pulo_etapa := 0        # 0 nada · 1 segurando o pulo · 2 esperando pra dar o mortal · 3 no ar
var tempo_pulo := 0.0
var segurar_pulo := 0.2
var vai_dar_mortal := false
var tempo_parado := 0.0
var tempo_de_re := 0.0
var tempo_virado := 0.0


func _ready() -> void:
	process_physics_priority = -1   # decide antes do carro ler os comandos


func _physics_process(dt: float) -> void:
	var c: Comandos = carro.comandos
	c.acelerador = 0.0
	c.direcao = 0.0
	c.inclinar = 0.0
	c.rolar = 0.0
	c.boost = false
	c.freio_mao = false
	c.pulo = false
	if carro.explodido:
		return

	var meu := carro.global_position
	var velocidade: float = carro.linear_velocity.length()
	var gol_dele := Vector3(0, 0, -lado * Arena.COMPRIMENTO / 2.0)
	var meu_gol := Vector3(0, 0, lado * Arena.COMPRIMENTO / 2.0)

	# onde a bola vai estar quando eu chegar (só pra frente, sem contar quique)
	var distancia_bola := meu.distance_to(bola.global_position)
	var t: float = clampf(distancia_bola / maxf(velocidade, 10.0), 0.0, 1.2) * PREVISAO[nivel]
	var bola_futura: Vector3 = bola.global_position + bola.linear_velocity * t
	bola_futura.x = clampf(bola_futura.x, -Arena.LARGURA / 2.0 + 2.0, Arena.LARGURA / 2.0 - 2.0)
	bola_futura.z = clampf(bola_futura.z, -Arena.COMPRIMENTO / 2.0 + 1.0, Arena.COMPRIMENTO / 2.0 - 1.0)

	# pra onde chutar: da bola pro gol dele
	var para_gol: Vector3 = gol_dele - bola_futura
	para_gol.y = 0.0
	para_gol = para_gol.normalized()
	var ate_bola: Vector3 = bola_futura - meu
	ate_bola.y = 0.0
	var alinhado: bool = ate_bola.normalized().dot(para_gol) > 0.55
	# a bola está entre mim e o meu gol, e do meu lado do campo: volto pra defender pelo lado
	# (no campo dele, passar da bola não é perigo: só dá a volta nela)
	var defendendo: bool = nivel >= 1 and (bola_futura.z - meu.z) * lado > 3.0 and bola_futura.z * lado > -10.0

	var alvo: Vector3
	if nivel == 0 or alinhado:
		alvo = bola_futura
	elif defendendo:
		alvo = meu_gol.lerp(bola_futura, 0.3)
		alvo.x += 6.0 * signf(meu.x - bola_futura.x)   # passa pelo lado, não por cima da bola
		if meu.distance_to(alvo) < 5.0:
			alvo = bola_futura
	else:
		# mira num ponto atrás da bola que vai chegando nela conforme o bot se aproxima: assim a curva
		# sempre fecha (com um ponto fixo a 3 m ele passava do ponto e ficava orbitando a bola)
		alvo = bola_futura - para_gol * clampf(ate_bola.length() * 0.4, 0.0, 9.0)
	if nivel == 0:
		alvo_lento = alvo_lento.lerp(alvo, minf(dt * 2.0, 1.0))   # reage atrasado
		alvo = alvo_lento
	else:
		alvo_lento = alvo

	dirigir_para(c, alvo, dt, velocidade)
	pular(c, dt, ate_bola, alinhado, velocidade)


func dirigir_para(c: Comandos, alvo: Vector3, dt: float, velocidade: float) -> void:
	var frente := -carro.global_basis.z
	frente.y = 0.0
	var para_alvo := alvo - carro.global_position
	para_alvo.y = 0.0
	var angulo := 0.0
	if frente.length() > 0.1 and para_alvo.length() > 0.1:
		angulo = frente.normalized().signed_angle_to(para_alvo.normalized(), Vector3.UP)
	c.direcao = clampf(-angulo * VIRAR[nivel], -1.0, 1.0)
	c.acelerador = ACELERADOR[nivel]
	if absf(angulo) > 1.0 and para_alvo.length() < 10.0:
		c.acelerador *= 0.5   # curva fechada perto do alvo: tira o pé pra não passar reto
	c.freio_mao = absf(angulo) > 1.4 and velocidade > 8.0 and carro.rodas_no_chao >= 3
	c.boost = absf(angulo) < 0.25 and para_alvo.length() > BOOST_A_PARTIR_DE[nivel] and carro.boost > 0.0
	# preso (na parede, no gol, em outro carro): dá ré virando pro outro lado
	if velocidade < 1.0 and carro.rodas_no_chao >= 3 and not carro.travado:
		tempo_parado += dt
	else:
		tempo_parado = 0.0
	if tempo_parado > 1.2:
		tempo_de_re = 0.8
		tempo_parado = 0.0
	if tempo_de_re > 0.0:
		tempo_de_re -= dt
		c.acelerador = -1.0
		c.direcao = -c.direcao
		c.boost = false


func pular(c: Comandos, dt: float, ate_bola: Vector3, alinhado: bool, velocidade: float) -> void:
	var no_chao: bool = carro.rodas_no_chao >= 3
	# virado de rodas pra cima: pulo desvira
	if carro.global_basis.y.dot(Vector3.UP) < 0.2 and velocidade < 3.0:
		tempo_virado += dt
		if tempo_virado > 0.6:
			c.pulos += 1
			tempo_virado = 0.0
		return
	tempo_virado = 0.0

	var altura_bola := bola.global_position.y
	var perto := ate_bola.length() < 2.5 + velocidade * 0.12
	if pulo_etapa == 0 and no_chao and perto and not carro.travado:
		if nivel >= 1 and altura_bola > 2.2 and altura_bola < 5.5:
			comecar_pulo(c, clampf((altura_bola - 1.5) * 0.12, 0.05, 0.2), false)
		elif nivel == 2 and altura_bola < 2.0 and alinhado and velocidade > 9.0 and ate_bola.length() < 4.0:
			comecar_pulo(c, 0.05, true)

	match pulo_etapa:
		1:
			c.pulo = true
			tempo_pulo += dt
			if tempo_pulo >= segurar_pulo:
				pulo_etapa = 2 if vai_dar_mortal else 3
				tempo_pulo = 0.0
		2:
			tempo_pulo += dt
			if tempo_pulo >= 0.06:
				# mortal pra frente na bola
				c.inclinar = 1.0
				c.pulos += 1
				c.pulo = true
				pulo_etapa = 3
				tempo_pulo = 0.0
		3:
			tempo_pulo += dt
			if no_chao and tempo_pulo > 0.3:
				pulo_etapa = 0


func comecar_pulo(c: Comandos, segurar: float, mortal: bool) -> void:
	c.pulos += 1
	c.pulo = true
	pulo_etapa = 1
	tempo_pulo = 0.0
	segurar_pulo = segurar
	vai_dar_mortal = mortal
