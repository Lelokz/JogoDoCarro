extends RigidBody3D

# Valores de partida: números da wiki RLBot convertidos de cm pra metros.
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
@export var multiplicador_curva := 1.0    # multiplica a tabela CURVATURA
@export var freio := 35.0                 # m/s²
@export var desaceleracao_solto := 5.25   # m/s², sem acelerar nem frear
@export var velocidade_maxima := 23.0     # m/s
@export var aderencia := 60.0             # m/s² que os pneus seguram de lado
@export var aderencia_freio_mao := 8.0
@export var giro_freio_mao := 1.4         # vira quanto a mais no freio de mão
@export var volta_aderencia := 0.6        # s pro pneu voltar a agarrar depois de soltar o freio de mão
@export var endireitar := 2.0             # quanto o carro gira sozinho pra apontar pra onde está indo
@export var angulo_visual_roda := 0.45    # rad, só a roda desenhada

# [velocidade m/s, aceleração m/s²]: acelera forte parado e quase nada perto de 14,1
const ACELERACAO := [[0.0, 16.0], [14.0, 1.6], [14.1, 0.0]]
const ENTRADA_DERRAPAGEM := 0.1   # s pro pneu soltar quando aperta o freio de mão
# [velocidade m/s, curvatura 1/m]: quanto mais rápido, mais aberta a curva
const CURVATURA := [[0.0, 0.69], [5.0, 0.398], [10.0, 0.235], [15.0, 0.1375], [17.5, 0.11], [25.0, 0.088]]

@onready var rodas: Array[Node3D] = [$RodaFE, $RodaFD, $RodaTE, $RodaTD]

var compressao := [0.0, 0.0, 0.0, 0.0]
var rodas_no_chao := 0
var derrapagem := 0.0   # 0 = pneu agarrando, 1 = freio de mão inteiro
var giro_pneu := 0.0
var ponto_inicial: Transform3D
var pedido_desvirar := false
var pedido_voltar := false


func _ready() -> void:
	ponto_inicial = global_transform


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("desvirar"):
		pedido_desvirar = true
	if Input.is_action_just_pressed("voltar_inicio"):
		pedido_voltar = true
	atualizar_rodas_desenhadas(delta)


func _integrate_forces(estado: PhysicsDirectBodyState3D) -> void:
	if pedido_voltar or pedido_desvirar:
		reposicionar(estado)
		return

	var dt := estado.step
	var base := estado.transform.basis
	var cima := base.y
	var espaco := estado.get_space_state()
	var alcance := curso_mola + raio_roda
	var normal_chao := Vector3.ZERO
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
		normal_chao += toque.normal
		compressao[i] = alcance - origem.distance_to(toque.position)
		var velocidade_compressao: float = (compressao[i] - anterior) / dt
		var forca := maxf(mola * compressao[i] + amortecedor * velocidade_compressao, 0.0)
		if compressao[i] > curso_mola:
			forca += batente * (compressao[i] - curso_mola)
		estado.apply_force(cima * forca, origem - estado.transform.origin)

	var v := estado.linear_velocity
	if rodas_no_chao > 0:
		normal_chao = normal_chao.normalized()
		var frente := (-base.z).slide(normal_chao).normalized()
		var lado := base.x.slide(normal_chao).normalized()
		var v_frente := v.dot(frente)
		var v_lado := v.dot(lado)
		var contato := rodas_no_chao / 4.0
		var acelerador := Input.get_axis("re", "acelerar")
		var direcao := Input.get_axis("esquerda", "direita")
		var freio_mao := Input.is_action_pressed("freio_mao")

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
		v -= normal_chao * grude * dt * contato

		var giro := -direcao * curva(CURVATURA, absf(v_frente)) * multiplicador_curva * v_frente
		giro *= lerpf(1.0, giro_freio_mao, derrapagem)
		var angulo_deslize := frente.signed_angle_to(v.slide(normal_chao), normal_chao)
		if v.length() > 2.0 and absf(angulo_deslize) < deg_to_rad(100.0):
			giro += angulo_deslize * endireitar * (1.0 - derrapagem)
		var w := estado.angular_velocity
		estado.angular_velocity = w + cima * (giro - w.dot(cima)) * contato

	estado.linear_velocity = v.limit_length(velocidade_maxima)


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
	pedido_voltar = false
	pedido_desvirar = false


func curva(tabela: Array, x: float) -> float:
	for i in range(1, tabela.size()):
		if x <= tabela[i][0]:
			var a: Array = tabela[i - 1]
			var b: Array = tabela[i]
			return lerpf(a[1], b[1], (x - a[0]) / (b[0] - a[0]))
	return tabela[-1][1]


func atualizar_rodas_desenhadas(delta: float) -> void:
	var v_frente := linear_velocity.dot(-global_basis.z)
	giro_pneu -= v_frente / raio_roda * delta
	var angulo := -Input.get_axis("esquerda", "direita") * angulo_visual_roda
	for i in 4:
		var pneu: Node3D = rodas[i].get_node("Pneu")
		var distancia := maxf(curso_mola - compressao[i], 0.0)
		pneu.position = Vector3(0.0, -distancia, 0.0)
		var b := Basis(Vector3.RIGHT, giro_pneu) * Basis(Vector3.BACK, PI / 2.0)
		if i < 2:
			b = Basis(Vector3.UP, angulo) * b
		pneu.basis = b
