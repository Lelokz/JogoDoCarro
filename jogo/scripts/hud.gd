extends CanvasLayer

@export var carro_caminho: NodePath

var carro: RigidBody3D


func _ready() -> void:
	carro = get_node(carro_caminho)
	$Controles.text = "W/S ou RT/LT: acelerar e ré   ·   A/D ou analógico: virar\nShift ou X: freio de mão   ·   R ou Back: desvirar   ·   T: voltar ao início   ·   F11: tela cheia"


func _process(_delta: float) -> void:
	var v := carro.linear_velocity.length()
	$Velocidade.text = "%d km/h  (%.1f m/s)\nRodas no chão: %d/4" % [roundi(v * 3.6), v, carro.rodas_no_chao]
