class_name Arena
extends Node3D

# Arena gerada por código: chão, paredes com curva embaixo e em cima, cantos arredondados,
# teto e os dois gols. Muda os números aqui que a arena muda junto.

const LARGURA := 80.0           # m, de parede a parede (x)
const COMPRIMENTO := 100.0      # m, de gol a gol (z)
const ALTURA := 20.0            # m até o teto
const RAIO_CURVA := 3.0         # curva entre chão e parede (e entre parede e teto)
const RAIO_CANTO := 14.0        # cantos arredondados, vistos de cima
const GOL_LARGURA := 18.0
const GOL_ALTURA := 6.5
const GOL_FUNDO := 9.0
const PASSOS_CURVA := 10
const PASSOS_CANTO := 20

const COR_AZUL := Color(0.15, 0.4, 1.0)
const COR_LARANJA := Color(1.0, 0.5, 0.1)

var material: ShaderMaterial
var material_vidro: ShaderMaterial


func _ready() -> void:
	material = Materiais.chao_da_arena(COMPRIMENTO / 2.0, GOL_LARGURA / 2.0)
	material_vidro = Materiais.vidro(COMPRIMENTO / 2.0)
	criar_chao_de_fora()
	criar_bloco(Vector3(0, -0.5, 0), Vector3(LARGURA + 2.0, 1.0, COMPRIMENTO + 2.0 * GOL_FUNDO + 4.0), material)
	# teto: só colisão, pra ver o céu
	criar_bloco(Vector3(0, ALTURA + 0.5, 0), Vector3(LARGURA + 2.0, 1.0, COMPRIMENTO + 2.0), null)
	criar_paredes()
	criar_gol(-1.0, COR_LARANJA)
	criar_gol(1.0, COR_AZUL)


func perimetro() -> Array:
	# a volta da arena vista de cima: [ponto no chão, direção pra dentro]
	var x := LARGURA / 2.0 - RAIO_CANTO
	var z := COMPRIMENTO / 2.0 - RAIO_CANTO
	var g := GOL_LARGURA / 2.0
	var pontos := []
	pontos.append([Vector3(-g, 0, -COMPRIMENTO / 2.0), Vector3.BACK])
	pontos.append([Vector3(g, 0, -COMPRIMENTO / 2.0), Vector3.BACK])
	adicionar_canto(pontos, Vector3(x, 0, -z), -90.0)
	adicionar_canto(pontos, Vector3(x, 0, z), 0.0)
	pontos.append([Vector3(g, 0, COMPRIMENTO / 2.0), Vector3.FORWARD])
	pontos.append([Vector3(-g, 0, COMPRIMENTO / 2.0), Vector3.FORWARD])
	adicionar_canto(pontos, Vector3(-x, 0, z), 90.0)
	adicionar_canto(pontos, Vector3(-x, 0, -z), 180.0)
	return pontos


func adicionar_canto(pontos: Array, centro: Vector3, angulo_inicial: float) -> void:
	for k in PASSOS_CANTO + 1:
		var a := deg_to_rad(angulo_inicial + 90.0 * k / PASSOS_CANTO)
		var fora := Vector3(cos(a), 0, sin(a))
		pontos.append([centro + fora * RAIO_CANTO, -fora])


func perfil(boca_do_gol: bool) -> Array:
	# corte da parede: [distância pra dentro, altura, normal pra dentro, normal pra cima]
	var pontos := []
	if boca_do_gol:
		pontos.append([0.0, GOL_ALTURA, 1.0, 0.0])
	else:
		for k in PASSOS_CURVA + 1:
			var t := PI / 2.0 * k / PASSOS_CURVA
			pontos.append([RAIO_CURVA - RAIO_CURVA * sin(t), RAIO_CURVA - RAIO_CURVA * cos(t), sin(t), cos(t)])
	for k in PASSOS_CURVA + 1:
		var t := PI / 2.0 * (1.0 - float(k) / PASSOS_CURVA)
		pontos.append([RAIO_CURVA - RAIO_CURVA * sin(t), ALTURA - RAIO_CURVA + RAIO_CURVA * cos(t), sin(t), -cos(t)])
	return pontos


func criar_paredes() -> void:
	var malha := SurfaceTool.new()
	malha.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := PackedVector3Array()
	var pontos := perimetro()
	for i in pontos.size():
		var a: Array = pontos[i]
		var b: Array = pontos[(i + 1) % pontos.size()]
		var meio: Vector3 = (a[0] + b[0]) / 2.0
		var boca := absf(absf(meio.z) - COMPRIMENTO / 2.0) < 0.01 and absf(meio.x) < GOL_LARGURA / 2.0
		var corte := perfil(boca)
		for j in corte.size() - 1:
			var v00 := vertice(a, corte[j])
			var v10 := vertice(b, corte[j])
			var v11 := vertice(b, corte[j + 1])
			var v01 := vertice(a, corte[j + 1])
			triangulo(malha, faces, [v00, v10, v11])
			triangulo(malha, faces, [v00, v11, v01])

	# tampa do lado da trave, onde a curva do chão termina
	var curva := perfil(false).slice(0, PASSOS_CURVA + 1)
	for ponto in pontos:
		var p: Vector3 = ponto[0]
		if absf(absf(p.z) - COMPRIMENTO / 2.0) < 0.01 and absf(absf(p.x) - GOL_LARGURA / 2.0) < 0.01:
			var lado := Vector3(-signf(p.x), 0, 0)
			var canto := [p, lado]
			for j in curva.size() - 1:
				triangulo(malha, faces, [canto, [vertice(ponto, curva[j])[0], lado], [vertice(ponto, curva[j + 1])[0], lado]])

	var corpo := StaticBody3D.new()
	var forma := CollisionShape3D.new()
	var colisao := ConcavePolygonShape3D.new()
	colisao.set_faces(faces)
	colisao.backface_collision = true
	forma.shape = colisao
	var desenho := MeshInstance3D.new()
	desenho.mesh = malha.commit()
	desenho.material_override = material_vidro
	desenho.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	corpo.add_child(forma)
	corpo.add_child(desenho)
	add_child(corpo)


func vertice(ponto: Array, corte: Array) -> Array:
	var p: Vector3 = ponto[0]
	var dentro: Vector3 = ponto[1]
	var posicao: Vector3 = p + dentro * corte[0] + Vector3.UP * corte[1]
	var normal: Vector3 = (dentro * corte[2] + Vector3.UP * corte[3]).normalized()
	return [posicao, normal]


func triangulo(malha: SurfaceTool, faces: PackedVector3Array, vertices: Array) -> void:
	for v in vertices:
		malha.set_normal(v[1])
		malha.add_vertex(v[0])
		faces.append(v[0])


func criar_gol(lado: float, cor: Color) -> void:
	var rede := Materiais.transparente(Color(cor.r, cor.g, cor.b, 0.35))
	var g := GOL_LARGURA / 2.0
	var linha := lado * COMPRIMENTO / 2.0
	criar_bloco(Vector3(0, GOL_ALTURA / 2.0, linha + lado * (GOL_FUNDO + 0.5)), Vector3(GOL_LARGURA + 2.0, GOL_ALTURA, 1.0), rede)
	criar_bloco(Vector3(-(g + 0.5), GOL_ALTURA / 2.0, linha + lado * GOL_FUNDO / 2.0), Vector3(1.0, GOL_ALTURA, GOL_FUNDO), rede)
	criar_bloco(Vector3(g + 0.5, GOL_ALTURA / 2.0, linha + lado * GOL_FUNDO / 2.0), Vector3(1.0, GOL_ALTURA, GOL_FUNDO), rede)
	criar_bloco(Vector3(0, GOL_ALTURA + 0.5, linha + lado * GOL_FUNDO / 2.0), Vector3(GOL_LARGURA + 2.0, 1.0, GOL_FUNDO), rede)


func criar_chao_de_fora() -> void:
	# só pra aparecer pelo vidro: um chão escuro em volta da arena
	var desenho := MeshInstance3D.new()
	desenho.mesh = PlaneMesh.new()
	desenho.mesh.size = Vector2(600, 600)
	desenho.position.y = -1.0
	desenho.material_override = Materiais.liso(Color(0.07, 0.08, 0.1), 0.9)
	add_child(desenho)


func criar_bloco(posicao: Vector3, tamanho: Vector3, aparencia: Material) -> void:
	var corpo := StaticBody3D.new()
	corpo.position = posicao
	var forma := CollisionShape3D.new()
	forma.shape = BoxShape3D.new()
	forma.shape.size = tamanho
	corpo.add_child(forma)
	if aparencia:
		var desenho := MeshInstance3D.new()
		desenho.mesh = BoxMesh.new()
		desenho.mesh.size = tamanho
		desenho.material_override = aparencia
		desenho.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		corpo.add_child(desenho)
	add_child(corpo)
