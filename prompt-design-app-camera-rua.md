Quero que você desenhe as telas de um app de câmera fotográfica iOS nativo, com pegada de fotografia de rua. Nome do app ainda não definido — use "[App]" como placeholder de nome em qualquer lugar que precise dele.

**Contexto do produto:** app com dois modos — Modo Rua (padrão, ágil, quase sem UI) e Modo Pro (controle manual completo, estilo Moment Pro Camera). Captura só gera JPEG (sem RAW), com 4 "receitas" de cor pré-configuradas aplicadas em tempo real no visor.

**Princípios de design não-negociáveis:**
- Modo Rua nunca pede mais de um toque até disparar — sem menu no caminho.
- O viewfinder é sempre em fundo preto, em qualquer tema do sistema (claro/escuro) — consistência de visor importa mais que aderência ao tema do iOS.
- Máximo 4 elementos de UI simultâneos sobre o viewfinder no Modo Rua (seletor de receita, botão de disparo, toggle de modo, ícone de troca de lente).
- Tipografia do sistema (SF Pro). Ícones outline minimalistas, sem preenchimento sólido, para não competir com a imagem.
- Cor de destaque (accent) só para: indicador de foco travado, receita ativa, estado "ligado" de toggles — nunca decorativa.
- Você tem liberdade para propor: a paleta de cor de destaque exata, o ícone do app, a transição visual entre Modo Rua e Modo Pro, e o formato dos sliders do Modo Pro.

**Telas a desenhar (todas [iPhone], sem versão iPad):**

1. **Onboarding — Boas-vindas:** nome do app (placeholder), uma frase de proposta de valor, botão "Continuar".
2. **Onboarding — Permissão de câmera:** explicação curta do porquê da permissão, botão que aciona o prompt do sistema.
3. **Viewfinder — Modo Rua:** preview em tela cheia, carrossel horizontal de receitas na base (com thumbnail de preview ao vivo de cada uma), botão de disparo central, toggle de modo (Rua/Pro), ícone de troca de lente, grid de terços e indicador de nível sobrepostos (mostre um estado com eles ativados). Mostre também o estado de foco travado (indicador visual no ponto tocado).
4. **Viewfinder — Modo Pro:** mesmo preview em tela cheia, mas com painel de sliders sobrepostos: ISO, velocidade do obturador, exposição, foco, white balance (temperatura + tinta), cada um com o valor numérico ao lado. Inclua toggles de zebra stripes e focus peaking.
5. **Seletor de receita (expandido):** grade com as 4 receitas ("Classic", "Soft", "Mono", "Positivo"), thumbnail de preview ao vivo de cada uma, nome de exibição, receita ativa destacada.
6. **Paywall:** preço (compra única, faixa de R$ 50 — use "[preço]" como placeholder), lista curta do que está incluso, botão de compra, botão "Restaurar compra". Estado de "processando compra" e estado de erro (ex: sem conexão com a App Store).
7. **Configurações:** idioma (português/inglês), grid, nível, obturador silencioso, preview em preto e branco do Modo Rua, versão do app, link "Restaurar compra".
8. **Permissão negada (câmera ou fotos):** mensagem explicando o motivo, botão que abre Ajustes do iOS.

**Fluxo principal entre telas:** Onboarding (Boas-vindas → Permissão de câmera) → Viewfinder Modo Rua (tela padrão de abertura) ↔ Viewfinder Modo Pro (toggle instantâneo, mesmo viewfinder) → toque em disparar sem compra ativa → Paywall → volta ao Viewfinder já com a foto salva. Configurações e troca de lente são acessíveis a qualquer momento a partir do Viewfinder.

**Toda a copy de texto ainda não está definida** (nome do app em aberto) — use placeholders claramente marcados como tais (ex.: `[placeholder: texto do botão]`), nunca escreva copy final.
