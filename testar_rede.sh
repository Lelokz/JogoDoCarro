#!/bin/bash
# Teste do multiplayer sem tela: um host e dois amigos no mesmo PC (endereço 127.0.0.1).
# ./testar_rede.sh 60  → finge internet lenta: 60 ms pra ir e 60 pra voltar.
ATRASO="--atraso=${1:-0}"
cd "$(dirname "$0")"
GODOT=Godot/Godot_v4.7.2-stable_linux.x86_64
PASTA=$(mktemp -d)
timeout 60 nice -n 19 $GODOT --headless --path jogo -s res://testes/teste_rede_host.gd -- $ATRASO > $PASTA/host.txt 2>&1 &
sleep 2
timeout 55 nice -n 19 $GODOT --headless --path jogo -s res://testes/teste_rede_amigo.gd -- --dirigir $ATRASO > $PASTA/amigo1.txt 2>&1 &
sleep 1
timeout 50 nice -n 19 $GODOT --headless --path jogo -s res://testes/teste_rede_amigo.gd -- $ATRASO > $PASTA/amigo2.txt 2>&1 &
wait
grep -hE '^(host|1º amigo|2º amigo)|ERROR|SCRIPT' $PASTA/host.txt $PASTA/amigo1.txt $PASTA/amigo2.txt
rm -r $PASTA
