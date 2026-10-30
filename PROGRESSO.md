# Progresso

Diário do projeto. O mais novo fica em cima.

## Como abrir
- `./jogar.sh`: abre o jogo no campo de teste
- `./editor.sh`: abre o projeto no editor do Godot
- `./testar.sh`: teste sem tela (o carro dirige sozinho e mostra os números)

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
- **Próximo passo:** tu testar dirigindo e dizer o que achou → Etapa 2 (suspensão + painel F1).

## Ajustes que ficaram bons
(quando a gente achar valores de gravidade/suspensão que ficaram gostosos, anota aqui)
