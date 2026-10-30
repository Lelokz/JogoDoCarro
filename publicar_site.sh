#!/bin/bash
# Gera a versão do navegador (pasta site/) e publica no Firebase Hosting (projeto rocketwar-2a302).
# ./publicar_site.sh teste  → só gera e abre em http://127.0.0.1:8099 pra testar no PC, sem publicar.
set -e
cd "$(dirname "$0")"
mkdir -p site
nice -n 19 Godot/Godot_v4.7.2-stable_linux.x86_64 --headless --path jogo --export-release "Web" ../site/index.html > /dev/null
echo "site gerado em site/"
if [ "$1" = "teste" ]; then
	echo "abrindo em http://127.0.0.1:8099 (Ctrl+C pra parar)"
	cd site && exec python3 -m http.server 8099 --bind 127.0.0.1
fi
firebase deploy --only hosting --project rocketwar-2a302
