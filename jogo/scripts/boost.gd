class_name Boost
extends Node3D

# O efeito do boost, preso no escapamento de cada carro (a frente do carro é o -Z, então sai pro +Z).
# Cada estilo é uma mistura de: chama em cone (malha que treme, miolo branco e ponta colorida),
# partículas que ficam no mundo (labaredas, faíscas, fumaça, anéis, estrelas) e feixes (laser).
# Tudo com o material do rastro (mesmo shader de sempre: nada novo pro navegador compilar).

var estilo := 0
var cor := Color(1.0, 0.45, 0.1)
var ligado := false
var forca := 0.0                # 0 a 1: liga e desliga em uns centésimos, sem estalo
var tempo := 0.0
var particulas: Array[CPUParticles3D] = []
var chamas: Array[MeshInstance3D] = []   # cones e feixes: tremem e somem quando desliga
var tamanhos := []                       # tamanho normal de cada chama


func montar(estilo_: int, cor_: Color) -> void:
	estilo = estilo_
	cor = cor_
	for filho in get_children():
		filho.queue_free()
	particulas.clear()
	chamas.clear()
	tamanhos.clear()
	var claro := cor.lerp(Color.WHITE, 0.6)
	match Aparencia.BOOSTS[estilo]:
		"Fogo":
			# três cones de chama encaixados: miolo claro e curto, corpo na cor, ponta avermelhada e comprida
			var quente := cor.lerp(Color(1.0, 0.95, 0.6), 0.5)
			var ponta := ponta_cone(cor)
			cone(0.32, 0.04, Color(1.0, 0.97, 0.85), quente, 1.6)
			cone(0.62, 0.068, quente, cor, 1.2)
			cone(1.0, 0.095, cor, ponta, 0.9)
			# línguas de fogo finas e esticadas na direção que saem
			var linguas := emissor(50, 0.17, lingua(), 5.0, 8.0, 11.0)
			linguas.particle_flag_align_y = true
			linguas.scale_amount_min = 0.6
			linguas.scale_amount_max = 1.2
			linguas.scale_amount_curve = curva([[0.0, 1.0], [1.0, 0.3]])
			linguas.color_ramp = degrade([[0.0, quente * 1.2, 0.55], [0.5, cor * 1.0, 0.4], [1.0, ponta * 0.6, 0.0]])
			faiscas(16, 1.0)
		"Faíscas":
			cone(0.35, 0.05, claro, cor, 2.0)
			faiscas(110, 1.6)
		"Fumaça preta":
			cone(0.32, 0.055, claro, cor, 2.0)
			var fumaca := emissor(70, 1.1, bola(0.09, 10), 2.0, 4.5, 14.0)
			fumaca.gravity = Vector3(0, 1.5, 0)
			fumaca.scale_amount_curve = curva([[0.0, 0.5], [0.3, 1.4], [1.0, 2.6]])
			fumaca.color_ramp = degrade([[0.0, cor * 1.4, 0.8], [0.12, Color(0.12, 0.11, 0.1), 0.85], [0.6, Color(0.06, 0.06, 0.07), 0.55], [1.0, Color(0.05, 0.05, 0.06), 0.0]])
		"Plasma":
			cone(1.0, 0.03, claro, cor, 2.4)
			cone(0.55, 0.07, cor, cor, 1.5)
			var aneis := emissor(12, 0.45, anel(), 6.0, 6.0, 0.0)
			aneis.scale_amount_curve = curva([[0.0, 0.6], [1.0, 2.2]])
			aneis.color_ramp = degrade([[0.0, claro * 2.2, 1.0], [0.5, cor * 2.0, 0.7], [1.0, cor * 1.2, 0.0]])
			labaredas(60, 0.3, 0.03, [[0.0, claro * 2.2, 1.0], [0.5, cor * 2.0, 0.8], [1.0, cor, 0.0]])
		"Laser":
			for x in [-0.03, 0.03]:
				feixe(Vector3(x, 0.0, 0.0), 1.8, 0.014, claro, 3.0)
				feixe(Vector3(x, 0.0, 0.0), 1.8, 0.045, cor, 1.8)
			labaredas(40, 0.35, 0.025, [[0.0, claro * 2.5, 1.0], [1.0, cor * 2.0, 0.0]])
		"Estrelinhas":
			cone(0.3, 0.05, claro, cor, 2.0)
			var estrelas := emissor(45, 0.7, estrela(), 3.0, 6.0, 22.0)
			estrelas.angular_velocity_min = -400.0
			estrelas.angular_velocity_max = 400.0
			estrelas.particle_flag_rotate_y = true
			estrelas.scale_amount_min = 0.7
			estrelas.scale_amount_max = 1.3
			estrelas.color_ramp = degrade([[0.0, claro * 2.2, 1.0], [0.3, cor * 2.0, 1.0], [1.0, cor * 1.4, 0.0]])
		"Arco-íris":
			cone(0.3, 0.05, Color(1.0, 0.95, 0.9), Color(1.0, 0.8, 0.6), 2.0)
			var arco := emissor(140, 0.6, bola(0.07, 8), 5.0, 7.5, 5.0)
			arco.scale_amount_curve = curva([[0.0, 1.0], [1.0, 0.5]])
			var cores := Gradient.new()
			cores.offsets = PackedFloat32Array([0.0, 0.2, 0.4, 0.6, 0.8, 1.0])
			cores.colors = PackedColorArray([Color(1, 0.1, 0.1) * 1.8, Color(1, 0.55, 0.05) * 1.8, Color(1, 0.95, 0.1) * 1.8, Color(0.2, 1, 0.3) * 1.8, Color(0.2, 0.5, 1) * 1.8, Color(0.7, 0.2, 1) * 1.8])
			arco.color_initial_ramp = cores
			arco.color_ramp = degrade([[0.0, Color.WHITE, 1.0], [0.7, Color.WHITE, 0.8], [1.0, Color.WHITE, 0.0]])
	for p in particulas:
		p.emitting = ligado


func _process(delta: float) -> void:
	tempo += delta
	forca = move_toward(forca, 1.0 if ligado else 0.0, delta * 14.0)
	for p in particulas:
		p.emitting = ligado
	# as chamas tremem: comprimento e grossura mudam um pouco a cada quadro
	for i in chamas.size():
		var c := chamas[i]
		c.visible = forca > 0.01
		var tremor := 0.85 + 0.15 * sin(tempo * 47.0 + i * 1.7) + randf_range(-0.12, 0.12)
		var grossura := forca * (0.92 + randf_range(0.0, 0.16))
		c.scale = Vector3(grossura, grossura, forca * tremor)


func ponta_cone(c: Color) -> Color:
	return c.lerp(Color(0.9, 0.12, 0.05), 0.45)


func emissor(quantos: int, vida: float, malha: Mesh, velocidade_min: float, velocidade_max: float, abertura: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = quantos
	p.lifetime = vida
	p.local_coords = false
	p.direction = Vector3.BACK
	p.spread = abertura
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = velocidade_min
	p.initial_velocity_max = velocidade_max
	p.mesh = malha
	p.emitting = false
	add_child(p)
	particulas.append(p)
	return p


func labaredas(quantas: int, vida: float, raio: float, cores: Array) -> void:
	# bolinhas rápidas que saem quentes (brancas) e esfriam na cor escolhida
	var p := emissor(quantas, vida, bola(raio, 8), 6.0, 9.5, 7.0)
	p.scale_amount_curve = curva([[0.0, 1.0], [0.5, 0.75], [1.0, 0.25]])
	p.color_ramp = degrade(cores)


func faiscas(quantas: int, forca_: float) -> void:
	var p := emissor(quantas, 0.55, risco(), 4.0 * forca_, 10.0 * forca_, 28.0)
	p.gravity = Vector3(0, -7, 0)
	p.particle_flag_align_y = true
	p.color_ramp = degrade([[0.0, Color(1.0, 0.95, 0.8) * 2.5, 1.0], [0.4, cor.lerp(Color.WHITE, 0.3) * 2.0, 1.0], [1.0, cor * 1.2, 0.0]])


func cone(comprimento: float, raio: float, cor_base: Color, cor_ponta: Color, brilho: float) -> void:
	# chama: cone deitado pro +Z, base opaca e ponta sumindo (as cores ficam nos vértices)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lados := 14
	var aneis := [[0.0, 1.0, 0.0], [0.25, 0.95, 0.15], [0.6, 0.6, 0.55], [1.0, 0.0, 1.0]]   # [onde, largura, quanto já virou a cor da ponta]
	for k in aneis.size() - 1:
		var a: Array = aneis[k]
		var b: Array = aneis[k + 1]
		var cor_a := Color(cor_base.lerp(cor_ponta, a[2]), 1.0 - a[0] * 0.95)
		var cor_b := Color(cor_base.lerp(cor_ponta, b[2]), 1.0 - b[0] * 0.95 if k + 1 < aneis.size() - 1 else 0.0)
		for j in lados:
			var t0 := TAU * j / lados
			var t1 := TAU * (j + 1) / lados
			var p := [Vector3(cos(t0) * raio * a[1], sin(t0) * raio * a[1], comprimento * a[0]),
				Vector3(cos(t1) * raio * a[1], sin(t1) * raio * a[1], comprimento * a[0]),
				Vector3(cos(t1) * raio * b[1], sin(t1) * raio * b[1], comprimento * b[0]),
				Vector3(cos(t0) * raio * b[1], sin(t0) * raio * b[1], comprimento * b[0])]
			var cores := [cor_a, cor_a, cor_b, cor_b]
			for i in [0, 1, 2, 0, 2, 3]:
				st.set_color(cores[i])
				st.set_normal(Vector3(p[i].x, p[i].y, 0.0).normalized())
				st.add_vertex(p[i])
	var m := MeshInstance3D.new()
	m.mesh = st.commit()
	m.material_override = Materiais.rastro(brilho, 1.0)
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.visible = false
	add_child(m)
	chamas.append(m)


func feixe(onde: Vector3, comprimento: float, grossura: float, cor_: Color, brilho: float) -> void:
	# laser: caixinha comprida que some na ponta
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var g := grossura / 2.0
	var cantos := [Vector2(-g, -g), Vector2(g, -g), Vector2(g, g), Vector2(-g, g)]
	for j in 4:
		var c0: Vector2 = cantos[j]
		var c1: Vector2 = cantos[(j + 1) % 4]
		var p := [Vector3(c0.x, c0.y, 0.0), Vector3(c1.x, c1.y, 0.0), Vector3(c1.x, c1.y, comprimento), Vector3(c0.x, c0.y, comprimento)]
		var cores := [Color(cor_, 1.0), Color(cor_, 1.0), Color(cor_, 0.0), Color(cor_, 0.0)]
		for i in [0, 1, 2, 0, 2, 3]:
			st.set_color(cores[i])
			st.set_normal(Vector3(p[i].x, p[i].y, 0.0).normalized())
			st.add_vertex(p[i])
	var m := MeshInstance3D.new()
	m.mesh = st.commit()
	m.material_override = Materiais.rastro(brilho)
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.position = onde
	m.visible = false
	add_child(m)
	chamas.append(m)


func bola(raio: float, lados: int) -> SphereMesh:
	# bolinha de borda esfumaçada (junta várias, vira chama ou nuvem, não bolha)
	var m := SphereMesh.new()
	m.radius = raio
	m.height = raio * 2.0
	m.radial_segments = maxi(lados, 12)
	m.rings = maxi(lados / 2, 6)
	m.material = Materiais.rastro(1.0, 1.0)
	return m


func lingua() -> SphereMesh:
	# bolinha bem esticada no Y (com align_y, fica deitada na direção que voa), borda esfumaçada
	var m := SphereMesh.new()
	m.radius = 0.024
	m.height = 0.2
	m.radial_segments = 10
	m.rings = 6
	m.material = Materiais.rastro(1.0, 1.0)
	return m


func risco() -> BoxMesh:
	var m := BoxMesh.new()
	m.size = Vector3(0.012, 0.14, 0.012)
	m.material = Materiais.rastro()
	return m


func anel() -> ArrayMesh:
	# anel em pé (de frente pra trás do carro), raio 0,1
	var st := Modelagem.nova()
	Modelagem.torno(st, [Vector2(0.085, 0.0), Vector2(0.1, 0.008), Vector2(0.11, 0.0), Vector2(0.1, -0.008), Vector2(0.085, 0.0)], 28, Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3.ZERO))
	var malha := ArrayMesh.new()
	Modelagem.adicionar(malha, st, "anel", Materiais.rastro())
	return malha


func estrela() -> ArrayMesh:
	# estrela chata de 5 pontas
	var st := Modelagem.nova()
	var centro := Vector3.ZERO
	for k in 10:
		var a0 := TAU * k / 10.0
		var a1 := TAU * (k + 1) / 10.0
		var r0 := 0.07 if k % 2 == 0 else 0.03
		var r1 := 0.03 if k % 2 == 0 else 0.07
		Modelagem.triangulo(st, [centro, Vector3(cos(a0) * r0, sin(a0) * r0, 0.0), Vector3(cos(a1) * r1, sin(a1) * r1, 0.0)], [Vector3.BACK, Vector3.BACK, Vector3.BACK])
	var malha := ArrayMesh.new()
	Modelagem.adicionar(malha, st, "estrela", Materiais.rastro())
	return malha


func curva(pontos: Array) -> Curve:
	var k := Curve.new()
	k.max_value = 3.0
	for ponto in pontos:
		k.add_point(Vector2(ponto[0], ponto[1]))
	return k


func degrade(pontos: Array) -> Gradient:
	# [[onde, cor, transparência], ...]
	var g := Gradient.new()
	var onde := PackedFloat32Array()
	var lista := PackedColorArray()
	for ponto in pontos:
		onde.append(ponto[0])
		lista.append(Color(ponto[1], ponto[2]))
	g.offsets = onde
	g.colors = lista
	return g
