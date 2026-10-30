#!/bin/bash
# Abre o jogo direto no campo de teste.
cd "$(dirname "$0")"
exec Godot/Godot_v4.7.2-stable_linux.x86_64 --path jogo
