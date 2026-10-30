# Projeto Rocket League — Plano

Jogo de futebol de carro **inspirado** em Rocket League, de graça, pra jogar com os amigos.
Nome do jogo: **provisório** (a gente escolhe depois). "Projeto Rocket League" é só o nome da pasta.

## Regra de ouro
1. **A física vem primeiro.** Gravidade, suspensão, pulo, boost e o toque na bola têm que ficar
   gostosos antes de qualquer menu, som ou carro bonito.
2. **Tudo ajustável ao vivo.** Dentro do jogo vai ter um painel (tecla F1) com controles deslizantes
   pra gravidade, mola, amortecedor, aderência, força do pulo etc. A gente mexe jogando, sem reabrir
   nada, e salva o ajuste que ficou bom.
3. **Visual e nome nossos.** Nada copiado do Rocket League (nome, logo, carros, sons, arenas).
   As mecânicas do gênero a gente faz; a cara do jogo é nossa.

## Ferramenta: Godot 4
- De graça e aberta, roda nativo no Linux e exporta pra Windows (os amigos).
- Já tem multiplayer embutido no esquema que tu quer: **um amigo vira host, os outros entram nele.**
- Leve: dá pra abrir junto com outras coisas no PC.
- Fica tudo aqui no HD, nesta pasta.

## Números de partida (referência pública da comunidade RLBot)
No Godot 1 unidade = 1 metro. No Rocket League 1 unidade = 1 cm. Convertido:

| O quê | Valor de partida |
|---|---|
| Gravidade | **6,5 m/s²** (bem menor que a da Terra, 9,8 — é isso que dá a sensação "flutuante") |
| Velocidade máx. sem boost | 14,1 m/s |
| Velocidade máx. com boost | 23 m/s (supersônico a partir de 22) |
| Aceleração do boost | ~9,9 m/s² no chão, ~10,6 no ar |
| Freio | 35 m/s² |
| Boost gasto | 33,3 por segundo (tanque de 100) |
| Bola: raio / vel. máx. / quique | 0,93 m / 60 m/s / 60% |
| Massa carro : bola | 180 : 30 (carro 6× mais pesado) |
| Giro máx. do carro no ar | 5,5 rad/s |
| Física rodando a | 120 vezes por segundo |

Esses são só o **ponto de partida**. O balanceamento final é o que ficar bom pra gente jogando.

## Etapas

### Etapa 0 — Base
- Instalar o Godot 4 (no HD), criar o projeto nesta pasta.
- Física a 120 Hz, gravidade 6,5.

### Etapa 1 — Campo de teste grandão + carro caixa
- Chão enorme com grade desenhada (pra enxergar a velocidade) e umas rampas soltas.
- Carro = caixa + 4 rodas. Acelerar, ré, virar, freio de mão (drift).
- Câmera atrás do carro.
- Teclado **e** controle.
- Velocímetro na tela.

### Etapa 2 — Suspensão de verdade
- Cada roda é um "raio" que mede a distância até o chão + mola + amortecedor.
- Aderência lateral (não sair de lado à toa), pouso macio, o carro se endireitar.
- Painel F1 de ajuste ao vivo + salvar/carregar ajustes.
- **Aqui a gente passa bastante tempo polindo.**

### Etapa 3 — Ar e boost
- Pulo (segurar = pula mais alto), duplo pulo, mortal/dodge pra frente/lados.
- Controle no ar (inclinar, girar, rolar), boost, supersônico.
- Rastro do boost simples.

### Etapa 4 — A bola
- Bola com quique, rolagem e limite de velocidade.
- O toque carro→bola com um "empurrão extra" ajustável (é o que deixa o chute gostoso).
- Câmera de bola (tecla pra alternar).

### Etapa 5 — A arena
- Campo fechado: paredes com curva, cantos, teto, dois gols.
- Andar na parede e no teto (o carro gruda quando as 4 rodas tocam).
- Pads de boost no chão, placar, cronômetro de 5 min, saída de bola (kickoff), comemoração de gol.

### Etapa 6 — Multiplayer (host)
- Menu: "Hospedar" ou "Entrar" (digitar o endereço do host).
- O host roda a física de verdade; os outros mandam os comandos e recebem a posição de tudo.
- **Os ajustes do carro são do host.** Os carros de todo mundo usam os valores do host, que manda
  eles pros outros quando entram. O painel F1 só abre pra quem é host; pros amigos ele nem aparece.
  Como a física roda no host, mesmo que alguém mexesse no arquivo do próprio PC, não ia mudar nada.
- 1v1, 2v2, 3v3.
- Pra jogar pela internet: o jeito mais fácil é uma rede virtual (tipo Tailscale/ZeroTier) ou
  abrir uma porta no roteador do host. A gente decide quando chegar aqui.

### Etapa 7 — Polimento
- **Objetivo (dito pelo Lelokz em 30/10/2026): jogável pela internet de verdade — cada um abre o jogo no seu PC
  e joga, sem complicação. Tailscale está fora (ele não gosta).** Conexão a decidir quando chegar a hora.
- Esconder o atraso da internet (o carro de cada um responde na hora, sem "lag").
- Carros com modelo melhor, cores dos times, sons, menu bonito, replay de gol.
- Exportar pra Windows e mandar pros amigos.

## Como a gente trabalha
- Uma etapa por vez; no fim de cada uma tu testa e diz o que achou.
- Tudo que for feito vai pro `PROGRESSO.md`.
