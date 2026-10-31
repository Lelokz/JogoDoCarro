#!/bin/bash
# Testes sem tela: o carro dirige, pula, voa e chuta a bola sozinho e mostra os números.
cd "$(dirname "$0")"
GODOT=Godot/Godot_v4.7.2-stable_linux.x86_64
echo "== Chão: aceleração, curva, freio, pouso, painel"
nice -n 19 $GODOT --headless --fixed-fps 120 --path jogo -s res://testes/teste_carro.gd 2>&1 | grep -v '^Godot Engine'
echo "== Ar: pulo, mortal, boost, desvirar, controle no ar"
nice -n 19 $GODOT --headless --fixed-fps 120 --path jogo -s res://testes/teste_ar.gd 2>&1 | grep -v '^Godot Engine'
echo "== Bola: quique, rolagem, batidas"
nice -n 19 $GODOT --headless --fixed-fps 120 --path jogo -s res://testes/teste_bola.gd 2>&1 | grep -v '^Godot Engine'
echo "== Arena: saída de bola, parede, gols, pads, prorrogação"
nice -n 19 $GODOT --headless --fixed-fps 120 --path jogo -s res://testes/teste_arena.gd 2>&1 | grep -v '^Godot Engine'
echo "== Explosões: demolição, volta do demolido, explosão do gol"
nice -n 19 $GODOT --headless --fixed-fps 120 --path jogo -s res://testes/teste_explosoes.gd 2>&1 | grep -v '^Godot Engine'
echo "== Bot: joga 90 s sozinho em cada nível (o carro azul fica parado)"
nice -n 19 $GODOT --headless --fixed-fps 120 --path jogo -s res://testes/teste_bot.gd 2>&1 | grep -v '^Godot Engine'
echo "== Carros: cada modelo anda, faz curva, pula e dá mortal"
nice -n 19 $GODOT --headless --fixed-fps 120 --path jogo -s res://testes/teste_modelos.gd 2>&1 | grep -v '^Godot Engine'
