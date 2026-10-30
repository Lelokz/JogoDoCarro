# Progresso

Diário do projeto. O mais novo fica em cima.

## Como abrir
- `./jogar.sh`: abre o jogo no campo de teste
- `./editor.sh`: abre o projeto no editor do Godot
- `./testar.sh`: teste sem tela (o carro dirige sozinho e mostra os números)
- Código no GitHub: https://github.com/Lelokz/JogoDoCarro (nome provisório). Commit + push a cada etapa.

## 30/10/2026: Etapa 5, a arena
- **Arena gerada por código** (`scripts/arena.gd`, muda os números e ela muda junto):
  80 m × 100 m × 20 m de altura, **cantos arredondados** vistos de cima (desenho nosso, o RL usa cantos retos),
  curva de 3 m entre chão e parede e entre parede e teto. Teto só com colisão (dá pra ver o céu).
  Gols de 18 × 6,5 m com 9 m de fundo, rede transparente da cor do time.
  Chão com linha do meio, círculo central e linha do gol; metade azul, metade laranja.
- **Partida** (`scripts/partida.gd`): tu é o Azul e ataca o gol laranja.
  - Saída de bola: 5 posições sorteadas, carro olhando pra bola, 33 de boost, contagem 3-2-1-VAI (carro travado).
  - Gol quando a bola passa inteira da linha: "GOL DO AZUL!", 3 s, nova saída. Gol contra conta pro Laranja.
  - Cronômetro de 5 min; acabou empatado → prorrogação (quem fizer o próximo gol ganha). Fim: Enter joga de novo.
  - **Pads de boost:** 6 grandes (enchem o tanque, voltam em 10 s) e 22 pequenos (+12, voltam em 4 s).
- **F2** troca entre a arena e o campo de teste. O jogo agora abre na arena.
- Teste sem tela: o carro sobe as duas paredes até o teto (19,8 m) com as 4 rodas grudadas;
  os dois gols e o gol contra contam certo; pads dão 100/12 e apagam; a bola a 60 m/s nunca escapa
  (parede, teto, canto, trave); prorrogação e fim de jogo funcionam.
- Ainda não visto na tela: o visual da arena foi feito sem eu conseguir olhar.

## 30/10/2026: bola 20% mais fraca
- Tu achou a bola rápida demais: num campo do tamanho do RL ela chegaria do outro lado antes do carro.
  Pediu uns 20% a menos.
- Medido: baixar só o "empurrão extra" quase não muda (pela metade = só 10% mais lenta); quem manda é a
  batida física. Criei a **"Força da batida"** (F1 → Bola), que multiplica tudo que a bola ganha na batida
  (não mexe quando o carro vai empurrando a bola colada).
- Teu ajuste: **80%**. Andando 76 → 61 km/h · boost 123 → 99 km/h · mortal 115 → 92 km/h.

## 30/10/2026: Etapa 4, a bola
Números conferidos no código do RocketSim.
- **Bola:** 1,82 m de diâmetro, peso 30 (carro 180), quica 60%, máximo 60 m/s, gira no máximo 6 rad/s.
  Fica 15 m na frente de onde o carro nasce.
  - Solta de 9,1 m: quica 3,1 → 1,1 → 0,4 m.
  - Rolando no chão perde velocidade (20 → 6,6 m/s em 5 s): como não pode girar mais que 6 rad/s,
    em alta velocidade ela arrasta em vez de rolar. A referência é igual. Ajustável no F1 (atrito).
- **Empurrão extra do toque** (igual à referência): além da batida normal, a bola ganha velocidade
  na direção do toque, mais forte quando o toque é fraco, menos pra cima, no máximo a cada 2 quadros.
  - Carro a 51 km/h → bola a 76 km/h · com boost (83 km/h) → bola a 123 km/h · mortal na bola → 115 km/h rasteira.
- **Câmera da bola** (C ou Y): fica atrás do carro na linha carro → bola, olhando pra bola.
- **G** (ou direcional pra cima): bola aparece 10 m na frente do carro. **T** volta carro e bola pro início.
- Na tela: velocidade da bola, do último toque e qual câmera tá ligada.
- F1 ganhou a seção "Bola": empurrão extra, quique, atrito, peso, resistência do ar, velocidade máxima.
- Tirei a resistência do ar que o Godot põe sozinho em tudo (10%/s): o RL não tem isso no carro.
  O carro ficou um pouco mais solto: 14,1 m/s sem boost (era 13,9), pulo 2,3 m (era 2,2),
  supersônico em 1,6 s (era 1,8).

## 30/10/2026: Etapa 3, pulo, mortal, controle no ar e boost
Números de partida conferidos no código do RocketSim (simulação aberta da física, feita pela comunidade).
- **Pulo:** toque rápido sobe 0,76 m, segurando sobe 2,2 m, duplo pulo 4,2 m.
  Pra usar o 2º pulo tem 1,25 s depois do pulo; caindo de rampa sem pular, o 2º pulo fica guardado.
- **Mortal** (2º pulo com direção): pra frente +4,8 m/s, pro lado +2 m/s, pra trás freia (13,7 → 4 m/s).
  - Seguindo a referência à risca, o giro fica preso em 5,5 rad/s e uma volta leva 1,14 s:
    o mortal de lado e o de trás batiam no chão no meio e o carro caía de teto.
  - **Do nosso jeito:** o mortal dá exatamente uma volta em 0,65 s, o carro quase não cai enquanto gira,
    e no fim o giro para. Os três terminam de rodas pra baixo. Ajustável no F1 ("Giro do mortal").
- **Controle no ar:** W/S inclina, A/D vira, Q/E rola (ou Shift + A/D). Chega no giro máximo em 0,44 s
  e para de girar sozinho quando solta.
- **Pulo pra desvirar:** de teto ou de lado no chão, o pulo desvira o carro.
- **Boost:** tanque de 100, dura 3 s, rastro laranja. Parado → supersônico (22 m/s) em 1,8 s; máximo 23 m/s.
  No campo de teste o tanque enche sozinho (20/s), porque os pads de boost só vêm na etapa 5.
  - A velocidade máxima que tinha ficado em 40 (sem querer) voltou pra 23.
- Câmera no ar segue pra onde o carro vai (senão girava junto no mortal).
- Botões: Espaço / botão direito / A = pulo · botão esquerdo / Ctrl / B = boost · Q/E ou LB/RB = rolar.
- `./testar.sh` agora roda os dois testes (chão e ar).
- Tu testou: "ficou legal".

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
- Velocidade máxima 23 → 40: voltei pra 23 na etapa 3 (sem querer também)
- Força da batida da bola: 80% (a bola ficava rápida demais pro tamanho do campo)

**Próximo passo:** tu testar a arena → Etapa 6 (multiplayer: um vira host, os outros entram).
