class_name Materiais
extends RefCounted

# Todos os materiais do jogo saem daqui, de só dois shaders (sólido e transparente).
# Medido em 30/10/2026: cada shader diferente custava ~1 s pro navegador compilar na primeira
# vez que o jogo abria; com tudo em dois, o "Treinar sozinho" abre na hora.

const SOLIDO := preload("res://shaders/superficie.gdshader")
const TRANSPARENTE := preload("res://shaders/transparente.gdshader")


static func liso(cor: Color, aspereza := 0.8, brilho := Color.BLACK, forca_brilho := 0.0, metal := 0.0) -> ShaderMaterial:
	var m := novo(SOLIDO, 1)
	m.set_shader_parameter("cor", cor)
	m.set_shader_parameter("aspereza", aspereza)
	m.set_shader_parameter("brilho", brilho)
	m.set_shader_parameter("forca_brilho", forca_brilho)
	m.set_shader_parameter("metal", metal)
	return m


static func luz(cor: Color, forca := 4.0) -> ShaderMaterial:
	return liso(cor, 0.4, cor, forca)


static func gramado(metade_comprimento: float, meia_largura: float, meia_largura_gol: float) -> ShaderMaterial:
	var m := novo(SOLIDO, 0)
	m.set_shader_parameter("metade_comprimento", metade_comprimento)
	m.set_shader_parameter("meia_largura", meia_largura)
	m.set_shader_parameter("meia_largura_gol", meia_largura_gol)
	return m


static func torcida() -> ShaderMaterial:
	return novo(SOLIDO, 4)


static func painel_de_led() -> ShaderMaterial:
	return novo(SOLIDO, 5)


static func rede(cor: Color) -> ShaderMaterial:
	var m := novo(TRANSPARENTE, 3)
	m.set_shader_parameter("cor", Color(cor.r, cor.g, cor.b, 0.06))
	return m


static func bola() -> ShaderMaterial:
	var m := novo(SOLIDO, 2)
	m.set_shader_parameter("aspereza", 0.5)
	return m


static func grade() -> ShaderMaterial:
	var m := novo(SOLIDO, 3)
	m.set_shader_parameter("aspereza", 0.9)
	return m


static func vidro(altura_teto: float) -> ShaderMaterial:
	var m := novo(TRANSPARENTE, 0)
	m.set_shader_parameter("altura_teto", altura_teto)
	return m


static func transparente(cor: Color) -> ShaderMaterial:
	var m := novo(TRANSPARENTE, 1)
	m.set_shader_parameter("cor", cor)
	return m


static func rastro(forca_luz := 1.0, suave := 0.0) -> ShaderMaterial:
	# partículas e chamas: a cor de cada uma (dos vértices) brilha sozinha; suave = borda esfumaçada
	var m := novo(TRANSPARENTE, 2)
	m.set_shader_parameter("forca_luz", forca_luz)
	m.set_shader_parameter("suave", suave)
	return m


static func novo(shader: Shader, tipo: int) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader
	m.set_shader_parameter("tipo", tipo)
	return m
