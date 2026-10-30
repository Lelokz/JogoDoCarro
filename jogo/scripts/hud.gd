extends CanvasLayer

@export var carro_caminho: NodePath
@export var bola_caminho: NodePath
@export var camera_caminho: NodePath

var carro: RigidBody3D
var bola: RigidBody3D
var camera: Camera3D


func _ready() -> void:
	carro = get_node(carro_caminho)
	bola = get_node(bola_caminho)
	camera = get_node(camera_caminho)
	$Controles.text = "W/S ou RT/LT: acelerar e ré   ·   A/D ou analógico: virar   ·   Shift ou X: freio de mão (no ar: rolar)\nEspaço, botão direito ou A: pulo (de novo no ar = duplo pulo; com direção = mortal)   ·   Botão esquerdo, Ctrl ou B: boost\nNo ar: W/S inclina, A/D vira, Q/E rola   ·   C ou Y: câmera da bola   ·   G: bola na frente   ·   R: desvirar   ·   T: início   ·   F1: ajustes   ·   F2: arena / campo de teste   ·   F11: tela cheia"


func _process(_delta: float) -> void:
	var v := carro.linear_velocity.length()
	$Velocidade.text = "%d km/h  (%.1f m/s)\nRodas no chão: %d/4\nBola: %d km/h  ·  último toque: %d km/h\nCâmera: %s" % [roundi(v * 3.6), v, carro.rodas_no_chao, roundi(bola.linear_velocity.length() * 3.6), roundi(bola.ultimo_toque * 3.6), "bola" if camera.camera_bola else "carro"]
	$Boost.text = ("SUPERSÔNICO\n" if carro.supersonico else "") + "Boost %d" % roundi(carro.boost)
