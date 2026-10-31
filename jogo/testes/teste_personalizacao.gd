extends SceneTree

# Roda sem tela: godot --headless --path jogo -s res://testes/teste_personalizacao.gd
# Salva, "fecha" (esquece o que tinha na memória) e abre de novo; converte o arquivo da versão 1;
# e a fileira de números da rede volta igual. Usa um arquivo de teste e devolve o de verdade no fim.

func _initialize() -> void:
	var ap: GDScript = load("res://scripts/aparencia.gd")
	var arquivo: String = ap.ARQUIVO
	var guardado := FileAccess.get_file_as_string(arquivo) if FileAccess.file_exists(arquivo) else ""

	var escolha := {"modelo": 2, "detalhe": 9, "desenho": 0, "boost": 1, "boost_cor": 7, "teto": 1, "antena": 1, "aerofolio": 1}
	var salvou: bool = ap.salvar(escolha)
	ap.salva = {}   # como se tivesse fechado o jogo
	var voltou: Dictionary = ap.minha()
	print("salvar, fechar e abrir: salvou %s, voltou igual: %s" % [salvou, "sim" if voltou == ap.limpa(escolha) else "NÃO " + str(voltou)])

	var velho := FileAccess.open(arquivo, FileAccess.WRITE)
	velho.store_string(JSON.stringify({"modelo": 3, "detalhe": 1, "fogo": 6, "rastro": 0, "enfeite": 2}))
	velho.close()
	ap.salva = {}
	var convertido: Dictionary = ap.minha()
	print("arquivo da versão 1 (Flecha, detalhe branco, cartola, fogo vermelho): %s" % ("convertido certo" if convertido.modelo == 3 and convertido.detalhe == 1 and convertido.teto == 1 and convertido.boost_cor == 6 and convertido.desenho == 1 else "ERRADO " + str(convertido)))

	var rede: Dictionary = ap.decodificar(ap.codificar(escolha))
	var lixo: Dictionary = ap.decodificar(PackedByteArray([250, 250]))
	print("pela rede: volta igual: %s · número estranho vira o padrão: %s" % ["sim" if rede == ap.limpa(escolha) else "NÃO", "sim" if lixo == ap.PADRAO else "NÃO"])

	if guardado == "":
		DirAccess.remove_absolute(ProjectSettings.globalize_path(arquivo))
	else:
		var de_volta := FileAccess.open(arquivo, FileAccess.WRITE)
		de_volta.store_string(guardado)
		de_volta.close()
	quit()
