#!/bin/bash
# Teste sem tela: o carro dirige sozinho e mostra velocidade, altura e raio de curva.
cd "$(dirname "$0")"
exec nice -n 19 Godot/Godot_v4.7.2-stable_linux.x86_64 --headless --fixed-fps 120 --path jogo -s res://testes/teste_carro.gd
