# Progresso

Diário do projeto. O mais novo fica em cima.

## Como abrir
- `./jogar.sh`: abre o jogo no campo de teste
- `./editor.sh`: abre o projeto no editor do Godot
- `./testar.sh`: teste sem tela (o carro dirige sozinho e mostra os números)
- Código no GitHub: https://github.com/Lelokz/JogoDoCarro (nome provisório). Commit + push a cada etapa.

## 30/10/2026: drift com transição
- Tu sentiu: soltando o Shift, o drift parava na hora e o carro voltava ao normal de uma vez.
  Medido: o carro ia de 80° de lado pra 0° em 0,2 s, e a velocidade caía de 9,5 pra 3,2 m/s (o tranco).
- Agora o pneu solta em 0,1 s quando aperta o Shift e **volta a agarrar aos poucos em 0,6 s** quando solta.
  Na saída do drift o carro também **endireita sozinho** pra onde está indo, em vez de só frear de lado.
  Resultado: o deslize some ao longo de ~0,5 s e o carro guarda mais velocidade.
- Duas barrinhas novas no F1: "Volta da aderência" e "Endireitar na saída do drift".
- Tu testou: "ficou bem melhor". Valores de partida mantidos (0,6 s / endireitar 2).

## 30/10/2026 (madrugada): Etapa 2, suspensão + painel F1
- Tu testou a etapa 1: "ficou legal". Pediu FOV menor.
  - O FOV não mudava: era a câmera ficando até ~2 m pra trás quando acelerava (parecia abrir).
    Agora a distância é sempre a mesma, só o giro da câmera é suave. FOV 100 → 90.
- **Painel F1:** barrinhas pra gravidade, mola, amortecedor, curso, batente, grude, motor,
  velocidade máxima, freio, curva, aderência, freio de mão e câmera (distância, altura, FOV, suavidade).
  Mostra também quanto cada mola tá apertada (FE/FD/TE/TD).
  Botões: Salvar (vai pra `jogo/ajustes/carro.json` e abre assim da próxima vez),
  Voltar pro salvo, Valores de partida.
- Suspensão nova: **batente** (força extra no fim do curso) e **grude no chão** (3,25 m/s², ajuda nas paredes depois).
- Medido numa queda de 5 m (o carro chega a 8 m/s):
  - mola 5000 / amortecedor 700 (antigo): a mola passa de 158% do curso, a caixa bate no chão.
  - batente mais forte não ajuda: só faz quicar mais.
  - **mola 8000 / amortecedor 3000 (novo de partida): 90% do curso, não quica, assenta em 0,9 s.**
- Saindo da rampa de 25° o carro às vezes cai de teto e fica lá: normal até a etapa 3
  (controle no ar e pulo pra desvirar). Por enquanto: R.

## 30/10/2026 (madrugada): Etapas 0 e 1
- Godot 4.7.2 baixado (conferido pelo SHA512) em `Godot/`. Projeto em `jogo/`.
- Física: Jolt, 120 Hz, gravidade 6,5 m/s², interpolação ligada (fica liso em monitor de qualquer Hz).
- **Campo de teste:** chão de 1 km × 1 km com grade (linha a cada 1 m, laranja a cada 10 m),
  3 rampas lado a lado (12°, 25°, 40°), uma rampa longa atrás, uma rampa de lado e uma parede.
- **Carro caixa:** corpo azul + cabine escura (a cabine fica mais pra trás, pra saber onde é a frente)
  e 4 rodas. Hitbox 0,84 × 0,36 × 1,18 m, massa 180.
  - Suspensão básica: cada roda é um raio até o chão, com mola + amortecedor.
  - Aceleração forte parado, perdendo força até 14,1 m/s. Freio 35 m/s², desacelera sozinho a 5,25.
  - Curva fica mais aberta com a velocidade (tabela de curvatura). Freio de mão: vira mais e escorrega.
  - R/Back desvira, T volta pro início, F11 tela cheia.
- Câmera atrás do carro, suave. Na tela: velocidade e rodas no chão.
- Teste sem tela: assenta a 31 cm, vai até 13,9 m/s, curva de 6,1 m de raio a 13,5 m/s
  (a referência dá 6,0), freio de mão 4 m. Saiu da rampa de 25° a 6,8 m de altura e capotou
  na queda (normal: ainda não tem controle no ar).
- Foi feito de madrugada sem abrir janela: **o visual ainda não foi visto**, só a física foi medida.

## Ajustes que ficaram bons
Fica salvo em `jogo/ajustes/carro.json` (o jogo abre com ele).

**30/10/2026, 1º ajuste do Lelokz** (o que mudou em relação aos valores de partida):
- Câmera: distância 2,8 → 2,5, altura 1,1 → 1,3, FOV 90 → 100 (com a distância fixa, o 100 ficou bom)
- Curva 1,0 → 1,15, aderência 60 → 54, giro no freio de mão 1,4 → 1,3
- Freio 6 e desacelera solto 0 foram sem querer: voltei pra 35 e 5,25
- Velocidade máxima 23 → 40 (por enquanto não muda nada: sem boost o motor vai só até 14,1)

**Próximo passo:** tu brincar no painel F1 e salvar o que ficar bom → Etapa 3 (pulo, ar, boost).
