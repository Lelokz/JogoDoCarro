class_name Aparencia
extends RefCounted

# Como cada um personalizou o carro. A cor principal é sempre a do time (senão não dá pra saber quem é
# de quem); o resto é escolha de cada um, por categoria (as abas do Personalizar).
# Fica salvo no PC / navegador de cada um (salva sozinho a cada clique) e vai pela rede como uma
# fileira de números pequenos: quem entra manda pro host e o host repassa no estado, junto com o carro.
# O arquivo tem versão: opção nova ganha o padrão, e o que a pessoa já tinha escolhido continua.

const ARQUIVO := "user://personalizacao.json"   # (o carro.json é do painel F1 no site)
const VERSAO := 2

const MODELOS := ["Raio", "Tanque", "Besouro", "Flecha"]
const SOBRE_MODELOS := ["Superesportivo em cunha: comprido, baixo e estreito", "Jipe de trilha: alto, quadradão e parrudo", "Bolinha retrô: tudo redondo, faróis nos para-lamas", "Fórmula de roda exposta: fino, comprido e com asas"]
const CORES := [
	["Prata", Color(0.78, 0.8, 0.84)],
	["Branco", Color(0.93, 0.94, 0.96)],
	["Grafite", Color(0.25, 0.26, 0.28)],
	["Preto", Color(0.04, 0.04, 0.05)],
	["Dourado", Color(1.0, 0.75, 0.25)],
	["Bronze", Color(0.72, 0.45, 0.25)],
	["Vermelho", Color(0.9, 0.1, 0.1)],
	["Vinho", Color(0.5, 0.06, 0.12)],
	["Laranja", Color(1.0, 0.45, 0.08)],
	["Amarelo", Color(1.0, 0.85, 0.1)],
	["Limão", Color(0.65, 0.95, 0.15)],
	["Verde", Color(0.15, 0.7, 0.25)],
	["Ciano", Color(0.1, 0.85, 0.95)],
	["Azul", Color(0.15, 0.35, 0.95)],
	["Roxo", Color(0.55, 0.25, 0.95)],
	["Rosa", Color(1.0, 0.35, 0.7)],
]
const CORES_FOGO := [
	["Laranja", Color(1.0, 0.45, 0.1)],
	["Azul", Color(0.2, 0.55, 1.0)],
	["Verde", Color(0.3, 1.0, 0.3)],
	["Roxo", Color(0.65, 0.3, 1.0)],
	["Rosa", Color(1.0, 0.3, 0.7)],
	["Amarelo", Color(1.0, 0.85, 0.15)],
	["Vermelho", Color(1.0, 0.12, 0.08)],
	["Branco", Color(0.85, 0.92, 1.0)],
	["Ciano", Color(0.1, 0.95, 0.95)],
	["Limão", Color(0.7, 1.0, 0.1)],
	["Dourado", Color(1.0, 0.7, 0.2)],
	["Magenta", Color(1.0, 0.1, 0.9)],
]
const DESENHOS := ["Nenhum", "Faixas"]
const BOOSTS := ["Fogo", "Faíscas", "Fumaça preta", "Plasma", "Laser", "Estrelinhas", "Arco-íris"]
const TETOS := ["Nenhum", "Cartola"]
const ANTENAS := ["Nenhuma", "Bandeira do time"]
const AEROFOLIOS := ["De fábrica", "Corrida"]

# cada escolha: [nome no arquivo, lista de opções]; a ordem é a da rede (não mudar, só acrescentar no fim)
const ESCOLHAS := [
	["modelo", MODELOS],
	["detalhe", CORES],
	["desenho", DESENHOS],
	["boost", BOOSTS],
	["boost_cor", CORES_FOGO],
	["teto", TETOS],
	["antena", ANTENAS],
	["aerofolio", AEROFOLIOS],
]
const PADRAO := {"modelo": 0, "detalhe": 0, "desenho": 1, "boost": 0, "boost_cor": 0, "teto": 0, "antena": 0, "aerofolio": 0}

static var salva := {}


static func minha() -> Dictionary:
	if salva.is_empty():
		salva = ler_arquivo()
	return salva.duplicate()


static func ler_arquivo() -> Dictionary:
	if not FileAccess.file_exists(ARQUIVO):
		return PADRAO.duplicate()
	var lida = JSON.parse_string(FileAccess.get_file_as_string(ARQUIVO))
	if not lida is Dictionary:
		return PADRAO.duplicate()
	if int(lida.get("versao", 1)) < 2:
		lida = da_versao_1(lida)
	return limpa(lida)


static func da_versao_1(velha: Dictionary) -> Dictionary:
	# 31/10 (manhã): era tudo junto; o "rastro" era o estilo do boost e o "enfeite" era um só
	var nova := {
		"modelo": velha.get("modelo", 0),
		"detalhe": [0, 1, 3, 4, 6, 11, 14, 15][clampi(int(velha.get("detalhe", 0)), 0, 7)],
		"desenho": 1 if int(velha.get("detalhe", 0)) > 0 else 0,
		"boost": velha.get("rastro", 0),
		"boost_cor": velha.get("fogo", 0),
	}
	match int(velha.get("enfeite", 0)):
		1:
			nova["antena"] = 1
		2:
			nova["teto"] = 1
		3:
			nova["aerofolio"] = 1
	return nova


static func limpa(escolha: Dictionary) -> Dictionary:
	# só o que existe; número fora da lista (arquivo velho, rede) vira o padrão
	var certa := {}
	for e in ESCOLHAS:
		var valor := int(escolha.get(e[0], PADRAO[e[0]]))
		certa[e[0]] = valor if valor >= 0 and valor < e[1].size() else PADRAO[e[0]]
	return certa


static func salvar(escolha: Dictionary) -> bool:
	salva = limpa(escolha)
	var dados := salva.duplicate()
	dados["versao"] = VERSAO
	var arquivo := FileAccess.open(ARQUIVO, FileAccess.WRITE)
	if arquivo == null:
		return false
	arquivo.store_string(JSON.stringify(dados, "\t"))
	arquivo.close()   # fechar na hora: no navegador é aí que ele guarda de verdade
	return true


static func navegador_guarda() -> bool:
	# no site, aba anônima ou site bloqueado não guardam nada (aí o Personalizar avisa)
	return not OS.has_feature("web") or OS.is_userfs_persistent()


static func codificar(escolha: Dictionary) -> PackedByteArray:
	var certa := limpa(escolha)
	var numeros := PackedByteArray()
	for e in ESCOLHAS:
		numeros.append(certa[e[0]])
	return numeros


static func decodificar(numeros: PackedByteArray) -> Dictionary:
	# vem da rede: o que faltar ou estiver fora da lista vira o padrão
	var escolha := {}
	for i in ESCOLHAS.size():
		if i < numeros.size():
			escolha[ESCOLHAS[i][0]] = numeros[i]
	return limpa(escolha)


static func aleatoria() -> Dictionary:
	var escolha := {}
	for e in ESCOLHAS:
		escolha[e[0]] = randi() % e[1].size()
	return escolha
