#!/bin/bash
# Fotos de um carro no pódio, de 6 lados, numa folha só: ./fotos_carro.sh PASTA [MODELO] [AEROFÓLIO]
cd "$(dirname "$0")"
PASTA=$(realpath "${1:-fotos}")
mkdir -p "$PASTA"
xvfb-run -a -s "-screen 0 1280x720x24" Godot/Godot_v4.7.2-stable_linux.x86_64 --path jogo --rendering-method gl_compatibility --rendering-driver opengl3 --resolution 1280x720 -s res://testes/fotos_carro.gd -- "$PASTA" "${2:-0}" "${3:--1}" 2>&1 | grep -iE "script error|parse error|error at|invalid" | head
python3 - "$PASTA" <<'PY'
import sys
from PIL import Image
pasta = sys.argv[1]
folha = Image.new("RGB", (3 * 560, 2 * 380))
for i in range(6):
    folha.paste(Image.open(f"{pasta}/g{i}.png").crop((360, 180, 920, 560)), ((i % 3) * 560, (i // 3) * 380))
folha.save(f"{pasta}/folha.png")
PY
