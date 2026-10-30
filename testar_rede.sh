#!/bin/bash
# Teste do multiplayer sem tela: um host e dois amigos no mesmo PC (endereço 127.0.0.1).
cd "$(dirname "$0")"
GODOT=Godot/Godot_v4.7.2-stable_linux.x86_64
PASTA=$(mktemp -d)
timeout 60 nice -n 19 $GODOT --headless --path jogo -s res://testes/teste_rede_host.gd > $PASTA/host.txt 2>&1 &
sleep 2
timeout 55 nice -n 19 $GODOT --headless --path jogo -s res://testes/teste_rede_amigo.gd -- --dirigir > $PASTA/amigo1.txt 2>&1 &
sleep 1
timeout 50 nice -n 19 $GODOT --headless --path jogo -s res://testes/teste_rede_amigo.gd > $PASTA/amigo2.txt 2>&1 &
wait
grep -hE '^(host|1º amigo|2º amigo)|ERROR|SCRIPT' $PASTA/host.txt $PASTA/amigo1.txt $PASTA/amigo2.txt
rm -r $PASTA
