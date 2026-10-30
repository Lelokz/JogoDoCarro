#!/bin/bash
# Testar o multiplayer sozinho: abre duas janelas, uma hospedando e outra entrando nela.
# Cada janela é um jogador: o teclado vai pra janela que estiver selecionada.
# ./jogar_em_dois.sh 60  → finge internet lenta: 60 ms pra ir e 60 pra voltar.
cd "$(dirname "$0")"
GODOT=Godot/Godot_v4.7.2-stable_linux.x86_64
ATRASO="--atraso=${1:-0}"
$GODOT --path jogo -- --hospedar $ATRASO &
sleep 3
$GODOT --path jogo -- --entrar=127.0.0.1 $ATRASO &
wait
