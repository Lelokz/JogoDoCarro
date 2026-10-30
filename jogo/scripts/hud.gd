extends CanvasLayer

@export var carro_caminho: NodePath

var carro: RigidBody3D


func _ready() -> void:
	carro = get_node(carro_caminho)
	$Controles.text = "W/S ou RT/LT: acelerar e ré   ·   A/D ou analógico: virar   ·   Shift ou X: freio de mão (no ar: rolar)\nEspaço, botão direito ou A: pulo (de novo no ar = duplo pulo; com direção = mortal)   ·   Botão esquerdo, Ctrl ou B: boost\nNo ar: W/S inclina, A/D vira, Q/E rola   ·   R: desvirar   ·   T: início   ·   F1: ajustes   ·   F11: tela cheia"


func _process(_delta: float) -> void:
	var v := carro.linear_velocity.length()
	$Velocidade.text = "%d km/h  (%.1f m/s)\nRodas no chão: %d/4" % [roundi(v * 3.6), v, carro.rodas_no_chao]
	$Boost.text = ("SUPERSÔNICO\n" if carro.supersonico else "") + "Boost %d" % roundi(carro.boost)
