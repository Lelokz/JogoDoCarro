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
	Opcoes.aplicar_graficos(self)
	Opcoes.mudou.connect(aplicar_graficos)
	material = Materiais.gramado(COMPRIMENTO / 2.0, LARGURA / 2.0, GOL_LARGURA / 2.0)
	material_vidro = Materiais.vidro(ALTURA)
	criar_chao_de_fora()
	criar_arquibancada()
	for x in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			criar_torre_de_luz(Vector3(62.0 * x, 0.0, 80.0 * z))
	criar_bloco(Vector3(0, -0.5, 0), Vector3(LARGURA + 2.0, 1.0, COMPRIMENTO + 2.0 * GOL_FUNDO + 4.0), material)
	# teto: só colisão, pra ver o céu
	criar_bloco(Vector3(0, ALTURA + 0.5, 0), Vector3(LARGURA + 2.0, 1.0, COMPRIMENTO + 2.0), null)
	criar_paredes()
	criar_gol(-1.0, COR_LARANJA)
	criar_gol(1.0, COR_AZUL)


func aplicar_graficos() -> void:
	Opcoes.aplicar_graficos(self)


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
	var rede := Materiais.rede(cor)
	var g := GOL_LARGURA / 2.0
	var linha := lado * COMPRIMENTO / 2.0
	# trave e travessão acesos na cor do time (só desenho: quem segura a bola é a parede)
	var trave := Modelagem.nova()
	for x in [-(g + 0.15), g + 0.15]:
		Modelagem.caixa(trave, Vector3(x, GOL_ALTURA / 2.0, linha + lado * 0.15), Vector3(0.3, GOL_ALTURA + 0.3, 0.3))
	Modelagem.caixa(trave, Vector3(0, GOL_ALTURA + 0.15, linha + lado * 0.15), Vector3(GOL_LARGURA + 0.6, 0.3, 0.3))
	var malha := ArrayMesh.new()
	Modelagem.adicionar(malha, trave, "trave", Materiais.liso(cor.lerp(Color.WHITE, 0.3), 0.3, cor, 2.5))
	var desenho := MeshInstance3D.new()
	desenho.mesh = malha
	desenho.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(desenho)
	criar_bloco(Vector3(0, GOL_ALTURA / 2.0, linha + lado * (GOL_FUNDO + 0.5)), Vector3(GOL_LARGURA + 2.0, GOL_ALTURA, 1.0), rede)
	criar_bloco(Vector3(-(g + 0.5), GOL_ALTURA / 2.0, linha + lado * GOL_FUNDO / 2.0), Vector3(1.0, GOL_ALTURA, GOL_FUNDO), rede)
	criar_bloco(Vector3(g + 0.5, GOL_ALTURA / 2.0, linha + lado * GOL_FUNDO / 2.0), Vector3(1.0, GOL_ALTURA, GOL_FUNDO), rede)
	criar_bloco(Vector3(0, GOL_ALTURA + 0.5, linha + lado * GOL_FUNDO / 2.0), Vector3(GOL_LARGURA + 2.0, 1.0, GOL_FUNDO), rede)


func criar_chao_de_fora() -> void:
	# só pra aparecer pelo vidro: o chão em volta da arena
	var desenho := MeshInstance3D.new()
	desenho.mesh = PlaneMesh.new()
	desenho.mesh.size = Vector2(600, 600)
	desenho.position.y = -0.05
	desenho.material_override = Materiais.liso(Color(0.09, 0.1, 0.12), 0.9)
	add_child(desenho)


func criar_arquibancada() -> void:
	# estádio em volta: muro com painel de LED, corredor, degraus com a torcida, muro de trás e cobertura.
	# Vista de cima é um retângulo de cantos redondos um pouco maior que a arena (contando os gols).
	var a := LARGURA / 2.0 + 4.0
	var b := COMPRIMENTO / 2.0 + GOL_FUNDO + 3.0
	var raio := 24.0
	var volta := []   # [ponto no chão, direção pra fora, metros andados]
	var andou := 0.0
	var centros := [Vector3(a - raio, 0, -(b - raio)), Vector3(a - raio, 0, b - raio), Vector3(-(a - raio), 0, b - raio), Vector3(-(a - raio), 0, -(b - raio))]
	for c in 4:
		for k in 13:
			var angulo := deg_to_rad(-90.0 + 90.0 * c + 90.0 * k / 12.0)
			var fora := Vector3(cos(angulo), 0, sin(angulo))
			var ponto: Vector3 = centros[c] + fora * raio
			if not volta.is_empty():
				andou += ponto.distance_to(volta[-1][0])
			volta.append([ponto, fora, andou])
	volta.append([volta[0][0], volta[0][1], andou + volta[0][0].distance_to(volta[-1][0])])

	var muro := Modelagem.nova()
	var led := Modelagem.nova()
	var corredor := Modelagem.nova()
	var torcida := Modelagem.nova()
	var cobertura := Modelagem.nova()
	var luzes := Modelagem.nova()
	faixa_em_volta(muro, volta, Vector2(0, 0), Vector2(0, 4.2))
	faixa_em_volta(led, volta, Vector2(-0.05, 1.0), Vector2(-0.05, 3.4), true)
	faixa_em_volta(corredor, volta, Vector2(0, 4.2), Vector2(1.8, 4.2))
	faixa_em_volta(torcida, volta, Vector2(1.8, 4.2), Vector2(32, 26))
	faixa_em_volta(muro, volta, Vector2(32, 26), Vector2(32, 30))
	faixa_em_volta(cobertura, volta, Vector2(32, 30), Vector2(14, 33))
	faixa_em_volta(luzes, volta, Vector2(15.5, 32.7), Vector2(14, 32.95))
	var malha := ArrayMesh.new()
	Modelagem.adicionar(malha, muro, "muro", Materiais.liso(Color(0.06, 0.065, 0.08), 0.7))
	Modelagem.adicionar(malha, led, "painel de LED", Materiais.painel_de_led())
	Modelagem.adicionar(malha, corredor, "corredor", Materiais.liso(Color(0.22, 0.23, 0.25), 0.9))
	Modelagem.adicionar(malha, torcida, "torcida", Materiais.torcida())
	Modelagem.adicionar(malha, cobertura, "cobertura", Materiais.liso(Color(0.1, 0.11, 0.13), 0.5, Color.BLACK, 0.0, 0.4))
	Modelagem.adicionar(malha, luzes, "luzes", Materiais.luz(Color(1.0, 0.97, 0.9), 3.0))
	var desenho := MeshInstance3D.new()
	desenho.mesh = malha
	desenho.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(desenho)


func faixa_em_volta(st: SurfaceTool, volta: Array, de: Vector2, ate: Vector2, uv_de_0_a_1 := false) -> void:
	# um pedaço do corte do estádio [pra fora, altura] repetido em toda a volta.
	# UV: x = metros andados na volta, y = metros (ou 0 a 1) subindo pelo pedaço
	var t := ate - de
	var n2 := Vector2(-t.y, t.x).normalized()   # virado pro campo / pra cima
	var comprimento := 1.0 if uv_de_0_a_1 else t.length()
	for i in volta.size() - 1:
		var p := []
		var n := []
		var uv := []
		for canto in [[i, de, 0.0], [i + 1, de, 0.0], [i + 1, ate, comprimento], [i, ate, comprimento]]:
			var v: Array = volta[canto[0]]
			var onde: Vector2 = canto[1]
			p.append(v[0] + v[1] * onde.x + Vector3.UP * onde.y)
			n.append((v[1] * n2.x + Vector3.UP * n2.y).normalized())
			uv.append(Vector2(v[2], canto[2]))
		for k in [0, 1, 2, 0, 2, 3]:
			st.set_normal(n[k])
			st.set_uv(uv[k])
			st.add_vertex(p[k])


func criar_torre_de_luz(onde: Vector3) -> void:
	# poste alto com um painel de refletores virado pro meio do campo
	var altura := 48.0
	var estrutura := Modelagem.nova()
	var lampadas := Modelagem.nova()
	Modelagem.caixa(estrutura, Vector3(0, altura / 2.0, 0), Vector3(1.4, altura, 1.4))
	var olhar := Basis.looking_at(-Vector3(onde.x, 0, onde.z).normalized() + Vector3.DOWN * 0.45)
	var painel := Vector3(0, altura + 2.5, 0)
	Modelagem.caixa(estrutura, painel, Vector3(11.0, 6.0, 0.8), olhar)
	for linha in 3:
		for coluna in 5:
			var p := Vector3(-4.0 + 2.0 * coluna, -1.8 + 1.8 * linha, -0.45)
			Modelagem.caixa(lampadas, painel + olhar * p, Vector3(1.5, 1.3, 0.12), olhar)
	var malha := ArrayMesh.new()
	Modelagem.adicionar(malha, estrutura, "estrutura", Materiais.liso(Color(0.12, 0.13, 0.15), 0.6, Color.BLACK, 0.0, 0.5))
	Modelagem.adicionar(malha, lampadas, "lâmpadas", Materiais.luz(Color(1.0, 0.98, 0.92), 6.0))
	var desenho := MeshInstance3D.new()
	desenho.mesh = malha
	desenho.position = onde
	desenho.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
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
