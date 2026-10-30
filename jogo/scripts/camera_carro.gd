extends Camera3D

@export var alvo_caminho: NodePath
@export var bola_caminho: NodePath
@export var distancia := 2.8
@export var altura := 1.1
@export var suavidade := 8.0   # só o giro da câmera é suave; a distância fica sempre igual

var alvo: Node3D
var bola: Node3D
var camera_bola := false
var frente_suave := Vector3.FORWARD


func _ready() -> void:
	alvo = get_node(alvo_caminho)
	bola = get_node_or_null(bola_caminho)
	top_level = true
	physics_interpolation_mode = PHYSICS_INTERPOLATION_MODE_OFF
	frente_suave = direcao_do_carro(alvo.global_transform)


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("camera_bola") and bola:
		camera_bola = not camera_bola
	var t := alvo.get_global_transform_interpolated()
	var posicao_bola := bola.get_global_transform_interpolated().origin if bola else Vector3.ZERO
	var direcao := direcao_do_carro(t)
	if camera_bola:
		# fica atrás do carro na linha carro → bola
		var ate_bola := posicao_bola - t.origin
		ate_bola.y = 0.0
		if ate_bola.length() > 0.5:
			direcao = ate_bola.normalized()
	var angulo := frente_suave.signed_angle_to(direcao, Vector3.UP)
	frente_suave = frente_suave.rotated(Vector3.UP, angulo * (1.0 - exp(-suavidade * delta))).normalized()
	global_position = t.origin - frente_suave * distancia + Vector3.UP * altura
	var olhar := t.origin + Vector3.UP * 0.4 + frente_suave * 1.5
	if camera_bola:
		olhar = olhar.lerp(posicao_bola, 0.7)
	look_at(olhar, Vector3.UP)


func direcao_do_carro(t: Transform3D) -> Vector3:
	if alvo.rodas_no_chao == 0:
		# no ar segue pra onde o carro vai, senão a câmera gira junto no mortal
		var v: Vector3 = alvo.linear_velocity
		v.y = 0.0
		return v.normalized() if v.length() > 3.0 else frente_suave
	var frente := -t.basis.z
	frente.y = 0.0
	if frente.length() < 0.1:
		return frente_suave
	return frente.normalized()
