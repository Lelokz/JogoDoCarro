#!/bin/bash
# Testes sem tela: o carro dirige, pula e voa sozinho e mostra os números.
cd "$(dirname "$0")"
GODOT=Godot/Godot_v4.7.2-stable_linux.x86_64
echo "== Chão: aceleração, curva, freio, pouso, painel"
nice -n 19 $GODOT --headless --fixed-fps 120 --path jogo -s res://testes/teste_carro.gd 2>&1 | grep -v '^Godot Engine'
echo "== Ar: pulo, mortal, boost, desvirar, controle no ar"
nice -n 19 $GODOT --headless --fixed-fps 120 --path jogo -s res://testes/teste_ar.gd 2>&1 | grep -v '^Godot Engine'
