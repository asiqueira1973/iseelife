# Esboço de épico — Zone Focus / "Snap Focus" no Modo Rua

> Status: ESBOÇO (ideia), não é spec final. Inspirado no **Snap Focus da Ricoh GR** (foco fixo
> por distância), que o Alexandre usa bastante. Pareia com o seletor de distância focal (28/35/40).
> A ideia é o clássico de rua: **foco pré-ajustado, sem espera de autofoco.**

## 1. Objetivo
Deixar o fotógrafo **travar o foco numa distância pré-definida** (uma "zona") no Modo Rua. Ao
disparar, a foto sai **na hora, sem AF caçando** — tudo dentro da zona de profundidade fica
nítido. É o jeito de fotografar rua: antecipa a cena, não espera a câmera focar.

## 2. Por que
- Fotografia de rua vive de **timing**; esperar o AF assentar perde o momento.
- Foco fixo + profundidade de campo = **zona de nitidez previsível** (o fotógrafo "sabe" o que
  vai sair nítido).
- Combina com o seletor de focais que já entrou (28/35/40): focal = enquadramento, zona = foco.

## 3. O desafio técnico (o ponto central — ser honesto)
O iOS **NÃO expõe foco em metros**. A API é `setFocusModeLocked(lensPosition:)`, com
`lensPosition` de **0..1** (perto..longe), **não calibrada em distância** e que **varia por
modelo de iPhone**. Ou seja: não dá pra dizer "foca em 2 m" direto.

**Porém — a favor da gente:** o sensor do iPhone é pequeno, então a **profundidade de campo é
enorme**. Um preset aproximado já cobre uma faixa grande de distância. Isso torna o zone focus
**viável mesmo sem precisão milimétrica**: não precisa de "2,00 m", precisa de "perto/médio/longe"
que, com a DOF profunda, pega tudo na zona.

Duas abordagens:
- **(A) Presets por lensPosition (device-agnóstico, simples):** oferecer 3–4 "zonas" (ex.: Perto /
  Médio / Rua / ∞) mapeadas para valores de `lensPosition` **calibrados empiricamente** no device.
  Trava o foco (`setFocusModeLocked`) → sem hunting. Rótulos aproximados (ou genéricos).
- **(B) Depth/LiDAR (só Pro):** nos iPhones Pro com LiDAR dá pra estimar distância real e mirar
  metros com mais precisão. Fora do 13 mini (sem LiDAR) e bem mais complexo → deixar pra depois.

Recomendo começar por **(A)**.

## 4. Como funcionaria (técnico, abordagem A)
- Estado novo (ConfiguracaoUsuario): `zoneFocusAtivo: Bool` + `zoneFocusPreset` (índice da zona).
- Ao ativar: `device.setFocusModeLocked(lensPosition: valorDaZona)`; AF contínuo **desligado**.
- Ao desativar: volta ao `continuousAutoFocus` (comportamento atual).
- A CameraSession já tem `definirFoco(lensPosition)` (Modo Pro) — o zone focus é uma versão
  **por presets + lock**, exposta de forma simples no Rua.
- Exposição continua pela **prioridade de obturador** (já existe); zone focus mexe só no FOCO.

## 5. UX (Modo Rua, minimalista)
- Um **toggle "Zona"** (ou ícone de foco) que liga/desliga o zone focus.
- Com ele ligado, um **seletor de zonas** discreto (ex.: Perto · Médio · Rua · ∞), ativo em âmbar,
  ao lado/abaixo do seletor de focais.
- Enquanto ligado, **o toque pra focar fica suspenso** (o foco é fixo) — ou o toque re-ancora a
  zona (decidir). O quadradinho AF não aparece.
- Rótulos: genéricos (Perto/Médio/Rua/∞) e, se calibrarmos, uma dica de distância **aproximada**.

## 6. Zonas propostas (v1)
- **Perto** (~1–1,5 m) · **Médio** (~2–3 m) · **Rua** (~5 m) · **∞** (hiperfocal/paisagem).
- Talvez começar com 3 (Perto/Rua/∞) e crescer.

## 7. Calibração (o trabalho principal)
- Medir, no device, os `lensPosition` que correspondem a cada zona (o Alexandre tem o 13 mini →
  calibramos nele primeiro). Testar com uma régua/marcas no chão.
- Guardar uma **tabela de calibração por modelo** (fallback: valores do 13 mini). Refinar por
  modelo conforme necessário.
- Risco: precisão varia por aparelho; mitigado pela DOF profunda do celular.

## 8. Interações / decisões a validar
- Zone focus ON x tap-to-focus (suspender o toque, ou re-ancorar a zona no toque).
- Zone focus é só do Rua (Pro mantém o foco manual por slider).
- Persistir a última zona e o estado on/off entre sessões.
- Combinar com o seletor de focais (independentes).

## 9. Fora de escopo
- Foco em metros com precisão de câmera dedicada (o iOS não entrega isso sem calibração/LiDAR).
- Escala de hiperfocal calculada por abertura real (a abertura do iPhone é fixa; simplificar).
