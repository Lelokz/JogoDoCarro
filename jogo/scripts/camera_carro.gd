extends Camera3D

@export var alvo_caminho: NodePath
@export var distancia := 2.8
@export var altura := 1.1
@export var suavidade := 8.0   # só o giro da câmera é suave; a distância fica sempre igual

var alvo: Node3D
var frente_suave := Vector3.FORWARD


func _ready() -> void:
	alvo = get_node(alvo_caminho)
	top_level = true
	physics_interpolation_mode = PHYSICS_INTERPOLATION_MODE_OFF
	frente_suave = direcao_do_carro(alvo.global_transform)


func _process(delta: float) -> void:
	var t := alvo.get_global_transform_interpolated()
	var angulo := frente_suave.signed_angle_to(direcao_do_carro(t), Vector3.UP)
	frente_suave = frente_suave.rotated(Vector3.UP, angulo * (1.0 - exp(-suavidade * delta))).normalized()
	global_position = t.origin - frente_suave * distancia + Vector3.UP * altura
	look_at(t.origin + Vector3.UP * 0.4 + frente_suave * 1.5, Vector3.UP)


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
