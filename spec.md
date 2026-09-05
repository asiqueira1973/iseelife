# Spec — I See Life (app de fotografia de rua iOS)

**Versão:** 1.0 (spec original) · ver seção 30 para o estado atual
**Responsável de produto:** Alexandre Siqueira
**Status:** implementado e publicado — ver seção 30
**Data:** 2026-08-07 (spec original)

> ⚠️ **LEIA ANTES DE MANTER O APP:** as seções **0–29 descrevem o escopo ORIGINAL da v1.0**.
> O app **evoluiu** desde então (nome definido, receitas a mais, novas features, mudanças de
> modelo). O **estado atual, o changelog e os mecanismos que NÃO podem ser quebrados** estão na
> **seção 30** deste documento e, com detalhe técnico, em **`DOCUMENTACAO-TECNICA.md`**. Para
> mudar o app com segurança: leia a seção 30 + a doc técnica, e siga o protocolo da seção 29.

## Como usar este documento

Este documento é a fonte única de verdade do produto, no nível de detalhe necessário para o Claude Code implementar sem inventar decisões. A seção 24 (Assunções declaradas) precisa ser revisada **antes** de gerar código — assunção não revisada vira verdade no minuto em que o agente começa a implementar. A seção 25 (Perguntas abertas) lista o que só o Alexandre pode decidir; o agente de código deve perguntar em vez de assumir sempre que cruzar com um item dela.

---

## 0. Princípios não-negociáveis

1. **Modo Rua nunca pede mais de um toque até disparar.** Abrir o app já deixa a pessoa pronta pra fotografar — nenhum menu, nenhuma configuração obrigatória no caminho do primeiro disparo.
2. **JPEG único, sem RAW, sem edição posterior no app.** O filtro é aplicado no momento da captura e vira o arquivo final — filosofia out-of-the-camera, sem editor embutido.
3. **Simplicidade antes de complexidade prematura.** Nenhuma tela do MVP existe "porque pode ser útil depois" — só o que serve ao Modo Rua e ao Modo Pro tal como especificados aqui.
4. **O viewfinder é sempre preto, em qualquer modo claro/escuro do sistema.** Consistência de visor é mais importante que aderência ao tema do iOS.
5. **Nenhuma dependência de rede.** O app funciona 100% offline, sempre — inclusive a compra (StoreKit valida localmente após a primeira confirmação).

---

## 1. Visão e problema

Um app de câmera iOS nativo com pegada de fotografia de rua: abre rápido, dispara rápido, e produz fotos com caráter — através de "receitas" inspiradas em simulações de filme (Fujifilm) e perfis de imagem (Ricoh GR III) aplicadas em tempo real, sem RAW e sem pós-processo. Ao lado do modo ágil (padrão), o app oferece um Modo Pro com controle manual completo de exposição, ISO, foco e white balance, para quem quer o mesmo nível de controle de apps de câmera manual como o Moment Pro Camera.

Public-alvo: o próprio Alexandre, fotógrafo de rua amador, e outros entusiastas de fotografia de rua no Brasil. Motivação declarada: ser o primeiro app de fotografia de rua brasileiro publicado na App Store, com valor de marca pessoal.

**Anti-escopo — o que este produto não é:**
- Não é um editor de fotos (sem crop, sem ajustes pós-captura, sem filtros aplicáveis depois de já ter uma foto).
- Não é um app de vídeo (Apple Log, ProRes e gravação de vídeo ficam de fora).
- Não é uma rede social — sem feed, sem perfil público, sem compartilhamento nativo além do share sheet padrão do iOS.
- Não compete com apps de câmera profissional multi-formato (ProRAW, TIFF) — o produto é deliberadamente enxuto.

---

## 3. Escopo do MVP

### Dentro
- Modo Rua (padrão ao abrir o app): auto exposição/foco com override por toque, obturador silencioso, visor limpo, preview em preto e branco opcional, 4 receitas pré-configuradas com preview em tempo real.
- Modo Pro: sliders manuais de ISO, velocidade do obturador, exposição, foco e white balance (temperatura + tinta), zebra stripes, focus peaking, grid.
- Troca de lente (wide / ultra-wide, conforme disponibilidade do aparelho).
- Captura em JPEG único, out-of-the-camera, sem RAW.
- 4 receitas pré-instaladas: inspiradas em Fuji Classic Chrome, Fuji Astia/Soft, Fuji Acros/Monochrome e Ricoh GR Positive Film (ver seção 11 para os parâmetros).
- Grid de composição (terços) e nível/giroscópio.
- Onboarding com pedido de permissão de câmera e de biblioteca de fotos.
- Compra única via StoreKit 2 (sem assinatura), com prévia gratuita do app antes da compra (ver seção 11).
- Interface em português e inglês (localização de strings).
- Compatibilidade: iPhone apenas (sem iPad).

### Fora do MVP
| Item | Destino | Motivo / o que falta |
|---|---|---|
| Zone focus com presets de distância (1m/2m/5m/infinito) | Descartado do MVP, mantido no roadmap (seção 28) | `lensPosition` do iOS não é calibrado em metros e varia por device — exige tabela de calibração manual por modelo de iPhone, decisão tomada em conversa de que isso não entra agora |
| ProRAW, Apple Log, ProRes | Adiado para v2 | Exclusivo de hardware iPhone Pro; o Alexandre testa em iPhone 13 mini (não-Pro) e não consegue validar essa faixa de recurso pessoalmente |
| Criação de receitas customizadas pelo usuário | Adiado para v2 | Aumenta complexidade de UI (editor de parâmetros) fora do escopo "clean e fácil" definido para o MVP |
| Suporte a iPad | Descartado para este produto | Decisão explícita — câmera de iPad não é o caso de uso de fotografia de rua |
| Galeria própria dentro do app | Descartado | Fotos vão direto para a Fototeca do sistema (Photos); duplicar galeria dentro do app adiciona complexidade sem benefício claro no MVP |
| Vídeo | Descartado | Fora da visão do produto (seção 1) |

---

## 4. Arquitetura

| Camada | Escolha | Por quê | Alternativa descartada |
|---|---|---|---|
| Linguagem/UI | Swift + SwiftUI | Padrão já usado nos outros apps do Alexandre (Quando Vence, Estante); nativo, sem dependência de framework híbrido | React Native / Flutter — não dá acesso fino o suficiente a AVFoundation para controle manual de câmera |
| Persistência local | SwiftData | Guarda só configurações do usuário e o catálogo de receitas (seed); volume mínimo de dados não justifica Core Data puro | Core Data direto — SwiftData já resolve o volume de dados deste app com menos boilerplate |
| Captura de câmera | AVFoundation (`AVCaptureSession`, `AVCapturePhotoOutput`, `AVCaptureDevice`) | Único caminho para expor ISO, shutter, foco e white balance manuais no iOS | Nenhuma — é a única API nativa que dá esse nível de controle |
| Pipeline de filtro (receitas) | Core Image (`CIFilter` em cadeia: curva de tom, saturação/HSL, shift de white balance, grão procedural, nitidez) | Processamento em tempo real no preview e na captura final, sem depender de servidor | LUT estático — não reproduz com fidelidade os parâmetros de highlight/shadow/grão descritos na seção 11 |
| Compra | StoreKit 2, produto não-consumível único | Mesmo padrão dos outros apps do Alexandre (Quando Vence, Estante) | Assinatura — descartada, o Alexandre decidiu por compra única de valor mais alto (~R$ 50) |
| Backend | Nenhum | App 100% local-first, sem conta, sem sincronização | — |
| iOS mínimo | iOS 17.0 | SwiftData (WWDC23) exige iOS 17+; é uma restrição técnica, não uma escolha de produto | — |
| Repositório | Novo repositório, mesmo prefixo de bundle ID e mesmo Apple Developer Team dos outros apps do Alexandre | Reaproveita conta e configuração já existentes | — |

**Premissa técnica a validar:** disponibilidade de lentes (wide/ultra-wide/tele) via `AVCaptureDevice.DiscoverySession` deve ser checada em runtime — o app roda em qualquer iPhone com iOS 17+, mas só mostra as lentes fisicamente presentes naquele aparelho (regra 11.1).

---

## 7. Modelo de dados

O volume de dados é mínimo — sem conta, sem múltiplos perfis, sem sincronização. Duas entidades locais via SwiftData.

```
configuracao_usuario (linha única, criada no primeiro uso)
├── id: UUID [pk]
├── idioma_preferido: enum(pt, en) [not null, default: pt]
├── modo_padrao: enum(rua, pro) [not null, default: rua]
├── ultima_lente_usada: enum(wide, ultra_wide) [nullable — nulo até a primeira captura]
├── grid_ativado: bool [not null, default: true]
├── nivel_ativado: bool [not null, default: true]
├── obturador_silencioso: bool [not null, default: true]
├── preview_pb_ativado: bool [not null, default: false]
├── compra_desbloqueada: bool [not null, default: false]
└── data_compra: datetime [nullable — nulo até a compra ser confirmada]

receita (catálogo fixo, seed no primeiro lançamento — não editável pelo usuário no MVP)
├── id: UUID [pk]
├── nome_exibicao: texto [not null] // ex: "Classic", "Soft", "Mono", "Positivo"
├── inspiracao: texto [not null] // referência interna, não exibida como marca de terceiro na UI
├── highlight: inteiro [not null] // -4 a +4, curva de tom nas altas luzes
├── shadow: inteiro [not null] // -4 a +4, curva de tom nas sombras
├── saturacao: inteiro [not null] // -4 a +4
├── temperatura_wb_kelvin: inteiro [nullable] // nulo = segue WB automático do sensor
├── tinta_wb: inteiro [not null, default: 0] // -9 a +9 (eixo verde/magenta)
├── intensidade_grao: enum(nenhum, fraco, medio, forte) [not null, default: nenhum]
├── nitidez: inteiro [not null] // -4 a +4
├── monocromatico: bool [not null, default: false]
├── filtro_mono: enum(nenhum, amarelo, vermelho, verde) [nullable] // só relevante quando monocromatico = true
└── ordem_exibicao: inteiro [not null] // ordem fixa no seletor de receitas
```

**Estratégia de exclusão:** não há exclusão de dados pelo usuário no MVP — `configuracao_usuario` é atualizada in-place, `receita` é somente leitura (seed).

**Dados de seed:** as 4 receitas da seção 11.2 são inseridas na primeira execução do app (`onAppear` do app root, checando se a tabela `receita` está vazia).

**Lógica que vive no banco:** nenhuma — sem triggers, sem funções, sem políticas (não há RLS em SwiftData local).

---

## 8. Épicos e critérios de aceite

### 8.1 — Captura no Modo Rua (padrão)
Objetivo: permitir fotografar em até um toque, sem configuração obrigatória.

Fluxo: app abre → viewfinder em tela cheia, Modo Rua ativo → toque simples na tela trava foco/exposição no ponto tocado (indicador visual por ~1s) → toque no botão de disparo captura → JPEG salvo na Fototeca com a receita ativa aplicada.

Critérios de aceite:
- Ao abrir o app pela primeira vez após onboarding, o viewfinder do Modo Rua aparece em no máximo 1 tela (sem tela intermediária).
- Tocar em qualquer ponto do viewfinder trava foco e exposição nesse ponto; um círculo aparece e desaparece após 1 segundo.
- Tocar no botão de disparo produz um JPEG salvo na Fototeca do sistema em até 1 segundo após o toque (ver 17.1).
- Sem receita selecionada, a captura usa a primeira receita da lista (ordem_exibicao = 1) como padrão.
- O obturador silencioso está ativo por padrão (`obturador_silencioso = true`); nenhum som de captura toca.

### 8.2 — Captura no Modo Pro
Objetivo: dar controle manual completo equivalente ao de apps como Moment Pro Camera.

Fluxo: usuário alterna para Modo Pro (seção 9) → sliders de ISO, velocidade do obturador, exposição e foco aparecem sobre o viewfinder → ajustes refletem em tempo real no preview → captura gera JPEG com a receita ativa aplicada sobre os valores manuais.

Critérios de aceite:
- Cada slider (ISO, shutter, exposição, foco, WB) reflete o valor numérico atual em texto ao lado.
- Arrastar o slider de ISO atualiza o preview em tempo real, sem travar a interface (sem frame descartado por mais de 200ms).
- Zebra stripes, quando ativado, marca em padrão diagonal qualquer área com luminância acima de 95%.
- Focus peaking, quando ativado, contorna em amarelo as bordas com maior contraste de foco.
- Grid de terços é exibido sobre o viewfinder quando `grid_ativado = true`.

### 8.3 — Troca de lente
Objetivo: alternar entre lentes disponíveis no aparelho.

Critérios de aceite:
- O seletor de lente mostra apenas as lentes fisicamente presentes no `AVCaptureDevice.DiscoverySession` daquele iPhone (regra 11.1) — em iPhone 13 mini, mostra só wide e ultra-wide.
- Trocar de lente não interrompe a sessão de captura (sem tela preta perceptível maior que 300ms).
- A última lente usada é lembrada entre sessões (`ultima_lente_usada`).

### 8.4 — Receitas (filtros de captura)
Objetivo: aplicar o visual das 4 receitas pré-configuradas em tempo real, no preview e na captura final.

Critérios de aceite:
- O seletor de receitas mostra as 4 opções (seção 11.2) com um thumbnail de preview ao vivo (não estático).
- Trocar de receita atualiza o preview do viewfinder em até 200ms.
- A receita ativa no momento do disparo é a que é aplicada ao JPEG final — não há como capturar sem receita nenhuma (a primeira receita da lista serve como "neutra").
- Receitas com `monocromatico = true` removem toda informação de cor do preview e do JPEG final.

### 8.5 — Salvar e permissões
Objetivo: garantir que o app só funciona com as permissões concedidas, com mensagens claras quando negadas.

Critérios de aceite:
- Na primeira abertura, o app pede permissão de câmera antes de mostrar o viewfinder.
- Se a permissão de câmera for negada, a tela mostra uma mensagem explicando o motivo e um botão que abre Ajustes do iOS.
- A permissão de biblioteca de fotos é pedida no momento da primeira captura (não no onboarding), com a justificativa de que é necessária para salvar a foto.
- Se a permissão de fotos for negada, a captura mostra um alerta e não perde a foto — mantém em memória até a permissão ser concedida ou a pessoa descartar.

### 8.6 — Onboarding
Objetivo: introduzir o app e pedir permissão de câmera em no máximo 2 telas.

Critérios de aceite:
- Onboarding tem no máximo 2 telas: (1) apresentação breve do app, (2) pedido de permissão de câmera.
- Onboarding só aparece uma vez — não reaparece em aberturas seguintes.

### 8.7 — Compra (paywall)
Objetivo: converter para compra única sem impedir que a pessoa experimente o app antes de pagar.

Fluxo: app é gratuito para abrir e explorar o viewfinder, os modos e as receitas; ao tentar salvar a primeira foto, aparece o paywall.

Critérios de aceite:
- A pessoa consegue abrir o app, trocar de modo, trocar de lente e trocar de receita sem ter comprado.
- Ao tocar no botão de disparo pela primeira vez sem `compra_desbloqueada = true`, aparece a tela de paywall antes de salvar a foto.
- Após a compra confirmada via StoreKit 2, `compra_desbloqueada` vira `true` e `data_compra` é preenchida; a foto que motivou o paywall é capturada e salva na sequência, sem a pessoa precisar tocar em disparar de novo.
- Botão de "Restaurar compra" disponível na tela de paywall e nas configurações.

### 8.8 — Configurações
Objetivo: reunir os ajustes que não fazem parte do fluxo de captura.

Critérios de aceite:
- Tela de Configurações permite trocar idioma (pt/en), ligar/desligar grid, nível, obturador silencioso e preview P&B do Modo Rua.
- Trocar o idioma reflete imediatamente em toda a interface, sem precisar reabrir o app.
- Tela de Configurações mostra a versão do app e um link para "Restaurar compra".

---

## 9. Fluxos principais ponta a ponta

**Fluxo 1 — Primeiro uso completo:**
1. Abre o app → onboarding (2 telas) → permissão de câmera concedida.
2. Viewfinder abre em Modo Rua, receita padrão ativa, lente padrão (wide) ativa.
3. Pessoa explora: troca de receita, troca de lente, alterna para Modo Pro e volta para Modo Rua — tudo sem paywall.
4. Toca em disparar → paywall aparece (app não estava comprado) → completa a compra → foto é capturada e salva automaticamente na Fototeca.
5. Próximas capturas não mostram mais o paywall.

**Exceção — permissão de fotos negada durante a primeira captura:**
1-4. Igual ao fluxo 1.
5. Sistema pede permissão de biblioteca de fotos → pessoa nega.
6. App mostra alerta, mantém a foto capturada em memória, e oferece botão para tentar salvar de novo (reabre o prompt de permissão do sistema, ou direciona a Ajustes se já foi negado permanentemente).

**Fluxo 2 — Troca de modo em uso normal:**
1. App já aberto em Modo Rua.
2. Pessoa toca no toggle de modo → transição para Modo Pro é imediata (sem tela de carregamento).
3. Sliders manuais aparecem sobre o mesmo viewfinder, mesma lente e mesma receita continuam ativas.

---

## 10. Inventário de telas

| Tela | O que mostra | Filtros/estados | Lê / escreve |
|---|---|---|---|
| Onboarding — Boas-vindas | Nome do app (placeholder), 1 frase de proposta de valor, botão "Continuar" | — | — |
| Onboarding — Permissão de câmera | Explicação curta do porquê da permissão, botão que aciona o prompt do sistema | Estado: aguardando resposta do sistema | escreve: nenhuma tabela (permissão é do sistema) |
| Viewfinder — Modo Rua | Preview em tela cheia, seletor de receita (carrossel horizontal na base), botão de disparo, toggle de modo (Rua/Pro), ícone de troca de lente, grid e nível sobrepostos se ativados | Estados: normal, foco travado (indicador visual), captura em andamento (breve flash), permissão negada | lê: `configuracao_usuario`, `receita` · escreve: `configuracao_usuario.ultima_lente_usada` |
| Viewfinder — Modo Pro | Mesmo preview em tela cheia + painel de sliders (ISO, shutter, exposição, foco, WB temperatura/tinta), toggle de zebra stripes, toggle de focus peaking | Estados: normal, ajustando slider (preview ao vivo), captura em andamento | lê: `configuracao_usuario`, `receita` · escreve: `configuracao_usuario.ultima_lente_usada` |
| Seletor de receita (expandido) | Grade com as 4 receitas, thumbnail de preview ao vivo de cada uma, nome de exibição | Estado: receita ativa destacada | lê: `receita` |
| Paywall | Preço, o que está incluso, botão de compra, botão "Restaurar compra" | Estados: normal, processando compra, erro de compra (ex: sem conexão com a App Store) | escreve: `configuracao_usuario.compra_desbloqueada`, `configuracao_usuario.data_compra` |
| Configurações | Idioma, grid, nível, obturador silencioso, preview P&B, versão do app, restaurar compra | — | lê/escreve: `configuracao_usuario` |
| Permissão negada (câmera ou fotos) | Mensagem explicando o motivo, botão que abre Ajustes do iOS | — | — |

---

## 11. Regras de negócio

**11.1 — Detecção de lentes disponíveis**

| Regra | Onde é aplicada |
|---|---|
| O seletor de lente mostra apenas as lentes retornadas por `AVCaptureDevice.DiscoverySession` para aquele aparelho específico, em tempo de execução | Frontend (Swift, na inicialização da sessão de câmera) |
| Se o aparelho tiver só 1 lente traseira, o ícone de troca de lente fica oculto (não desabilitado — oculto) | Frontend |
| iPhone 13 mini (aparelho de teste do Alexandre) expõe wide e ultra-wide, sem telephoto | Frontend — validado por teste manual no aparelho |

**11.2 — Parâmetros das 4 receitas (seed de `receita`)**

Valores aproximados por pesquisa de parâmetros publicamente documentados de simulações de filme Fujifilm (comunidade Fuji X Weekly) e Image Control da Ricoh GR III (comunidade Ricoh Recipes) — ver Anexo de Fontes. Não são cópia de algoritmo proprietário, são uma aproximação estética via Core Image.

| Receita (nome interno) | highlight | shadow | saturação | temp. WB | tinta WB | grão | nitidez | monocromático |
|---|---|---|---|---|---|---|---|---|
| "Classic" (insp. Classic Chrome) | -1 | +1 | +2 | quente (+shift R, -shift B) | 0 | fraco | +2 | não |
| "Soft" (insp. Astia/Soft) | -2 | 0 | -2 | fria (~2650K) | -8 | nenhum | -1 | não |
| "Mono" (insp. Acros+R) | -1 | +3 a +4 | — | neutro | -1 | forte | -2 | sim, filtro vermelho |
| "Positivo" (insp. Ricoh GR Positive Film) | -2 a -4 | +2 a +4 | +3 | fria, correção de highlight ativa | +3 | nenhum | 0 | não |

**11.3 — Pipeline de captura**

| Regra | Onde é aplicada |
|---|---|
| A receita ativa é aplicada via cadeia de `CIFilter` sobre o buffer de `AVCapturePhotoOutput` antes da codificação final em JPEG | Frontend (Swift/Core Image) |
| Não existe opção de capturar "sem filtro" — a primeira receita da lista (`ordem_exibicao = 1`, "Classic") funciona como padrão neutro-relativo | Frontend |
| O app não guarda cópia sem filtro da foto — só o JPEG final é salvo na Fototeca | Frontend |

**11.4 — Paywall**

| Regra | Onde é aplicada |
|---|---|
| Todas as telas e modos são navegáveis sem compra; o gate acontece só no primeiro toque em disparar | Frontend |
| Preço de venda: compra única, próxima de R$ 50 (valor final de listagem a definir na App Store Connect — ver Perguntas Abertas) | App Store Connect (fora do código) |
| Após compra confirmada, nenhum outro gate aparece nesse aparelho (StoreKit valida localmente) | Frontend (StoreKit 2) |

---

## 16. Direção visual

Referência funcional: densidade de controle parecida com apps de câmera manual (Halide, Moment), mas com menos elementos simultâneos na tela — pedido explícito do Alexandre de "clean e fácil de usar".

**Decidido:**
- Viewfinder sempre em fundo preto, independente do modo claro/escuro do sistema (princípio 4).
- Tipografia do sistema (SF Pro), sem fonte customizada.
- Ícones outline minimalistas, sem preenchimento sólido, para não competir visualmente com a imagem do viewfinder.
- Modo Rua tem no máximo 4 elementos de UI visíveis por cima do viewfinder ao mesmo tempo (seletor de receita, botão de disparo, toggle de modo, ícone de lente) — grid e nível não contam por serem sobreposições discretas na própria imagem.
- Cor de destaque (accent) usada só para: indicador de foco travado, receita ativa selecionada, e estado "ativado" de toggles — nunca como cor decorativa.

**Livre para o Claude Design propor:** paleta de cor de destaque (accent color) exata, ícone do app, tipo de transição entre Modo Rua e Modo Pro, formato exato dos sliders do Modo Pro.

---

## 17. Requisitos não-funcionais

| Requisito | Alvo |
|---|---|
| Tempo entre abrir o app e viewfinder pronto para disparar | < 1,5s em iPhone 13 mini ou mais recente |
| Tempo entre toque no disparador e JPEG salvo | < 1s |
| Tempo de troca de lente | < 300ms sem tela preta perceptível |
| Tempo de troca de receita (atualização do preview) | < 200ms |
| Compatibilidade mínima | iOS 17.0, iPhone com pelo menos 1 lente traseira (wide) |
| Orientação | Retrato apenas no MVP (câmera de rua é majoritariamente uso em retrato/rápido) |
| Offline | 100% funcional sem rede, incluindo validação de compra após a primeira confirmação |
| Idiomas | Português e inglês, com troca em tempo real na tela de Configurações |
| Acessibilidade | Área mínima de toque de 44×44pt em todos os controles; suporte a Dynamic Type nos textos fora do viewfinder (sliders e labels do Modo Pro) |
| Bateria | Sessão de câmera não deve permanecer ativa em segundo plano — encerrada ao sair do app |

---

## 18. Convenções de código, documentação e estrutura do repositório

- **Idioma:** como não há banco de dados tradicional (SQL/Postgres), a convenção padrão de "banco em português" se aplica às entidades SwiftData descritas na seção 7, que já usam nomenclatura em português (`configuracao_usuario`, `receita`). Código Swift, nomes de arquivo, funções e variáveis internas seguem inglês, padrão de mercado da plataforma — ver assunção 24.1.
- **Comentários obrigatórios:** toda `struct`/`class` de modelo SwiftData, todo `ViewModel` e toda função de processamento de imagem (Core Image) leva comentário de cabeçalho em português explicando o que faz e qual regra desta spec implementa (ex: `// aplica receita "Mono" — regra 11.2`).
- **Organização de pastas esperada:**
  ```
  App/
    Modelos/          (configuracao_usuario.swift, receita.swift)
    Camera/           (sessão AVFoundation, controle manual, discovery de lentes)
    Filtros/          (pipeline Core Image, definição das 4 receitas)
    Telas/
      Viewfinder/
      Paywall/
      Onboarding/
      Configuracoes/
    Compras/          (StoreKit 2)
    Localizacao/       (strings pt/en)
  ```
- **Documentação viva:** README com setup local, e o `DOCUMENTACAO-TECNICA.md` (seção 19) gerado ao fim da implementação.
- **Variáveis de ambiente:** nenhuma — app sem backend, sem chave de API externa.

---

## 19. Documento de documentação técnica (entregável ao fim da implementação)

Ao final da implementação, gerar `DOCUMENTACAO-TECNICA.md` na raiz do repositório, em português, com:
1. Modelo de dados explicado em português — o que `configuracao_usuario` e `receita` representam, campo a campo.
2. Relacionamento entre as tabelas (neste caso, nenhuma relação — são entidades independentes; declarar isso explicitamente).
3. Regras de negócio que vivem no código (não há banco com triggers — listar onde cada regra da seção 11 foi implementada no código Swift).
4. Mapa tela → dados: para cada tela da seção 10, o que ela lê e escreve.
5. Lógica das principais funcionalidades por tela — especialmente o pipeline de captura (11.3) e o gate de paywall (11.4).
6. Divergências em relação a este spec, com justificativa.

Toda mudança relevante no app atualiza este documento no mesmo commit.

---

## 20. Privacidade, segurança e conformidade

- **Dados coletados:** nenhum dado pessoal é coletado ou enviado a servidor — o app não tem backend. As únicas informações armazenadas ficam em `configuracao_usuario` (preferências) e ficam exclusivamente no aparelho.
- **Fotos capturadas:** vão direto para a Fototeca do sistema (framework Photos) — o app não mantém cópia própria além da foto em memória durante a captura.
- **Permissões solicitadas:** câmera (obrigatória, pedida no onboarding) e biblioteca de fotos (pedida no momento da primeira captura, com justificativa exibida antes do prompt do sistema).
- **Compra:** processada inteiramente pela StoreKit 2 / App Store — o app não lida com dados de cartão ou pagamento diretamente.
- **Retenção:** `configuracao_usuario` persiste enquanto o app estiver instalado; é removida junto com a desinstalação (comportamento padrão do SwiftData local).
- **LGPD:** por não haver coleta, transmissão ou armazenamento de dados pessoais fora do aparelho do próprio usuário, o app não processa dados pessoais na acepção da LGPD além do que o próprio sistema operacional já gerencia (permissões de câmera/fotos).
- Este app não embute IA generativa nem modelo de linguagem — não se aplicam guardrails de IA.

---

## 23. Riscos e mitigação

| Risco | Impacto | Probabilidade | Mitigação |
|---|---|---|---|
| Processamento Core Image em tempo real no preview pode não sustentar os alvos de 17.1 em iPhones mais antigos (iOS 17 mínimo inclui aparelhos com chip mais fraco que o A15) | Alto — experiência trava, reputação na loja | Média | Testar em pelo menos um aparelho mais antigo suportado (ex: iPhone com A12/A13) antes do lançamento; se necessário, subir o iOS mínimo ou simplificar a cadeia de filtro para aparelhos mais antigos |
| App Store review pode questionar app de câmera com preço alto (~R$ 50) sem trial claro | Médio — atraso de aprovação | Baixa-Média | Deixar claro nas notas de review que o app é gratuito para explorar e só cobra ao salvar a primeira foto (fluxo 1, seção 9) |
| Aproximação das receitas (11.2) pode não convencer visualmente quem já usa Fujifilm/Ricoh de verdade | Médio — expectativa de produto | Média | Validar visualmente com o próprio Alexandre em fotos reais antes do lançamento; ajustar parâmetros Core Image por comparação, não só por número copiado da receita original |
| Detecção de lentes (11.1) pode falhar silenciosamente em algum modelo de iPhone não testado | Médio | Baixa | Fallback: se `DiscoverySession` não retornar nenhuma lente, usar a câmera traseira padrão do sistema sem seletor de lente |

---

## 24. Assunções declaradas

1. **Nomenclatura de código em inglês, mesmo nas entidades SwiftData.** As entidades da seção 7 (`configuracao_usuario`, `receita`) mantêm nome em português (seguindo a convenção padrão), mas propriedades internas do Swift (ex: nomes de `enum` cases, variáveis de estado de UI) seguem inglês idiomático da plataforma. Se o Alexandre preferir português em tudo, é só avisar que ajusto.
2. **Paywall no primeiro disparo, não no onboarding.** Decisão de deixar a pessoa explorar o app antes de pagar, para reduzir fricção de decisão de compra sem ter visto o produto funcionando. Se preferir gate mais cedo (ex: já no onboarding), é só avisar.
3. **Orientação retrato apenas.** Câmeras de fotografia de rua costumam ser usadas em retrato rápido; suporte a paisagem fica fora do MVP. Se for importante, avisar para eu adicionar.
4. **Sem galeria própria dentro do app.** Fotos vão direto pra Fototeca do sistema; não há tela de "fotos recentes" dentro do app no MVP.
5. **Preço final de venda não fixado no spec.** Ficou definido "perto de R$ 50" em conversa — o valor exato de listagem na App Store Connect fica para a seção 25 (Perguntas Abertas), porque depende de faixa de preço disponível na loja e câmbio.
6. **Textos de copy final não escritos neste spec** (seção 15 não incluída) — nome do app ainda em aberto, então toda copy entra como placeholder no prompt de design, e será escrita depois que o nome for definido.

---

## 25. Perguntas abertas

| Pergunta | Quem decide | Até quando |
|---|---|---|
| Nome final do app | Alexandre | Antes de gerar o prompt de App Store Connect e os textos finais de copy |
| Valor exato de listagem na App Store Connect (faixa de preço da Apple mais próxima de R$ 50) | Alexandre | Antes da submissão à loja |
| Ícone do app | Alexandre (com apoio do Claude Design) | Antes da submissão à loja |
| Testar em pelo menos um iPhone mais antigo além do 13 mini, para validar o risco de performance (seção 23) | Alexandre | Antes do lançamento |

---

## 26. Definition of Done

- [ ] Todos os épicos da seção 8 implementados e validados contra os critérios de aceite.
- [ ] As 4 receitas da seção 11.2 aplicadas e comparadas visualmente pelo Alexandre contra referências reais.
- [ ] Localização em português e inglês completa, sem string hardcoded fora do sistema de localização.
- [ ] StoreKit 2 testado em sandbox, incluindo restauração de compra.
- [ ] Permissões de câmera e fotos testadas nos três estados (concedida, negada, negada permanentemente → Ajustes).
- [ ] Testado em iPhone 13 mini (aparelho do Alexandre) e em pelo menos 1 modelo adicional.
- [ ] `DOCUMENTACAO-TECNICA.md` gerado e conferido contra o app implementado.
- [ ] Nenhuma dependência de rede em nenhum fluxo.
- [ ] Ícone, nome e metadados da App Store Connect prontos (depende das perguntas abertas da seção 25).

---

## 27. Próximos passos operacionais

1. Revisar a seção 24 (Assunções) e a seção 25 (Perguntas abertas) — em especial o nome do app.
2. Gerar as telas no Claude Design a partir do `prompt-design-<produto>.md` entregue junto com este spec.
3. Criar o repositório, reaproveitando bundle ID prefix e Apple Developer Team dos outros apps.
4. Colar o prompt de implementação (entregue no chat) no Claude Code.
5. Validar visualmente as 4 receitas contra fotos reais antes de travar os parâmetros finais do Core Image.
6. Testar performance em pelo menos 1 iPhone mais antigo (risco da seção 23).

---

## 28. Roadmap — próximas releases

**Zone focus com presets de distância** (retirado do MVP em conversa — ver seção 3): presets de foco pré-calibrados (ex: 1m, 2m, 5m, infinito) usando `lensPosition` do `AVCaptureDevice`. Requer calibração manual por modelo de iPhone, testando um objeto a distância conhecida e anotando o `lensPosition` correspondente, porque o iOS não expõe essa propriedade em unidades de metros nem com mapeamento consistente entre modelos. Pode começar com calibração só para iPhone 13 mini e expandir depois.

**ProRAW, Apple Log, ProRes:** exclusivos de hardware iPhone Pro — aguardando o Alexandre ter acesso a um aparelho Pro para testar e validar antes de especificar.

**Criação de receitas customizadas pelo usuário:** editor de parâmetros (highlight, shadow, saturação, WB, grão) para a pessoa criar e salvar suas próprias receitas, além das 4 pré-instaladas.

**Suporte a iPad:** caso o produto pivote de fotografia de rua para outro uso onde iPad faça sentido.

---

## 29. Protocolo de mudanças incrementais

Depois que o v1 estiver pronto e publicado:

1. Fazer commit de checkpoint antes de qualquer mudança, para ter um `git diff` confiável.
2. Não colar o spec inteiro de novo — colar só o trecho novo/alterado, ou pedir um spec adicional específico da nova feature.
3. Escrever a instrução como diff ("o app já existe e funciona, adicione X sem alterar Y"), nunca como recomeço.
4. Delimitar explicitamente o que não deve mudar.
5. Pedir a lista de arquivos que serão criados/alterados antes do código, e aprovar antes de deixar o agente seguir.
6. Revisar o `git diff` contra o plano aprovado; reverter o que passou do escopo combinado.
7. Exigir atualização do `DOCUMENTACAO-TECNICA.md` no mesmo commit da mudança.

**Modelo de prompt para mudança incremental:**
```
O app [nome] já existe e está funcionando em produção. Quero adicionar: [descrição da mudança].
Não altere: [lista do que deve ficar intocado].
Antes de codar, monte um plano e a lista de arquivos que serão criados/alterados, e aguarde minha aprovação.
Ao final, atualize o DOCUMENTACAO-TECNICA.md refletindo a mudança.
```

---

## 30. Estado atual e changelog (atualizar a cada mudança)

Esta seção reflete o que o app **realmente é hoje**, sobre o escopo original das seções 0–29.
O detalhamento técnico (onde cada coisa vive no código, divergências, migrações) está em
**`DOCUMENTACAO-TECNICA.md`** — é a fonte de verdade técnica. Aqui fica o resumo de produto +
os pontos que **não podem ser quebrados** numa manutenção futura.

**Nome:** definido como **I See Life** (era aberto na seção 25). Ícone e accent âmbar `#FFB000`.

### Mecanismos que NÃO podem ser quebrados (armadilhas de manutenção)
1. **Receitas `hl/sh/sat` são guardadas em MEIO-PASSO ×2** (o valor no store é o dobro do real;
   ex.: -1,5 → -3). O `RecipeValues` divide por 2. Editar um valor de receita sem saber disso
   dobra/divide o efeito. (v1.1)
2. **`RecipeSeed.sincronizarCatalogo` roda a cada abertura**: faz upsert das receitas por
   `nomeExibicao` E **deleta** receitas fixas que saíram do código. Não dá pra adicionar/editar
   receita só no banco — tem que ser no código (senão é sobrescrita/apagada). Preserva
   `criadaPeloUsuario`.
3. **Migração SwiftData é aditiva**: campos novos em `receita`/`configuracao_usuario` precisam de
   **default inline no `@Model`** (enum: valor totalmente qualificado). **Não** trocar o tipo de
   um campo existente (ex.: Int→Double) sem plano de migração — quebra o launch de quem atualiza.
4. **Captura é frame-grab silencioso por padrão** (não `AVCapturePhotoOutput`); o disparo é no
   **touch-down** do botão. `AVCapturePhotoOutput` só quando `obturador_silencioso` = OFF.
5. **Modo Rua usa prioridade de obturador** (obturador fixo + ISO auto, loop em `CameraSession`),
   não exposição totalmente automática como dizia a seção 3 original.
6. **O projeto Xcode é gerado por XcodeGen** (`project.yml` é a fonte; o `.xcodeproj` é derivado e
   gitignorado). Rodar `xcodegen generate` após mexer em `project.yml`.

### v1.0 — publicado (build em revisão/aprovação): deltas sobre o escopo original
- **Receita "Neutra"** adicionada como ordem 1 e **padrão** (imagem crua do iPhone, sem filtro).
  São **5 receitas** na v1.0 (Neutra + as 4 da seção 11.2, com **Soft revisada** — WB 5600K/tint
  +1, não 2650K/-8, após validação visual).
- **Disparo pelos botões de volume** (`AVCaptureEventInteraction`, iOS 17.2+).
- **Quick Action da Tela de Início** (segurar o ícone → "Disparar").
- **Extensão de Control iOS 18** (Tela de Bloqueio/Central de Controle): embutida, mas com **bug
  conhecido — não registra**; deixada no build, a corrigir com target nativo do Xcode.
- **Prioridade de obturador no Rua** (piso 1/250·1/500·1/1000 em Configurações).
- **Feedback de disparo** (pop + haptic + piscar) e captura híbrida silencioso/nítido.

### v1.1 — pronto no repo, ainda NÃO publicado (sobe depois da v1 aprovar)
- **Receita "Vívida"** adicionada (ordem 6) → **6 receitas**. (Retrô/Retrato/Dourada foram
  prototipadas e removidas por não convencerem visualmente.)
- **Campos de fidelidade** em `receita`: `ajuste_vermelho`/`ajuste_azul` (WB shift Fuji R/B,
  eixo separado do `tinta_wb` que é verde/magenta), `efeito_color_chrome`(+`_azul`), `clareza`,
  `tamanho_grao`, `criada_pelo_usuario`; `hl/sh/sat` com meio-passo (ver armadilha 1).
- **Modo Pro:** botão **"Auto"** (recalibra pro automático, zera EV), **refresh** de foco/WB ao
  trocar de receita no Rua, painel que cabe os 6 sliders, e slider que não conflita com o scroll.
- **Zebra/Peaking escondidos** atrás de flag (`mostrarZebraPeaking = false`) até calibrar.
- **Cota grátis de 10 fotos antes do paywall** (`fotosGratisUsadas`, regra 11.4): app usável sem
  compra e sem login ("experimente antes de comprar"). Paridade com o Android — que precisou disso
  para passar na revisão da Play (revisor sem conta de teste). Vai na **1.2.0** (1.1.0 já está aprovada na loja).
- **2 receitas em teste (build 7, iOS primeiro):** "Retrato 400" (ordem 7) e "Retrato 800" (ordem 8)
  — emulações de negativo de retrato (base Classic Chrome, insp. Fujifilm). Nomes sem marca de
  terceiro; 400/800 = ISO. Vão pro TestFlight; se aprovarem visualmente, sobem à produção e depois
  entram no Android; se não, saem do catálogo (`sincronizarCatalogo` deleta as removidas). Sem campo
  no modelo para Dynamic Range/Noise Reduction — aproximação pela curva de tom e grão.

### Backlog (futuro, não crítico)
- App Shortcut "Disparar" (AppShortcutsProvider). · Control nativo da Tela de Bloqueio (target
  Xcode nativo). · Calibrar/reativar Zebra/Peaking. · Itens do roadmap seção 28.

---

## Anexo — Fontes

- Parâmetros de referência da simulação Classic Chrome: Fuji X Weekly, "My Fujifilm X100F Classic Chrome Film Simulation Recipe" e "Fujifilm Classic Chrome Film Simulation Recipes" — consultado em 07/08/2026.
- Parâmetros de referência da simulação Astia/Soft: Fuji X Weekly, "Astia Film Simulation recipe" e "My 5 Favorite Film Simulation Recipes that use Astia" — consultado em 07/08/2026.
- Parâmetros de referência da simulação Acros/Monochrome: Fuji X Weekly, "Understanding Acros Film Simulation Options On Fujifilm X Cameras" e "Fujifilm X-Trans IV Film Simulation Recipe: Moody Monochrome" — consultado em 07/08/2026.
- Parâmetros de referência do Ricoh GR III Positive Film: Ricoh Recipes, "The Analog Collection"; Medium/Rokkorxblog, "Ricoh GR3 / GR2 Custom JPEG Film Simulation Settings"; GR Blog official, "GR III Review — Image Control (Emi)" — consultado em 07/08/2026.
