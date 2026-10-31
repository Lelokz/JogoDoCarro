class_name Aparencia
extends RefCounted

# Como cada um personalizou o carro: modelo, cor dos detalhes (faixas e rodas), cor do fogo do boost,
# tipo de rastro e enfeite. A cor principal é sempre a do time (senão não dá pra saber quem é de quem).
# Fica salvo no PC / navegador de cada um e vai pela rede como um número só: quem entra manda pro host
# e o host repassa no estado, junto com o carro.
# É só aparência: todos os carros têm a mesma física e a mesma caixa de batida.

const ARQUIVO := "user://personalizacao.json"   # (o carro.json é do painel F1 no site)
const MODELOS := ["Raio", "Tanque"]
const SOBRE_MODELOS := ["Superesportivo em cunha: comprido, baixo e estreito", "Jipe de trilha: alto, quadradão e parrudo"]
const DETALHES := [
	["Nenhum", Color(0.78, 0.8, 0.84)],
	["Branco", Color(0.92, 0.93, 0.95)],
	["Preto", Color(0.05, 0.05, 0.06)],
	["Dourado", Color(1.0, 0.75, 0.25)],
	["Vermelho", Color(0.9, 0.1, 0.1)],
	["Verde", Color(0.3, 0.85, 0.2)],
	["Roxo", Color(0.55, 0.25, 0.95)],
	["Rosa", Color(1.0, 0.35, 0.7)],
]
const FOGOS := [
	["Laranja", Color(1.0, 0.45, 0.1)],
	["Azul", Color(0.2, 0.55, 1.0)],
	["Verde", Color(0.3, 1.0, 0.3)],
	["Roxo", Color(0.65, 0.3, 1.0)],
	["Rosa", Color(1.0, 0.3, 0.7)],
	["Amarelo", Color(1.0, 0.85, 0.15)],
	["Vermelho", Color(1.0, 0.12, 0.08)],
	["Branco", Color(0.85, 0.92, 1.0)],
]
const RASTROS := ["Fogo", "Faíscas", "Fumaça"]
const ENFEITES := ["Nenhum", "Antena", "Chapéu", "Aerofólio"]
const PADRAO := {"modelo": 0, "detalhe": 0, "fogo": 0, "rastro": 0, "enfeite": 0}

static var salva := {}


static func minha() -> Dictionary:
	if salva.is_empty():
		salva = PADRAO.duplicate()
		if FileAccess.file_exists(ARQUIVO):
			var lida = JSON.parse_string(FileAccess.get_file_as_string(ARQUIVO))
			if lida is Dictionary:
				salva = decodificar(codificar(lida))
	return salva.duplicate()


static func salvar(escolha: Dictionary) -> void:
	salva = escolha.duplicate()
	var arquivo := FileAccess.open(ARQUIVO, FileAccess.WRITE)
	if arquivo:
		arquivo.store_string(JSON.stringify(salva, "\t"))


static func codificar(escolha: Dictionary) -> int:
	var e := PADRAO.duplicate()
	e.merge(escolha, true)
	return int(e.modelo) + 8 * (int(e.detalhe) + 16 * (int(e.fogo) + 16 * (int(e.rastro) + 4 * int(e.enfeite))))


static func decodificar(numero: int) -> Dictionary:
	# vem da rede: qualquer coisa fora da lista vira o padrão
	return {
		"modelo": dentro(numero % 8, MODELOS),
		"detalhe": dentro(numero / 8 % 16, DETALHES),
		"fogo": dentro(numero / 128 % 16, FOGOS),
		"rastro": dentro(numero / 2048 % 4, RASTROS),
		"enfeite": dentro(numero / 8192 % 8, ENFEITES),
	}


static func dentro(i: int, lista: Array) -> int:
	return i if i >= 0 and i < lista.size() else 0


static func aleatoria() -> Dictionary:
	return {
		"modelo": randi() % MODELOS.size(),
		"detalhe": randi() % DETALHES.size(),
		"fogo": randi() % FOGOS.size(),
		"rastro": randi() % RASTROS.size(),
		"enfeite": randi() % ENFEITES.size(),
	}
