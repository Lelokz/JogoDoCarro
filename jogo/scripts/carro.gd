extends RigidBody3D

# Valores de partida: números do RocketSim/RLBot convertidos de cm pra metros.
# São pra ajustar jogando no painel F1.

@export_group("Suspensão")
@export var mola := 8000.0          # N/m em cada roda
@export var amortecedor := 3000.0   # N·s/m em cada roda
@export var curso_mola := 0.12      # m
@export var raio_roda := 0.17       # m
@export var batente := 20000.0      # N/m a mais quando a mola passa do curso (pouso não bate seco)
@export var grude := 3.25           # m/s² puxando o carro contra o chão enquanto as rodas tocam

@export_group("Direção")
@export var forca_motor := 1.0            # multiplica a tabela ACELERACAO
@export var multiplicador_curva := 1.3   # multiplica a tabela CURVATURA (os padrões daqui são os ajustes dele no F1: o site não lê o ajustes/carro.json)
@export var freio := 35.0                 # m/s²
@export var desaceleracao_solto := 5.25   # m/s², sem acelerar nem frear
@export var velocidade_maxima := 23.0     # m/s
@export var aderencia := 54.0             # m/s² que os pneus seguram de lado
@export var aderencia_freio_mao := 8.0
@export var giro_freio_mao := 1.3         # vira quanto a mais no freio de mão
@export var volta_aderencia := 0.6        # s pro pneu voltar a agarrar depois de soltar o freio de mão
@export var endireitar := 2.0             # quanto o carro gira sozinho pra apontar pra onde está indo
@export var angulo_visual_roda := 0.45    # rad, só a roda desenhada

@export_group("Pulo")
@export var forca_pulo := 2.92            # m/s na hora que aperta
@export var forca_segurando := 14.58      # m/s² enquanto segura o botão
@export var tempo_segurando := 0.2        # s que segurar ainda ajuda
@export var janela_pulo_extra := 1.25     # s depois do pulo pra usar o duplo pulo ou o mortal
@export var forca_mortal := 5.0           # m/s do empurrão do mortal
@export var duracao_mortal := 0.65        # s pra dar a volta inteira no mortal

@export_group("Ar e boost")
@export var controle_no_ar := 1.0         # multiplica a força de girar no ar
@export var aceleracao_boost := 9.92      # m/s² no chão (no ar é 6,7% a mais)
@export var gasto_boost := 33.3           # por segundo (tanque de 100 dura 3 s)
@export var recarga_boost := 0.0          # por segundo; o campo de teste liga isso

# [velocidade m/s, aceleração m/s²]: acelera forte parado e quase nada perto de 14,1
const ACELERACAO := [[0.0, 16.0], [14.0, 1.6], [14.1, 0.0]]
const ENTRADA_DERRAPAGEM := 0.1   # s pro pneu soltar quando aperta o freio de mão
# [velocidade m/s, curvatura 1/m]: quanto mais rápido, mais aberta a curva
const CURVATURA := [[0.0, 0.69], [5.0, 0.398], [10.0, 0.235], [15.0, 0.1375], [17.5, 0.11], [25.0, 0.088]]
const PULO_MINIMO := 0.025                          # s: até um toque rápido pula um pouco
const GIRO_NO_AR := Vector3(12.46, 9.11, 38.34)     # rad/s²: inclinar, virar, rolar
const AMORTECE_NO_AR := Vector3(2.88, 1.92, 4.79)   # para de girar sozinho quando solta
const GIRO_MAXIMO := 5.5                            # rad/s
const ACELERACAO_NO_AR := 0.667                     # m/s² acelerando no ar
const BOOST_MINIMO := 0.1                           # s: um toque no boost dura pelo menos isso
const SUPERSONICO := 22.0                           # m/s
const VELOCIDADE_REFERENCIA := 23.0                 # m/s: base do empurrão do mortal

@onready var rodas: Array[Node3D] = [$RodaFE, $RodaFD, $RodaTE, $RodaTD]

var compressao := [0.0, 0.0, 0.0, 0.0]
var rodas_no_chao := 0
var normal_chao := Vector3.UP
var derrapagem := 0.0   # 0 = pneu agarrando, 1 = freio de mão inteiro
var giro_pneu := 0.0
var ponto_inicial: Transform3D
var pedido_desvirar := false
var pedido_voltar := false
var pedido_pulo := false
var travado := false   # parado na contagem da saída de bola

# multiplayer: quem joga aqui lê o teclado; o host simula todos os carros;
# quem entrou numa partida só mostra os carros na posição que o host manda
var comandos := Comandos.new()
var controle_local := true
var simulando := true
var velocidade_rede := Vector3.ZERO
var pulos_vistos := -1
# quem entrou numa partida: diferença pro que o host calculou, aplicada no próximo passo da física
var correcao_posicao := Vector3.ZERO
var correcao_rotacao := Quaternion.IDENTITY
var correcao_velocidade := Vector3.ZERO
var correcao_giro := Vector3.ZERO
var tem_correcao := false
var resetar_interpolacao := false
var desviradas_vistas := -1

var boost := 100.0
var boostando := false
var tempo_boost_minimo := 0.0
var supersonico := false
var pulando := false
var tempo_pulo := 0.0
var pulou := false
var pulo_extra_usado := false
var tempo_no_ar_pos_pulo := 0.0
var tempo_mortal := -1.0   # -1 = não está no mortal
var direcao_mortal := Vector2.ZERO
var tempo_desvirando := 0.0
var eixo_desvirar := Vector3.ZERO
var rastro: CPUParticles3D
var teleportou := true   # quadro depois de um teleporte (e de nascer): a mola mudar de uma vez não conta como pancada
var explodido := false   # demolido: some por uns segundos e volta perto do próprio gol
var tinta := ModeloCarro.pintura(Color(0.2, 0.45, 0.95))   # cada carro tem a sua (cor do time)
var turbina := ModeloCarro.turbina()                      # e a sua turbina (acende no boost)
var detalhe := Materiais.liso(Color(0.78, 0.8, 0.84), 0.22, Color.BLACK, 0.0, 0.9)   # rodas e enfeite
var enfeite := MeshInstance3D.new()
var aparencia := Aparencia.PADRAO.duplicate()   # o que o dono escolheu no Personalizar


func _ready() -> void:
	add_to_group("carros")
	ponto_inicial = global_transform
	# cada carro com a sua caixa de batida (o modelo muda o tamanho dela)
	$Forma.shape = BoxShape3D.new()
	inertia = ModeloCarro.INERCIA
	$Corpo.add_child(enfeite)
	criar_rastro()
	vestir(aparencia)
	# pra partida saber em quem o carro bateu (demolição)
	contact_monitor = true
	max_contacts_reported = 4


func _physics_process(delta: float) -> void:
	if resetar_interpolacao:
		reset_physics_interpolation()
		resetar_interpolacao = false
	if controle_local:
		comandos.ler_teclado()
	if simulando:
		if pulos_vistos >= 0 and comandos.pulos != pulos_vistos:
			pedido_pulo = true
		pulos_vistos = comandos.pulos
		# desvirar e voltar pro início são só pra treino: online seria roubo
		if desviradas_vistas >= 0 and comandos.desviradas != desviradas_vistas and not Rede.online():
			pedido_desvirar = true
		desviradas_vistas = comandos.desviradas
		if controle_local and not Rede.online() and Input.is_action_just_pressed("voltar_inicio"):
			pedido_voltar = true
	else:
		estimar_rodas()
	rastro.emitting = boostando
	turbina.set_shader_parameter("forca_brilho", 4.0 if boostando else 0.5)
	atualizar_rodas_desenhadas(delta)


func _integrate_forces(estado: PhysicsDirectBodyState3D) -> void:
	if pedido_voltar or pedido_desvirar:
		reposicionar(estado)
		return

	if tem_correcao:
		aplicar_correcao(estado)
	var dt := estado.step
	ler_suspensao(estado, dt)
	if travado:
		estado.linear_velocity = Vector3.ZERO
		estado.angular_velocity = Vector3.ZERO
		return
	var no_chao := rodas_no_chao >= 3
	if no_chao and not pulando and (not pulou or tempo_no_ar_pos_pulo > 0.0):
		pulou = false
		pulo_extra_usado = false
		tempo_mortal = -1.0
	atualizar_boost(dt)

	if pedido_pulo:
		pedido_pulo = false
		apertou_pulo(estado, no_chao)
	segurar_pulo(estado, dt)

	if rodas_no_chao > 0:
		dirigir(estado, dt)
	elif tempo_mortal >= 0.0:
		girar_mortal(estado, dt)
	else:
		controlar_no_ar(estado, dt)

	if tempo_desvirando > 0.0:
		estado.angular_velocity = eixo_desvirar * GIRO_MAXIMO
		tempo_desvirando -= dt
	if boostando:
		var no_ar := 1.0 if rodas_no_chao > 0 else 1.067
		estado.linear_velocity += -estado.transform.basis.z * aceleracao_boost * no_ar * dt

	var velocidade := estado.linear_velocity.length()
	supersonico = velocidade >= SUPERSONICO or (supersonico and velocidade >= SUPERSONICO - 1.0)
	estado.linear_velocity = estado.linear_velocity.limit_length(velocidade_maxima)
	if not girando_mortal():
		estado.angular_velocity = estado.angular_velocity.limit_length(GIRO_MAXIMO)


func ler_suspensao(estado: PhysicsDirectBodyState3D, dt: float) -> void:
	var cima := estado.transform.basis.y
	var espaco := estado.get_space_state()
	var alcance := curso_mola + raio_roda
	var soma_normais := Vector3.ZERO
	rodas_no_chao = 0

	for i in 4:
		var origem := estado.transform * rodas[i].position
		var consulta := PhysicsRayQueryParameters3D.create(origem, origem - cima * alcance, collision_mask, [get_rid()])
		var toque := espaco.intersect_ray(consulta)
		var anterior: float = compressao[i]
		if toque.is_empty():
			compressao[i] = 0.0
			continue
		rodas_no_chao += 1
		soma_normais += toque.normal
		compressao[i] = alcance - origem.distance_to(toque.position)
		# depois de um teleporte a mola pula de solta pra apertada num quadro só: o amortecedor
		# achava que foi uma pancada fortíssima e jogava o carro pra cima (~3 m/s)
		var velocidade_compressao: float = 0.0 if teleportou else (compressao[i] - anterior) / dt
		var forca := maxf(mola * compressao[i] + amortecedor * velocidade_compressao, 0.0)
		if compressao[i] > curso_mola:
			forca += batente * (compressao[i] - curso_mola)
		estado.apply_force(cima * forca, origem - estado.transform.origin)

	teleportou = false
	if rodas_no_chao > 0:
		normal_chao = soma_normais.normalized()


func dirigir(estado: PhysicsDirectBodyState3D, dt: float) -> void:
	var base := estado.transform.basis
	var cima := base.y
	var v := estado.linear_velocity
	var frente := (-base.z).slide(normal_chao).normalized()
	var lado := base.x.slide(normal_chao).normalized()
	var v_frente := v.dot(frente)
	var v_lado := v.dot(lado)
	var contato := rodas_no_chao / 4.0
	var acelerador := 1.0 if boostando else comandos.acelerador
	var direcao := comandos.direcao
	var freio_mao := comandos.freio_mao

	var dv := 0.0
	if acelerador != 0.0 and absf(v_frente) > 0.1 and signf(acelerador) != signf(v_frente):
		dv = -signf(v_frente) * minf(freio * dt, absf(v_frente))
	elif acelerador != 0.0:
		dv = acelerador * curva(ACELERACAO, absf(v_frente)) * forca_motor * dt
	else:
		dv = -signf(v_frente) * minf(desaceleracao_solto * dt, absf(v_frente))
	v += frente * dv * contato

	if freio_mao:
		derrapagem = minf(derrapagem + dt / ENTRADA_DERRAPAGEM, 1.0)
	else:
		derrapagem = maxf(derrapagem - dt / volta_aderencia, 0.0)
	var limite_lado := lerpf(aderencia, aderencia_freio_mao, derrapagem) * dt * contato
	v -= lado * clampf(v_lado, -limite_lado, limite_lado)
	if not pulando:
		v -= normal_chao * grude * dt * contato

	var giro := -direcao * curva(CURVATURA, absf(v_frente)) * multiplicador_curva * v_frente
	giro *= lerpf(1.0, giro_freio_mao, derrapagem)
	var angulo_deslize := frente.signed_angle_to(v.slide(normal_chao), normal_chao)
	if v.length() > 2.0 and absf(angulo_deslize) < deg_to_rad(100.0):
		giro += angulo_deslize * endireitar * (1.0 - derrapagem)
	var w := estado.angular_velocity
	estado.angular_velocity = w + cima * (giro - w.dot(cima)) * contato
	estado.linear_velocity = v


func controlar_no_ar(estado: PhysicsDirectBodyState3D, dt: float) -> void:
	var base := estado.transform.basis
	var direita := base.x
	var cima := base.y
	var frente := -base.z
	var inclinar := -comandos.inclinar   # + = nariz pra cima
	var virar := -comandos.direcao       # + = pra esquerda
	var rolar := comandos.rolar          # + = pra direita
	if comandos.freio_mao:
		# segurando Shift/X, o virar vira rolar
		rolar = clampf(rolar - virar, -1.0, 1.0)
		virar = 0.0

	var w := estado.angular_velocity
	var a_inclinar := GIRO_NO_AR.x * inclinar * controle_no_ar - AMORTECE_NO_AR.x * (1.0 - absf(inclinar)) * w.dot(direita)
	var a_virar := GIRO_NO_AR.y * virar * controle_no_ar - AMORTECE_NO_AR.y * (1.0 - absf(virar)) * w.dot(cima)
	var a_rolar := GIRO_NO_AR.z * rolar * controle_no_ar - AMORTECE_NO_AR.z * w.dot(frente)
	estado.angular_velocity = w + (direita * a_inclinar + cima * a_virar + frente * a_rolar) * dt
	estado.linear_velocity += frente * comandos.acelerador * ACELERACAO_NO_AR * dt


func apertou_pulo(estado: PhysicsDirectBodyState3D, no_chao: bool) -> void:
	var base := estado.transform.basis
	if no_chao and not pulando:
		estado.linear_velocity += base.y * forca_pulo
		pulando = true
		tempo_pulo = 0.0
		pulou = true
		tempo_no_ar_pos_pulo = 0.0
		return
	if rodas_no_chao > 0:
		return
	if encostado_virado(estado):
		desvirar_pulando(estado)
		return
	if pulo_extra_usado or (pulou and tempo_no_ar_pos_pulo > janela_pulo_extra):
		return
	pulo_extra_usado = true
	pulando = false
	var direcao := Vector2(comandos.inclinar, comandos.direcao)
	if direcao.length() >= 0.5:
		comecar_mortal(estado, direcao)
	else:
		estado.linear_velocity += base.y * forca_pulo


func segurar_pulo(estado: PhysicsDirectBodyState3D, dt: float) -> void:
	if not pulando:
		if pulou and rodas_no_chao == 0:
			tempo_no_ar_pos_pulo += dt
		return
	tempo_pulo += dt
	if tempo_pulo < PULO_MINIMO or (tempo_pulo < tempo_segurando and comandos.pulo):
		estado.linear_velocity += estado.transform.basis.y * forca_segurando * dt
	else:
		pulando = false


func comecar_mortal(estado: PhysicsDirectBodyState3D, direcao: Vector2) -> void:
	# direcao.x: + = pra frente, - = pra trás; direcao.y: + = pra direita
	if absf(direcao.x) < 0.1:
		direcao.x = 0.0
	if absf(direcao.y) < 0.1:
		direcao.y = 0.0
	direcao = direcao.normalized()
	direcao_mortal = direcao
	tempo_mortal = 0.0

	var base := estado.transform.basis
	var frente := Vector3(-base.z.x, 0.0, -base.z.z)
	if frente.length() < 0.01:
		frente = Vector3(base.y.x, 0.0, base.y.z)
	frente = frente.normalized()
	var direita := frente.cross(Vector3.UP)
	var v := estado.linear_velocity
	var v_frente := v.dot(frente)
	var razao := absf(v_frente) / VELOCIDADE_REFERENCIA
	var para_tras := direcao.x < 0.0 if absf(v_frente) < 1.0 else (direcao.x >= 0.0) != (v_frente > 0.0)
	var impulso := direcao * forca_mortal
	impulso.x *= ((2.5 if para_tras else 1.0) - 1.0) * razao + 1.0
	impulso.y *= 0.9 * razao + 1.0
	if para_tras:
		impulso.x *= 16.0 / 15.0
	estado.linear_velocity = v + frente * impulso.x + direita * impulso.y


func girar_mortal(estado: PhysicsDirectBodyState3D, dt: float) -> void:
	# o mortal dá exatamente uma volta em duracao_mortal e para: cai de rodas pra baixo
	tempo_mortal += dt
	var base := estado.transform.basis
	var eixo := (base.x * -direcao_mortal.x + -base.z * direcao_mortal.y).normalized()
	var w := estado.angular_velocity
	if girando_mortal():
		estado.angular_velocity = w + eixo * (TAU / duracao_mortal - w.dot(eixo))
	elif tempo_mortal - dt < duracao_mortal:
		estado.angular_velocity = w - eixo * w.dot(eixo)
	else:
		controlar_no_ar(estado, dt)
	# durante o giro o carro quase não cai: dá tempo de completar a volta
	var v := estado.linear_velocity
	if tempo_mortal >= 0.15 and tempo_mortal < duracao_mortal and (v.y < 0.0 or tempo_mortal < 0.21):
		v.y *= pow(0.65, 120.0 * dt)
		estado.linear_velocity = v


func girando_mortal() -> bool:
	return tempo_mortal >= 0.0 and tempo_mortal < duracao_mortal


func encostado_virado(estado: PhysicsDirectBodyState3D) -> bool:
	if estado.transform.basis.y.dot(Vector3.UP) > 0.7:
		return false
	var origem := estado.transform.origin
	var consulta := PhysicsRayQueryParameters3D.create(origem, origem + Vector3.DOWN * 0.6, collision_mask, [get_rid()])
	return not estado.get_space_state().intersect_ray(consulta).is_empty()


func desvirar_pulando(estado: PhysicsDirectBodyState3D) -> void:
	var cima := estado.transform.basis.y
	var eixo := cima.cross(Vector3.UP)
	if eixo.length() < 0.1:
		eixo = -estado.transform.basis.z
	eixo_desvirar = eixo.normalized()
	tempo_desvirando = cima.angle_to(Vector3.UP) / GIRO_MAXIMO
	estado.linear_velocity += Vector3.UP * 2.0


func corrigir(posicao: Vector3, rotacao: Quaternion, velocidade_: Vector3, giro: Vector3, de_uma_vez: bool) -> void:
	correcao_posicao += posicao
	correcao_rotacao = rotacao * correcao_rotacao
	correcao_velocidade += velocidade_
	correcao_giro += giro
	tem_correcao = true
	if de_uma_vez:
		resetar_interpolacao = true


func aplicar_correcao(estado: PhysicsDirectBodyState3D) -> void:
	if correcao_posicao.length() > 0.5:
		teleportou = true
	var t := estado.transform
	t.origin += correcao_posicao
	t.basis = Basis(correcao_rotacao) * t.basis.orthonormalized()
	estado.transform = t
	estado.linear_velocity += correcao_velocidade
	estado.angular_velocity += correcao_giro
	correcao_posicao = Vector3.ZERO
	correcao_rotacao = Quaternion.IDENTITY
	correcao_velocidade = Vector3.ZERO
	correcao_giro = Vector3.ZERO
	tem_correcao = false


func velocidade() -> Vector3:
	return linear_velocity if simulando else velocidade_rede


func explodir() -> void:
	# some, para de bater nas coisas e fica parado onde explodiu até voltar
	explodido = true
	visible = false
	boostando = false
	$Forma.set_deferred("disabled", true)
	if simulando:
		set_deferred("freeze", true)


func reviver(onde := Transform3D()) -> void:
	# onde = Transform3D() quando quem decide o lugar é o host (o amigo só volta a aparecer)
	explodido = false
	visible = true
	$Forma.set_deferred("disabled", false)
	if simulando:
		set_deferred("freeze", false)
	if onde != Transform3D():
		colocar_em(onde)


func definir_simulacao(ligada: bool) -> void:
	simulando = ligada
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	freeze = not ligada


func definir_time(time: String) -> void:
	tinta.set_shader_parameter("cor", Color(0.2, 0.45, 0.95) if time == "azul" else Color(1.0, 0.5, 0.12))


func vestir(escolha: Dictionary) -> void:
	# a cor principal continua a do time; aqui muda faixas, rodas, fogo, rastro e enfeite
	aparencia = Aparencia.decodificar(Aparencia.codificar(escolha))
	var cor_detalhe: Color = Aparencia.DETALHES[aparencia.detalhe][1]
	detalhe.set_shader_parameter("cor", cor_detalhe)
	tinta.set_shader_parameter("cor_faixas", Color(cor_detalhe, 1.0 if aparencia.detalhe > 0 else 0.0))
	var fogo: Color = Aparencia.FOGOS[aparencia.fogo][1]
	turbina.set_shader_parameter("brilho", fogo)
	montar_rastro(aparencia.rastro, fogo)
	# modelo: desenho, rodas e (como no Rocket League) caixa de batida e lugar das rodas
	var d := ModeloCarro.dados(aparencia.modelo)
	$Forma.shape.size = d.caixa
	$Forma.position = d.centro
	var lugares := [Vector3(-d.rodas.x, 0, d.rodas.y), Vector3(d.rodas.x, 0, d.rodas.y), Vector3(-d.rodas.x, 0, d.rodas.z), Vector3(d.rodas.x, 0, d.rodas.z)]
	for i in 4:
		rodas[i].position = lugares[i] + Vector3.UP * ModeloCarro.ALTURA_RODA
		var pneu: MeshInstance3D = rodas[i].get_node("Pneu")
		pneu.mesh = ModeloCarro.roda(aparencia.modelo, i >= 2)
		usar_materiais(pneu)
	rastro.position = d.turbina
	$Corpo.mesh = ModeloCarro.corpo(aparencia.modelo)
	usar_materiais($Corpo)
	enfeite.mesh = ModeloCarro.enfeite(aparencia.enfeite)
	usar_materiais(enfeite)
	enfeite.position = ModeloCarro.posicao_enfeite(aparencia.modelo, aparencia.enfeite)


func usar_materiais(malha: MeshInstance3D) -> void:
	# os pedaços com nome de cor usam os materiais deste carro (time, fogo, detalhes)
	if malha.mesh == null:
		return
	for i in malha.mesh.get_surface_count():
		match malha.mesh.surface_get_name(i):
			"pintura":
				malha.set_surface_override_material(i, tinta)
			"turbina":
				malha.set_surface_override_material(i, turbina)
			"detalhe", "aro":
				malha.set_surface_override_material(i, detalhe)


func estimar_rodas() -> void:
	# carro que só aparece (posição vinda do host): as rodas acompanham o chão só no desenho
	var espaco := get_world_3d().direct_space_state
	var cima := global_basis.y
	var alcance := curso_mola + raio_roda
	rodas_no_chao = 0
	for i in 4:
		var origem := global_transform * rodas[i].position
		var toque := espaco.intersect_ray(PhysicsRayQueryParameters3D.create(origem, origem - cima * alcance, collision_mask, [get_rid()]))
		compressao[i] = 0.0 if toque.is_empty() else alcance - origem.distance_to(toque.position)
		if not toque.is_empty():
			rodas_no_chao += 1


func colocar_em(onde: Transform3D) -> void:
	ponto_inicial = onde
	pedido_voltar = true


func atualizar_boost(dt: float) -> void:
	var apertado := comandos.boost and boost > 0.0
	if apertado:
		tempo_boost_minimo = BOOST_MINIMO
	boostando = (apertado or tempo_boost_minimo > 0.0) and boost > 0.0
	tempo_boost_minimo = maxf(tempo_boost_minimo - dt, 0.0)
	if boostando:
		boost = maxf(boost - gasto_boost * dt, 0.0)
	else:
		boost = minf(boost + recarga_boost * dt, 100.0)


func reposicionar(estado: PhysicsDirectBodyState3D) -> void:
	if pedido_voltar:
		estado.transform = ponto_inicial
	else:
		var frente := -estado.transform.basis.z
		frente.y = 0.0
		if frente.length() < 0.1:
			frente = Vector3.FORWARD
		var posicao := estado.transform.origin + Vector3.UP
		estado.transform = Transform3D(Basis.looking_at(frente), posicao)
	estado.linear_velocity = Vector3.ZERO
	estado.angular_velocity = Vector3.ZERO
	tempo_mortal = -1.0
	tempo_desvirando = 0.0
	pedido_voltar = false
	pedido_desvirar = false
	teleportou = true


func curva(tabela: Array, x: float) -> float:
	for i in range(1, tabela.size()):
		if x <= tabela[i][0]:
			var a: Array = tabela[i - 1]
			var b: Array = tabela[i]
			return lerpf(a[1], b[1], (x - a[0]) / (b[0] - a[0]))
	return tabela[-1][1]


func criar_rastro() -> void:
	rastro = CPUParticles3D.new()
	rastro.emitting = false
	rastro.local_coords = false
	rastro.direction = Vector3.BACK
	var bolinha := SphereMesh.new()
	bolinha.radius = 0.09
	bolinha.height = 0.18
	bolinha.radial_segments = 8
	bolinha.rings = 4
	bolinha.material = Materiais.rastro()
	rastro.mesh = bolinha
	add_child(rastro)


func montar_rastro(tipo: int, fogo: Color) -> void:
	# fogo: bolinhas rápidas e curtas · faíscas: pontinhos que caem · fumaça: nuvem que cresce e fica
	var cores := Gradient.new()
	rastro.scale_amount_curve = null
	match tipo:
		1:
			rastro.amount = 70
			rastro.lifetime = 0.5
			rastro.spread = 22.0
			rastro.initial_velocity_min = 4.0
			rastro.initial_velocity_max = 8.0
			rastro.gravity = Vector3(0, -9.0, 0)
			rastro.scale_amount_min = 0.2
			rastro.scale_amount_max = 0.4
			cores.set_color(0, Color(fogo.lerp(Color.WHITE, 0.3) * 2.5, 1.0))
			cores.set_color(1, Color(fogo * 1.5, 0.0))
		2:
			rastro.amount = 60
			rastro.lifetime = 0.9
			rastro.spread = 12.0
			rastro.initial_velocity_min = 1.5
			rastro.initial_velocity_max = 3.0
			rastro.gravity = Vector3(0, 0.8, 0)
			rastro.scale_amount_min = 0.7
			rastro.scale_amount_max = 1.0
			var crescer := Curve.new()
			crescer.max_value = 3.0
			crescer.add_point(Vector2(0.0, 0.6))
			crescer.add_point(Vector2(1.0, 2.6))
			rastro.scale_amount_curve = crescer
			cores.set_color(0, Color(fogo.lerp(Color.WHITE, 0.4) * 1.6, 1.0))
			cores.set_color(1, Color(0.3, 0.3, 0.33, 0.0))
			cores.add_point(0.25, Color(0.55, 0.55, 0.58, 0.45))
		_:
			rastro.amount = 80
			rastro.lifetime = 0.35
			rastro.spread = 8.0
			rastro.initial_velocity_min = 3.0
			rastro.initial_velocity_max = 5.0
			rastro.gravity = Vector3.ZERO
			rastro.scale_amount_min = 0.6
			rastro.scale_amount_max = 1.0
			cores.set_color(0, Color(fogo.lerp(Color(1.0, 0.95, 0.6), 0.6), 1.0))
			cores.set_color(1, Color(fogo.darkened(0.2), 0.0))
	rastro.color_ramp = cores


func atualizar_rodas_desenhadas(delta: float) -> void:
	var v_frente := velocidade().dot(-global_basis.z)
	giro_pneu -= v_frente / raio_roda * delta
	var angulo := -comandos.direcao * angulo_visual_roda
	for i in 4:
		var pneu: Node3D = rodas[i].get_node("Pneu")
		var distancia := maxf(curso_mola - compressao[i], 0.0)
		pneu.position = Vector3(0.0, -distancia, 0.0)
		var b := Basis(Vector3.RIGHT, giro_pneu) * Basis(Vector3.BACK, PI / 2.0)
		if i < 2:
			b = Basis(Vector3.UP, angulo) * b
		pneu.basis = b
