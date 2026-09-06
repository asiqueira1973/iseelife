# Épico — Seletor de distância focal no Modo Rua (28 / 35 / 40)

> Status: IMPLEMENTADO (v1.3, build 10) — falta teste em device. Inspirado na Leica LUX, mas SÓ a
> parte de distância focal (enquadramento). Fica de fora, de propósito, a simulação de abertura/
> bokeh/caráter de lente (isso seria outro épico, pesado e menos "cara de rua").
>
> Como ficou: campo `focalRuaMm` na ConfiguracaoUsuario (default 28, migração aditiva);
> `CameraSession.definirFocalRua` aplica `videoZoomFactor = focal/26` na lente wide (crop do
> sensor, vale p/ preview E captura); seletor `FocalSelector` (pílula 28·35·40) no Modo Rua, só
> quando a wide está ativa; no Pro e na ultra-wide volta ao quadro nativo.

## 1. Objetivo
Deixar o fotógrafo escolher a **distância focal** no Modo Rua — trabalhando como um telêmetro
de **foco/enquadramento fixo** (28mm, 35mm, 50mm) —, na filosofia *out-of-the-camera*: o
recorte é aplicado **na hora do disparo** e já vira o JPEG final. Nada de zoom livre "escondido";
focais nomeadas, clássicas de rua.

## 2. Por que
28 e 35 são as focais mais usadas em fotografia de rua; 50 é o clássico seguinte. Um seletor de
focal enxuto ensina composição e dá identidade — sem sair do "abriu, mirou, disparou".

## 3. Como funciona (técnico)
Não é lente nova: é **crop do sensor** no módulo físico mais adequado.
- Usar um **dispositivo virtual multi-câmera** (ex.: `.builtInDualWideCamera` / `.builtInTripleCamera`
  quando existir) e ajustar `AVCaptureDevice.videoZoomFactor` para o fator da focal escolhida.
  Assim o iOS **escolhe sozinho a melhor lente física** (troca pra tele perto do 50, onde houver) e
  faz o crop mínimo.
- Mapa focal → zoom (relativo à principal ~26mm equiv.):
  - **28mm** → ~1,08×
  - **35mm** → ~1,35×
  - **50mm** → ~1,92×
- O crop é **aplicado ao preview E ao arquivo** (o que se vê é o que se grava — princípio 0.1).
- A **receita de cor** continua independente (focal = enquadramento; receita = cor).

## 4. UX (Modo Rua, minimalista)
- Um **seletor de focal discreto** (ex.: pílula "35" em âmbar, ou um mini-dial horizontal 28·35·50
  com o ativo em âmbar), sem poluir o visor.
- No Modo Rua, o seletor de focal **assume o papel do zoom** (em vez de zoom livre).
- Indicador da focal ativa visível e sóbrio; troca com 1 toque (cicla) ou swipe.
- Modo Pro pode manter o zoom/lente como é hoje (decidir depois).

## 5. Qualidade por aparelho (é o ponto sensível)
A resolução resultante depende do crop e do hardware:

| Aparelho | 28mm | 35mm | 50mm |
|---|---|---|---|
| **iPhone 13 mini** (12MP, sem tele, sem 48MP) | ~10 MP | ~6,6 MP | ~3,3 MP |
| **iPhone 48MP** (14 Pro+/15+) | ~alto | ~alto | ~13 MP |
| **iPhone Pro com tele** | ~alto | ~alto | ~óptico (troca p/ tele) |

Decisão pendente pro 50 em aparelhos 12MP: (a) oferecer com a resolução real, ou (b) **upscale**
leve pra padronizar o tamanho do arquivo (custo: suavização). Talvez: mostrar as 3 focais sempre,
mas deixar a qualidade acontecer conforme o device (sem esconder nada do usuário).

## 6. Conjunto de focais
- **v1 (implementado):** 28 · 35 · 40 (28 default). Sem o 50 (crop pesado demais em aparelhos 12MP).
- Futuro: talvez 24/21 pra quem curte grande-angular; 50 só em aparelhos com tele/48MP.

## 7. Fora de escopo (deixar claro)
- Simulação de **abertura / profundidade de campo / bokeh / caráter de lente** (Noctilux etc.).
- Perfis ópticos (vinheta, aberração, cat's-eye). Tudo isso = outro épico, se um dia.

## 8. Riscos / pontos a validar
- Recorte de 50mm no 13 mini fica baixo (~3MP) — alinhar expectativa ou upscale.
- Garantir que o crop do preview == crop do arquivo (paridade WYSIWYG).
- Trocar de focal não pode "brigar" com o gesto/indicador de zoom atual (1x).
- Consistência de exposição/receita ao mudar de lente física (quando o iOS troca de módulo).
