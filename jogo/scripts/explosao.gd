class_name Explosao
extends Node3D

# Explosão (demolição e gol): um clarão que cresce e some, faíscas na cor do time e fumaça.
# Usa o mesmo material do rastro do boost (cor de cada partícula), então não cria shader novo
# pro navegador compilar. Some sozinha depois de uns segundos.

var cor := Color(1.0, 0.55, 0.15)
var tamanho := 1.0   # 1 = demolição; o gol usa mais
var tempo := 0.0


static func criar(onde: Node, posicao: Vector3, cor_: Color, tamanho_: float) -> Explosao:
	var e := Explosao.new()
	e.cor = cor_
	e.tamanho = tamanho_
	onde.add_child(e)
	e.global_position = posicao
	return e


func _ready() -> void:
	# clarão: uma bola só que cresce rápido e apaga
	var clarao := emissor(1, 0.45, 1.0, 0.0, 0.0, 28)
	clarao.scale_amount_min = 1.2 * tamanho
	clarao.scale_amount_max = 1.2 * tamanho
	clarao.scale_amount_curve = curva([0.0, 0.4], [0.35, 1.0], [1.0, 1.3])
	# cores acima de 1 = brilham (o bloom da arena acende em volta)
	clarao.color_ramp = degrade([cor.lerp(Color.WHITE, 0.75) * 5.0, cor * 3.0, cor * 1.5], [1.0, 0.7, 0.0])
	# faíscas pra todo lado, caindo
	var faiscas := emissor(int(60 * sqrt(tamanho)), 0.9, 0.12, 6.0 * tamanho, 16.0 * tamanho)
	faiscas.spread = 180.0
	faiscas.gravity = Vector3(0, -12, 0)
	faiscas.scale_amount_min = 0.6
	faiscas.color_ramp = degrade([Color(1.0, 0.95, 0.7) * 6.0, cor * 3.0, cor], [1.0, 1.0, 0.0])
	# fumaça subindo devagar
	var fumaca := emissor(int(16 * sqrt(tamanho)), 1.8, 0.5 * sqrt(tamanho), 1.0, 3.0 * tamanho)
	fumaca.spread = 180.0
	fumaca.gravity = Vector3(0, 1.5, 0)
	fumaca.scale_amount_min = 0.8
	fumaca.scale_amount_max = 1.6
	fumaca.color_ramp = degrade([Color(0.5, 0.45, 0.4), Color(0.3, 0.3, 0.32), Color(0.25, 0.25, 0.27)], [0.0, 0.3, 0.0])


func emissor(quantos: int, vida: float, raio: float, velocidade_min: float, velocidade_max: float, lados := 12) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = maxi(quantos, 1)
	p.lifetime = vida
	p.one_shot = true
	p.explosiveness = 1.0
	p.local_coords = false
	p.direction = Vector3.UP
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = velocidade_min
	p.initial_velocity_max = velocidade_max
	var bolinha := SphereMesh.new()
	bolinha.radius = raio
	bolinha.height = raio * 2.0
	bolinha.radial_segments = lados
	bolinha.rings = lados / 2
	bolinha.material = Materiais.rastro()
	p.mesh = bolinha
	p.emitting = true
	add_child(p)
	return p


func curva(a: Array, b: Array, c: Array) -> Curve:
	var k := Curve.new()
	k.max_value = 2.0
	for ponto in [a, b, c]:
		k.add_point(Vector2(ponto[0], ponto[1]))
	return k


func degrade(cores: Array, alfas: Array) -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	var lista := PackedColorArray()
	for i in 3:
		lista.append(Color(cores[i], alfas[i]))
	g.colors = lista
	return g


func _process(delta: float) -> void:
	tempo += delta
	if tempo > 3.0:
		queue_free()
