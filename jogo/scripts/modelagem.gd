class_name Modelagem
extends RefCounted

# Ferramentas pra montar modelos por código (carro, rodas, pads, arquibancada).
# As normais são calculadas aqui mesmo (os shaders desenham os dois lados do triângulo e usam a normal).

const PONTOS_CANTO := 5
# pontos de um corte (secao): 4 cantos + 1 ponto no meio de cada lado (onde a saia escura começa)
const PONTOS_CORTE := 4 * PONTOS_CANTO + 2
const LADO_DIREITO := PONTOS_CANTO
const LADO_ESQUERDO := 3 * PONTOS_CANTO + 1


static func nova() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


static func adicionar(malha: ArrayMesh, st: SurfaceTool, nome: String, material: Material) -> void:
	# peça vazia (ex.: carro sem vidro) não entra: senão o nome e o material iam pra peça de antes
	var dados := st.commit_to_arrays()
	if dados[Mesh.ARRAY_VERTEX] == null or dados[Mesh.ARRAY_VERTEX].is_empty():
		return
	malha.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, dados)
	var i := malha.get_surface_count() - 1
	malha.surface_set_name(i, nome)
	malha.surface_set_material(i, material)


static func triangulo(st: SurfaceTool, pontos: Array, normais: Array) -> void:
	for i in 3:
		st.set_normal(normais[i])
		st.add_vertex(pontos[i])


static func quadrado(st: SurfaceTool, p: Array, n: Array) -> void:
	triangulo(st, [p[0], p[1], p[2]], [n[0], n[1], n[2]])
	triangulo(st, [p[0], p[2], p[3]], [n[0], n[2], n[3]])


static func secao(s: Array) -> PackedVector3Array:
	# corte de uma peça (visto de frente): retângulo de cantos redondos, mais estreito em cima
	# s = [z, meia largura embaixo, meia largura em cima, y de baixo, y de cima, raio embaixo, raio em cima]
	# e, se tiver, [7] = altura do ponto no meio de cada lado (senão fica no meio mesmo)
	var z: float = s[0]
	var baixo := Vector2(s[1], s[3] + s[5])
	var cima := Vector2(s[2], s[4] - s[6])
	var meio := 0.5 if s.size() < 8 else clampf(inverse_lerp(baixo.y, cima.y, s[7]), 0.0, 1.0)
	var lado := baixo.lerp(cima, meio)
	var cantos := [
		[Vector2(s[1] - s[5], s[3] + s[5]), s[5], -90.0],
		[Vector2(s[2] - s[6], s[4] - s[6]), s[6], 0.0],
		[Vector2(-(s[2] - s[6]), s[4] - s[6]), s[6], 90.0],
		[Vector2(-(s[1] - s[5]), s[3] + s[5]), s[5], 180.0],
	]
	var pontos := PackedVector3Array()
	for c in 4:
		for k in PONTOS_CANTO:
			var a := deg_to_rad(cantos[c][2] + 90.0 * k / (PONTOS_CANTO - 1))
			var p: Vector2 = cantos[c][0] + Vector2(cos(a), sin(a)) * cantos[c][1]
			pontos.append(Vector3(p.x, p.y, z))
		if c == 0:
			pontos.append(Vector3(lado.x, lado.y, z))
		elif c == 2:
			pontos.append(Vector3(-lado.x, lado.y, z))
	return pontos


static func costurar(st: SurfaceTool, cortes: Array, indices: Array) -> void:
	# liga um corte no outro (de frente pra trás), só com os pontos da lista (uma parte da volta)
	for k in cortes.size() - 1:
		for j in indices.size() - 1:
			var i0: int = indices[j]
			var i1: int = indices[j + 1]
			var p := [cortes[k][i0], cortes[k][i1], cortes[k + 1][i1], cortes[k + 1][i0]]
			var n := [normal_do_corte(cortes, k, i0), normal_do_corte(cortes, k, i1), normal_do_corte(cortes, k + 1, i1), normal_do_corte(cortes, k + 1, i0)]
			quadrado(st, p, n)


static func normal_do_corte(cortes: Array, k: int, i: int) -> Vector3:
	var corte: PackedVector3Array = cortes[k]
	var total := corte.size()
	var ao_redor := corte[(i + 1) % total] - corte[(i - 1 + total) % total]
	var ao_longo: Vector3 = cortes[mini(k + 1, cortes.size() - 1)][i] - cortes[maxi(k - 1, 0)][i]
	var n := ao_redor.cross(ao_longo).normalized()
	var centro := Vector3.ZERO
	for p in corte:
		centro += p
	centro /= total
	return -n if n.dot(corte[i] - centro) < 0.0 else n


static func tampa(st: SurfaceTool, corte: PackedVector3Array, para_fora: Vector3, bojo := 0.0) -> void:
	# fecha a ponta de uma peça com um leque de triângulos (bojo = quanto o meio sai pra fora)
	var centro := Vector3.ZERO
	for p in corte:
		centro += p
	centro = centro / corte.size() + para_fora * bojo
	for i in corte.size():
		triangulo(st, [centro, corte[i], corte[(i + 1) % corte.size()]], [para_fora, para_fora, para_fora])


static func indices(de: int, ate: int, total: int) -> Array:
	# de "de" até "ate" dando a volta se precisar (de 0 até total = a volta inteira)
	var lista := []
	for i in range(de, ate + 1):
		lista.append(i % total)
	return lista


static func caixa(st: SurfaceTool, centro: Vector3, tamanho: Vector3, giro := Basis()) -> void:
	var metade := tamanho / 2.0
	var eixos := [Vector3.RIGHT, Vector3.UP, Vector3.BACK]
	for e in 3:
		for lado in [-1.0, 1.0]:
			var n: Vector3 = eixos[e] * lado
			var u: Vector3 = eixos[(e + 1) % 3]
			var v: Vector3 = eixos[(e + 2) % 3]
			var base := n * metade[e]
			var du := u * metade[(e + 1) % 3]
			var dv := v * metade[(e + 2) % 3]
			var p := [base - du - dv, base + du - dv, base + du + dv, base - du + dv]
			for i in 4:
				p[i] = centro + giro * p[i]
			var nn := (giro * n).normalized()
			quadrado(st, p, [nn, nn, nn, nn])


static func torno(st: SurfaceTool, perfil: Array, lados: int, onde := Transform3D()) -> void:
	# peça redonda (pneu, aro, pad): gira o perfil [raio, altura] em volta do eixo Y.
	# O lado de fora fica à direita de quem anda pelo perfil.
	var normais := []
	for j in perfil.size():
		var antes: Vector2 = perfil[maxi(j - 1, 0)]
		var depois: Vector2 = perfil[mini(j + 1, perfil.size() - 1)]
		var t := depois - antes
		normais.append(Vector2(t.y, -t.x).normalized())
	for k in lados:
		var a0 := TAU * k / lados
		var a1 := TAU * (k + 1) / lados
		for j in perfil.size() - 1:
			var p := [ponto_torno(perfil[j], a0), ponto_torno(perfil[j], a1), ponto_torno(perfil[j + 1], a1), ponto_torno(perfil[j + 1], a0)]
			var n := [ponto_torno(normais[j], a0), ponto_torno(normais[j], a1), ponto_torno(normais[j + 1], a1), ponto_torno(normais[j + 1], a0)]
			for i in 4:
				p[i] = onde * p[i]
				n[i] = (onde.basis * n[i]).normalized()
			quadrado(st, p, n)


static func ponto_torno(p: Vector2, angulo: float) -> Vector3:
	return Vector3(p.x * cos(angulo), p.y, p.x * sin(angulo))


static func espelhar(perfil: Array) -> Array:
	# o mesmo perfil do outro lado (altura trocada de sinal), mantendo o lado de fora à direita
	var outro := []
	for p in perfil:
		outro.push_front(Vector2(p.x, -p.y))
	return outro


static func tubo(st: SurfaceTool, de: Vector3, ate: Vector3, raio: float, lados := 10) -> void:
	# cano reto de "de" até "ate", com as pontas fechadas
	var u := (ate - de).normalized()
	var ref := Vector3.UP if absf(u.y) < 0.9 else Vector3.BACK
	var x := u.cross(ref).normalized()
	var comprimento := de.distance_to(ate)
	var perfil := [Vector2(0, 0), Vector2(raio, 0), Vector2(raio, 0), Vector2(raio, comprimento), Vector2(raio, comprimento), Vector2(0, comprimento)]
	torno(st, perfil, lados, Transform3D(Basis(x, u, x.cross(u)), de))
