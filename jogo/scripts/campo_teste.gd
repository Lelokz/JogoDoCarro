extends Node3D

const TAMANHO_CHAO := 1000.0

# [posição, tamanho, inclinação em graus, giro em graus]. A rampa sobe pra frente (-Z).
const RAMPAS := [
	[Vector3(-20, 0, -40), Vector3(8, 0.5, 10), 12.0, 0.0],
	[Vector3(0, 0, -40), Vector3(8, 0.5, 12), 25.0, 0.0],
	[Vector3(20, 0, -40), Vector3(8, 0.5, 14), 40.0, 0.0],
	[Vector3(0, 0, 60), Vector3(14, 0.5, 30), 15.0, 180.0],
	[Vector3(60, 0, 0), Vector3(10, 0.5, 20), 30.0, -90.0],
]

# [posição, tamanho]
const PAREDES := [
	[Vector3(-45, 3, 0), Vector3(2, 6, 60)],
]

var material_grade: ShaderMaterial


func _ready() -> void:
	Opcoes.aplicar_graficos(self)
	Opcoes.mudou.connect(aplicar_graficos)
	material_grade = Materiais.grade()
	# ainda não tem os pads de boost (etapa 5): aqui o tanque enche sozinho
	$Carro.recarga_boost = 20.0
	criar_bloco(Vector3(0, -0.5, 0), Vector3(TAMANHO_CHAO, 1, TAMANHO_CHAO), Basis())
	for r in RAMPAS:
		var tamanho: Vector3 = r[1]
		var inclinacao := deg_to_rad(r[2])
		var base := Basis(Vector3.UP, deg_to_rad(r[3])) * Basis(Vector3.RIGHT, inclinacao)
		# levanta o bloco até a ponta baixa da rampa encostar no chão
		var y := tamanho.z / 2.0 * sin(inclinacao) - tamanho.y / 2.0 * cos(inclinacao)
		criar_bloco(r[0] + Vector3(0, y, 0), tamanho, base)
	for p in PAREDES:
		criar_bloco(p[0], p[1], Basis())


func criar_bloco(posicao: Vector3, tamanho: Vector3, base: Basis) -> void:
	var corpo := StaticBody3D.new()
	corpo.transform = Transform3D(base, posicao)
	var forma := CollisionShape3D.new()
	forma.shape = BoxShape3D.new()
	forma.shape.size = tamanho
	var desenho := MeshInstance3D.new()
	desenho.mesh = BoxMesh.new()
	desenho.mesh.size = tamanho
	desenho.material_override = material_grade
	corpo.add_child(forma)
	corpo.add_child(desenho)
	add_child(corpo)


func aplicar_graficos() -> void:
	Opcoes.aplicar_graficos(self)
