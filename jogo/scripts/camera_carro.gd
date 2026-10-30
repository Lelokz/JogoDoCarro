extends Camera3D

@export var alvo_caminho: NodePath
@export var distancia := 2.8
@export var altura := 1.1
@export var suavidade := 8.0

var alvo: Node3D


func _ready() -> void:
	alvo = get_node(alvo_caminho)
	top_level = true
	physics_interpolation_mode = PHYSICS_INTERPOLATION_MODE_OFF
	global_position = alvo.global_position + alvo.global_basis.z * distancia + Vector3.UP * altura


func _process(delta: float) -> void:
	var t := alvo.get_global_transform_interpolated()
	var frente := -t.basis.z
	frente.y = 0.0
	if frente.length() < 0.1:
		frente = -global_basis.z
		frente.y = 0.0
	frente = frente.normalized()
	var destino := t.origin - frente * distancia + Vector3.UP * altura
	global_position = global_position.lerp(destino, 1.0 - exp(-suavidade * delta))
	look_at(t.origin + Vector3.UP * 0.4 + frente * 1.5, Vector3.UP)
