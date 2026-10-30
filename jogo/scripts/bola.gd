extends RigidBody3D

# Bola: números do RocketSim convertidos de cm pra metros.
# O "empurrão extra" é o que deixa o chute gostoso: além da batida normal,
# a bola ganha velocidade na direção do toque (mais pra frente do carro, menos pra cima).

@export var carro_caminho: NodePath
@export var empurrao_extra := 1.0        # multiplica o empurrão extra (1 = referência)
@export var forca_batida := 1.0          # multiplica tudo que a bola ganha numa batida (física + empurrão)
@export var velocidade_maxima := 60.0    # m/s

const GIRO_MAXIMO := 6.0                 # rad/s
const ESCALA_ALTURA := 0.35              # o empurrão extra joga menos pra cima
const ESCALA_FRENTE := 0.65              # e um pouco menos na direção da frente do carro
const VELOCIDADE_TOQUE_MAXIMA := 46.0    # m/s de diferença entre carro e bola que ainda conta
# [velocidade do toque m/s, fator]: toque fraco ganha proporcionalmente mais
const CURVA_EMPURRAO := [[0.0, 0.65], [5.0, 0.65], [23.0, 0.55], [46.0, 0.30]]

var carro: RigidBody3D
var ponto_inicial: Transform3D
var ultimo_empurrao := -10
var pedido_voltar := false
var pedido_trazer := false
var ultimo_toque := 0.0   # velocidade que a bola saiu do último toque (pro HUD e pros testes)
var velocidade_anterior := Vector3.ZERO
var velocidade_rede := Vector3.ZERO   # quem entrou numa partida: a bola só aparece onde o host manda
var tocando_carro := false


func _ready() -> void:
	carro = get_node(carro_caminho)
	ponto_inicial = global_transform
	contact_monitor = true
	max_contacts_reported = 4


func _physics_process(_delta: float) -> void:
	if Rede.online():
		return   # voltar e trazer a bola são só pra treino
	if Input.is_action_just_pressed("voltar_inicio"):
		pedido_voltar = true
	if Input.is_action_just_pressed("trazer_bola"):
		pedido_trazer = true


func _integrate_forces(estado: PhysicsDirectBodyState3D) -> void:
	if pedido_voltar or pedido_trazer:
		reposicionar(estado)
		return

	# um empurrão extra no máximo a cada 2 quadros, igual à referência
	var quadro := Engine.get_physics_frames()
	var toque := false
	for i in estado.get_contact_count():
		var outro := estado.get_contact_collider_object(i)
		if outro is Node and outro.is_in_group("carros"):
			toque = true
			if quadro > ultimo_empurrao + 1:
				empurrar(estado, outro)
				ultimo_empurrao = quadro
			break
	# só na batida (não enquanto o carro vai empurrando a bola colada)
	if toque and not tocando_carro:
		estado.linear_velocity = velocidade_anterior + (estado.linear_velocity - velocidade_anterior) * forca_batida
		ultimo_toque = estado.linear_velocity.length()
	tocando_carro = toque

	estado.linear_velocity = estado.linear_velocity.limit_length(velocidade_maxima)
	estado.angular_velocity = estado.angular_velocity.limit_length(GIRO_MAXIMO)
	velocidade_anterior = estado.linear_velocity


func velocidade() -> Vector3:
	return velocidade_rede if Rede.modo == "cliente" else linear_velocity


func empurrar(estado: PhysicsDirectBodyState3D, quem: RigidBody3D) -> void:
	var posicao_relativa := estado.transform.origin - quem.global_position
	var velocidade_toque := minf((estado.linear_velocity - quem.linear_velocity).length(), VELOCIDADE_TOQUE_MAXIMA)
	if velocidade_toque <= 0.0:
		return
	var direcao := (posicao_relativa * Vector3(1.0, ESCALA_ALTURA, 1.0)).normalized()
	var frente := -quem.global_basis.z
	direcao = (direcao - frente * direcao.dot(frente) * (1.0 - ESCALA_FRENTE)).normalized()
	estado.linear_velocity += direcao * velocidade_toque * curva(CURVA_EMPURRAO, velocidade_toque) * empurrao_extra
	ultimo_toque = estado.linear_velocity.length()


func reposicionar(estado: PhysicsDirectBodyState3D) -> void:
	if pedido_trazer:
		var frente := -carro.global_basis.z
		frente.y = 0.0
		frente = frente.normalized() if frente.length() > 0.1 else Vector3.FORWARD
		estado.transform = Transform3D(Basis(), carro.global_position + frente * 10.0 + Vector3.UP * 1.5)
	else:
		estado.transform = ponto_inicial
	estado.linear_velocity = Vector3.ZERO
	estado.angular_velocity = Vector3.ZERO
	velocidade_anterior = Vector3.ZERO
	pedido_voltar = false
	pedido_trazer = false


func curva(tabela: Array, x: float) -> float:
	for i in range(1, tabela.size()):
		if x <= tabela[i][0]:
			var a: Array = tabela[i - 1]
			var b: Array = tabela[i]
			return lerpf(a[1], b[1], (x - a[0]) / (b[0] - a[0]))
	return tabela[-1][1]
