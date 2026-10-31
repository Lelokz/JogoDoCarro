#!/bin/bash
# Tira fotos do visual do jogo sem abrir janela (precisa do xvfb-run): ./tirar_fotos.sh PASTA
cd "$(dirname "$0")"
PASTA=$(realpath "${1:-fotos}")
mkdir -p "$PASTA"
xvfb-run -a -s "-screen 0 1280x720x24" nice -n 10 Godot/Godot_v4.7.2-stable_linux.x86_64 --path jogo --rendering-method gl_compatibility --rendering-driver opengl3 --resolution 1280x720 -s res://testes/fotos.gd -- "$PASTA" 2>&1 | grep -iE "error|script" | head -20
ls "$PASTA"
