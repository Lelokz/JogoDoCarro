class_name Lataria
extends RefCounted

# Carroceria lisa feita por curvas (o jeito de modelar os carros).
# Cada peça (corpo, cabine) é descrita como um projetista desenha um carro:
#   "topo"    [[z, y], ...]  linha de cima, vista de lado
#   "fundo"   [[z, y], ...]  linha de baixo, vista de lado (os arcos das rodas são recortados nela)
#   "cintura" [[z, y], ...]  altura onde a lateral é mais larga
#   "largura" [[z, m], ...]  meia largura na cintura, vista de cima
#   "ombro"   [[z, f], ...]  quanto o lado estreita até em cima (1 = reto, 0,6 = bem inclinado)
#   "forma"   [[z, n], ...]  2 = redondo, 4 = arredondado, 10 = quadradão
#   "saia"    [[z, y], ...]  abaixo disso é plástico escuro (opcional)
#   "reto": true             sem curvas entre os pontos e faces lisas (carro anguloso)
# z vai da frente (-) pra trás (+), como o carro (a frente é o -Z).

const VOLTA := 32        # pontos em cada corte
const FATIAS := 64       # cortes de ponta a ponta


static func valor(curva: Array, z: float, reto := false) -> float:
	# passa pelos pontos; entre eles, curva suave (Catmull-Rom) ou reta
	if z <= curva[0][0]:
		return curva[0][1]
	if z >= curva[-1][0]:
		return curva[-1][1]
	var i := 0
	while z > curva[i + 1][0]:
		i += 1
	var a: Array = curva[i]
	var b: Array = curva[i + 1]
	var t: float = (z - a[0]) / (b[0] - a[0])
	if reto:
		return lerpf(a[1], b[1], t)
	var antes: float = curva[maxi(i - 1, 0)][1]
	var depois: float = curva[mini(i + 2, curva.size() - 1)][1]
	var y: float = 0.5 * ((2.0 * a[1]) + (-antes + b[1]) * t + (2.0 * antes - 5.0 * a[1] + 4.0 * b[1] - depois) * t * t + (-antes + 3.0 * a[1] - 3.0 * b[1] + depois) * t * t * t)
	# não deixa a curva passar dos pontos vizinhos (senão faz ondinha)
	return clampf(y, minf(a[1], b[1]) - 0.01, maxf(a[1], b[1]) + 0.01)


static func fundo_com_arcos(peca: Dictionary, z: float, arcos: Array) -> float:
	var y := valor(peca.fundo, z, peca.get("reto", false))
	for arco in arcos:
		# arco = [z da roda, y do centro, raio]: recorta a lataria por cima da roda
		var dz: float = z - arco[0]
		if absf(dz) < arco[2]:
			y = maxf(y, arco[1] + sqrt(arco[2] * arco[2] - dz * dz))
	return y


static func corte(peca: Dictionary, z: float, arcos: Array) -> PackedVector3Array:
	var pontos := PackedVector3Array()
	for k in VOLTA:
		# começa embaixo no meio, sobe pela direita, passa por cima e desce pela esquerda
		pontos.append(ponto(peca, z, TAU * k / VOLTA - PI / 2.0, arcos))
	return pontos


static func ponto(peca: Dictionary, z: float, a: float, arcos := []) -> Vector3:
	# um ponto da lataria no corte z; a = ângulo em volta (0 = lado direito na cintura, PI/2 = em cima)
	var reto: bool = peca.get("reto", false)
	var topo := valor(peca.topo, z, reto)
	var fundo := fundo_com_arcos(peca, z, arcos)
	var cintura := clampf(valor(peca.cintura, z, reto), fundo + 0.008, topo - 0.008)
	var largura := valor(peca.largura, z, reto)
	var ombro := valor(peca.ombro, z, reto) if peca.has("ombro") else 1.0
	var n := valor(peca.forma, z, reto)
	var c := cos(a)
	var s := sin(a)
	var x := signf(c) * pow(absf(c), 2.0 / n) * largura
	var y: float
	if s >= 0.0:
		var sobe := pow(s, 2.0 / n)
		y = cintura + (topo - cintura) * sobe
		x *= lerpf(1.0, ombro, sobe)
	else:
		y = cintura - (cintura - fundo) * pow(-s, 2.0 / n)
		x *= 0.97
	return Vector3(x + peca.get("x", 0.0), y, z)


static func cortes(peca: Dictionary, arcos: Array) -> Array:
	var lista := []
	var z0: float = peca.topo[0][0]
	var z1: float = peca.topo[-1][0]
	for f in FATIAS + 1:
		var z := lerpf(z0, z1, float(f) / FATIAS)
		lista.append(corte(peca, z, arcos))
	return lista


static func montar(peca: Dictionary, arcos: Array, escolher: Callable) -> void:
	# costura os cortes; escolher(centro, normal) devolve em qual SurfaceTool vai cada quadradinho
	var lista := cortes(peca, arcos)
	var liso: bool = not peca.get("reto", false)
	var centros := []
	for c in lista:
		var soma := Vector3.ZERO
		for p in c:
			soma += p
		centros.append(soma / VOLTA)
	for f in lista.size() - 1:
		for k in VOLTA:
			var k2 := (k + 1) % VOLTA
			var p := [lista[f][k], lista[f][k2], lista[f + 1][k2], lista[f + 1][k]]
			var face: Vector3 = (p[1] - p[0]).cross(p[3] - p[0])
			if face.length() < 1e-9:
				face = (p[2] - p[1]).cross(p[3] - p[1])
			face = face.normalized()
			var centro: Vector3 = (p[0] + p[1] + p[2] + p[3]) / 4.0
			if face.dot(centro - (centros[f] + centros[f + 1]) / 2.0) < 0.0:
				face = -face
			var n := [face, face, face, face]
			if liso:
				n = [normal(lista, f, k), normal(lista, f, k2), normal(lista, f + 1, k2), normal(lista, f + 1, k)]
			var st: SurfaceTool = escolher.call(centro, face)
			if st:
				Modelagem.quadrado(st, p, n)
	# fecha a frente e a traseira
	for ponta in [[lista[0], Vector3.FORWARD], [lista[-1], Vector3.BACK]]:
		var st: SurfaceTool = escolher.call(ponta[0][0], ponta[1])
		if st:
			Modelagem.tampa(st, ponta[0], ponta[1])


static func normal(lista: Array, f: int, k: int) -> Vector3:
	var corte_: PackedVector3Array = lista[f]
	var ao_redor := corte_[(k + 1) % VOLTA] - corte_[(k - 1 + VOLTA) % VOLTA]
	var ao_longo: Vector3 = lista[mini(f + 1, lista.size() - 1)][k] - lista[maxi(f - 1, 0)][k]
	var n := ao_redor.cross(ao_longo)
	if n.length() < 1e-9:
		return Vector3.FORWARD if f == 0 else Vector3.BACK
	n = n.normalized()
	var centro := Vector3.ZERO
	for p in corte_:
		centro += p
	centro /= VOLTA
	return -n if n.dot(corte_[k] - centro) < 0.0 else n
