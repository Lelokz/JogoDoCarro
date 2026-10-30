#!/bin/bash
# Abre o projeto no editor do Godot.
cd "$(dirname "$0")"
exec Godot/Godot_v4.7.2-stable_linux.x86_64 --path jogo --editor
