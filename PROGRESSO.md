# Progresso

Diário do projeto. O mais novo fica em cima.

## Como abrir
- `./jogar.sh`: abre o jogo (menu)
- `./jogar_em_dois.sh`: duas janelas no mesmo PC, uma hospedando e outra entrando (testar o multiplayer sozinho)
- `./testar_rede.sh`: teste do multiplayer sem tela (host + 2 amigos)
- `./editor.sh`: abre o projeto no editor do Godot
- `./testar.sh`: teste sem tela (o carro dirige sozinho e mostra os números)
- Código no GitHub: https://github.com/Lelokz/JogoDoCarro (nome provisório). Commit + push a cada etapa.
- **Site do jogo: https://rocketwar-2a302.web.app** (Firebase da outra conta Google). `./publicar_site.sh` gera e publica (site + regras do banco das salas); `./publicar_site.sh teste` só gera e abre em http://127.0.0.1:8099.

## 31/10/2026: visual novo (carro, bola e estádio)
- Pedido teu: "deixar o jogo parecendo de profissional". **Só a aparência mudou:** as caixas de colisão
  do carro, da bola e da arena são as mesmas, então a física que tu aprovou continua igual.
- Tudo é montado por código (`scripts/modelagem.gd` = ferramentas; `scripts/modelo_carro.gd` = carro),
  e continua com **só 2 shaders** (regra do carregamento rápido no site).
- **Carro:** carroceria esportiva em duas cores (pintura do time em cima, saia escura embaixo),
  para-lamas em arco, cabine de vidro com teto pintado, aerofólio, entradas de ar, faróis e lanternas
  que brilham, turbina atrás que acende no boost, rodas com pneu arredondado e aro de 5 raios (girando).
- **Bola:** gomos de bola de futebol (12 pentágonos pretos e 20 hexágonos brancos) com costura.
- **Campo:** gramado com listras de corte e manchas, marcação (meio, círculo, áreas, borda), área do
  gol com um toque da cor do time. Rampa escura com placas e faixa de luz na cor do time; vidro limpo.
  Trave e travessão acesos; rede de verdade (quadradinhos).
- **Estádio:** arquibancada em volta com torcida (azul de um lado, laranja do outro, uns pulando),
  escadas e corredor, painel de LED com setas correndo, cobertura com luz, 4 torres de refletores.
- **Luz:** céu de fim de tarde, sol de lado, brilho nas luzes (bloom), névoa leve. Pads de boost novos
  (base de metal com anel aceso; o grande tem uma esfera de energia flutuando).
- HUD mostra o FPS. `./tirar_fotos.sh PASTA` tira fotos do visual sem abrir janela.
- Medido no navegador com placa de vídeo: **60 FPS**. Carregamento na 1ª visita (pior caso, sem
  memória de shaders): menu pronto em ~15 s (era ~10 s); das próximas vezes é mais rápido.
  **Falta:** otimizar a montagem da arena pra voltar pros ~10 s.

## 30/10/2026: salas com código no site (passo 2 de "jogar pela internet sem baixar nada")
- Tu ativou o **Realtime Database** no rocketwar-2a302 (modo bloqueado). As regras ficam em
  `regras_banco.json` e são publicadas junto com o site: só deixam gravar recados de sala no formato
  certo, ninguém consegue listar as salas, e qualquer outra coisa no banco é recusada (conferido com curl).
- **Como funciona:** no menu do site, **"Criar sala"** abre a arena e mostra um código de 4 letras no
  canto de cima (ex.: SALA QBUG). O amigo digita o código e clica em **"Entrar na sala"**, ou abre o link
  direto, tipo `rocketwar-2a302.web.app/?sala=QBUG` (o **L** copia esse link na tela de quem hospeda).
  - O banco é só um quadro de recados pro "aperto de mão" (`scripts/sala.gd`). Depois que conecta, os
    navegadores conversam direto (WebRTC) e o banco não é mais usado. Quando o host aperta ESC, a sala é
    apagada do banco.
  - Avisos no menu: sala que não existe, sala cheia (6), host não respondeu, "o host fechou a partida".
  - No PC (`./jogar.sh`) continua o Hospedar/Entrar pelo endereço de antes.
- Testado com **dois navegadores separados** no meu PC: o amigo entrou pelo link e conectou em ~2 s,
  ficou no Laranja e dirigiu; o placar e o relógio iguais nas duas telas; o host saiu e o amigo voltou
  pro menu com aviso; um código errado dá "a sala não existe".
- **Falta:** testar com um amigo de verdade, em outra casa. Por enquanto só tem STUN (o "descobridor de
  endereço" do Google). Em algumas internets (4G, alguns provedores) isso não basta e precisa de um
  **TURN** (um repetidor). O ExpressTURN é grátis; falta decidir qual conta usar.

## 30/10/2026: carregamento rápido no navegador + boost sem Ctrl
- Tu viu no site: "Treinar sozinho" travava ~20 s antes de abrir; e a aba fechou do nada jogando.
- **Aba fechando:** era o boost no Ctrl + acelerar no W = **Ctrl+W, que fecha a aba** (o site não consegue
  impedir). Boost agora: **botão esquerdo do mouse, F ou B**. (Ctrl+R e Ctrl+T também eram perigosos.)
- **Os 20 s:** medido no navegador com a placa de vídeo, sem a memória de shaders da NVIDIA:
  carregar a cena 0,3 s, montar a arena 0,1 s, **primeiro quadro 10,8 s** = o navegador compilando os
  shaders (os "programas" de cada material). Desligar sombra/céu/MSAA quase não muda; com **um material só
  caiu pra 3,2 s** → o que pesa é a quantidade de materiais diferentes.
  - Agora todos os materiais saem de **só 2 shaders** (`superficie.gdshader` sólido e `transparente.gdshader`),
    escolhendo o desenho por um número ("tipo"). Fábrica: `scripts/materiais.gd`. Visual igual (conferido em foto).
  - **Tela de carregamento** quando o jogo abre: monta a arena escondida e mostra aos poucos
    (céu, chão/carros, vidro, boost, resto), com barra de progresso; os botões aparecem quando termina.
    A tela de abertura do Godot (logo deles) virou fundo escuro.
  - Resultado (pior caso, 1ª vez): o jogo abre a tela de carregamento em ~3 s, carrega por ~7 s,
    e **"Treinar sozinho" abre em 0,15 s** (era 11 s). Da 2ª vez em diante o navegador/placa lembram e é mais rápido.
- Site publicado de novo.
- Tu testou no site: "ficou bem melhor!".

## 30/10/2026: o jogo no navegador (passo 1 de "jogar pela internet sem baixar nada")
- Decidido contigo: **tudo de graça**. Site no Firebase Hosting; salas com código; os navegadores conversam
  direto (WebRTC) e o Firebase só faz o "aperto de mão"; STUN do Google + TURN grátis do ExpressTURN
  (mesma receita do Loft). Servidor alugado: fora.
- Projeto Firebase: **rocketwar-2a302**, na tua outra conta Google. A pasta do jogo usa só essa conta
  (`firebase login:use`); Loft e Jarvis continuam com a deles.
- Modelos de exportação do Godot: baixei o pacote (1,28 GB, conferido), tirei só os 2 da web (20 MB) pra
  `Godot/modelos` e apaguei o resto.
- Versão web "sem threads" (roda em qualquer site, sem cabeçalho especial). Gráfico no modo compatível
  (WebGL 2). O arquivo principal tem 39 MB e chega comprimido com **7 MB**.
- No navegador o "Hospedar/Entrar" de agora não funciona (o navegador não deixa esse tipo de conexão):
  aparece "em breve (salas com código)". Treinar sozinho e campo de teste funcionam.
- Testado num Chromium sem janela, no site publicado: menu, treino, arena, contagem, carro andando.
  Esse navegador de teste não tem placa de vídeo e roda devagar; **falta tu ver se no teu fica liso.**
- **Próximo:** salas com código + WebRTC (passo 2). **Depois: gráficos melhores** (pedido teu).

## 30/10/2026: Etapa 7 (parte 1), esconder o atraso da internet
- Tu pediu só isso por agora (versão Windows e conexão pela internet depois; **Tailscale não**).
  Objetivo do jogo: **jogável pela internet, cada um abre no seu PC e joga, sem complicação.**
- **O carro de quem entra é calculado na hora no PC dele** (não espera o host). O PC dele guarda o que calculou
  em cada comando; quando o estado do host chega, compara com o que o host calculou pro mesmo comando e corrige
  30% da diferença por vez (suave). Diferença maior que 4 m (saída de bola) corrige de uma vez.
- **O host usa os comandos de cada amigo um por passo, em ordem** (numa fila), em vez de "o último que chegou":
  pela internet os comandos chegam em bolos e o host usava uns duas vezes e pulava outros.
- O host manda os **ajustes do carro** (F1) e a gravidade pros amigos a cada 2 s, pra todo mundo calcular igual.
- **Internet lenta de mentira pra testar:** `./jogar_em_dois.sh 60` (60 ms pra ir e 60 pra voltar) e `./testar_rede.sh 60`.
- Medido (teste sem tela, amigo acelerando, boost e pulo):
  | internet | carro do amigo começa a se mexer | diferença pro host (95% das vezes) |
  |---|---|---|
  | sem atraso | 17 ms | 0,4 cm |
  | 60 + 60 ms | 17 ms | 1,9 cm |
  | 120 + 120 ms | 17 ms | 6,1 cm |
  Antes, com 60 + 60 ms, o carro do amigo só começava a andar ~170 ms depois de apertar.
- **Ainda falta:** a bola e os outros carros aparecem pro amigo um pouquinho no passado (o tempo da internet).
  No PC do amigo o carro dele passa "por dentro" da bola e a batida de verdade acontece no host;
  o resultado (bola voando, carro freando) chega com o atraso da internet. Próximo passo, se incomodar.

## 30/10/2026: ESC no multiplayer
- Tu achou: no amigo, ESC mostrava o menu por um instante e voltava pro jogo; no host, ESC "reiniciava" o jogo.
- Causa: o `jogar_em_dois.sh` abre o jogo com "hospeda"/"entra em 127.0.0.1" escondido, e o menu
  lia isso toda vez que aparecia, então hospedava/entrava de novo na hora. Agora só lê quando o jogo abre.
- Testado sem tela: ESC no host e no amigo → fica no menu.
- Tu testou as duas janelas de novo: "agora ficou melhor".

## 30/10/2026: Etapa 6, multiplayer (primeira versão) + paredes de vidro
- **Paredes de vidro:** tu viu que, com a câmera da bola e o carro na parede, a câmera ficava atrás
  da parede e não dava pra ver nada. Agora a parede é vidro com a grade desenhada; a curva de baixo
  fica quase sólida e vai virando vidro pra cima. Chão escuro em volta da arena pra aparecer pelo vidro.
  Conferido numa foto renderizada: com o carro na parede, dá pra ver o campo inteiro através do vidro.
- **Menu:** Treinar sozinho · Campo de teste · Hospedar partida · Entrar (endereço do host) · Sair.
  ESC volta pro menu. O último endereço digitado fica salvo.
- **Como funciona:** o PC do host roda a física de tudo. Quem entra manda os comandos (120 vezes por segundo)
  e recebe a posição de tudo (60 vezes por segundo), mostrando 50 ms atrás pra ficar liso.
  - Porta 7777. Até 6 jogadores (3 contra 3). Os times se dividem sozinhos (host = Azul).
  - Carro na cor do time. O placar mostra "tu: Azul/Laranja".
  - Ajustes do carro (F1) são do host e valem pra todos os carros; pros amigos o F1 nem abre.
  - Online não tem R (desvirar), T (voltar) nem G (trazer a bola): seria roubo. O pulo desvira.
  - A tela do host mostra o endereço pros amigos digitarem.
- Por dentro: o carro agora lê "Comandos" (teclado aqui, rede nos carros dos amigos) em vez do teclado direto.
- Teste sem tela (`./testar_rede.sh`, host + 2 amigos no mesmo PC): os dois entram, times azul/laranja/azul,
  o carro do amigo anda/pula/usa boost no PC do host e no dele, o placar chega certo, quem sai some.
- **Ainda falta:** esconder o atraso da internet (etapa 7) — hoje o amigo sente o carro responder com o
  atraso da internet dele até o host. Na mesma rede de casa quase não se nota.
- **Pra jogar com amigos de verdade:** eles precisam do jogo (versão Windows, ainda não feita) e de um jeito
  de chegar no teu PC pela internet (Tailscale/ZeroTier ou abrir a porta 7777 no roteador).

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

**Próximo passo:** tu testar com internet lenta de mentira (`./jogar_em_dois.sh 60`) → decidir se a bola também precisa ser prevista → jeito de jogar pela internet sem complicação + versão Windows.
