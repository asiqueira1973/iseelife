# Documentação Técnica — I See Life

Documento gerado ao fim da implementação, conforme a seção 19 do `spec.md`. Cobre os 6
itens exigidos: modelo de dados, relacionamento entre entidades, regras de negócio no
código, mapa tela → dados, lógica das principais funcionalidades por tela e divergências
em relação ao spec.

App: câmera de fotografia de rua iOS, local-first, 100% offline. Swift + SwiftUI, SwiftData,
AVFoundation, Core Image, StoreKit 2. iOS 17.0+, iPhone apenas, retrato apenas.

O projeto Xcode é gerado por XcodeGen a partir de `project.yml` (`xcodegen generate`).

---

## 1. Modelo de dados (explicado)

Duas entidades SwiftData independentes, com nome em português (convenção da seção 7/18); o
código Swift usa inglês idiomático (assunção 24.1). Definidas em `Sources/Modelos/`.

### `configuracao_usuario` — `ConfiguracaoUsuario.swift`

Linha única (singleton), criada no primeiro uso. Guarda todas as preferências locais. É
atualizada in-place; nunca excluída pelo usuário no MVP.

| Campo | Tipo | Significado |
|---|---|---|
| `id` | UUID (pk) | Identificador da linha. |
| `idiomaPreferido` | `Idioma` (pt/en) | Idioma da interface. Default `pt`. Alimenta a troca em tempo real. |
| `modoPadrao` | `ModoCaptura` (rua/pro) | Modo ao abrir o visor. Default `rua` (princípio 0.1). |
| `ultimaLenteUsada` | `LenteCamera?` (wide/ultra_wide) | Última lente usada; nulo até a 1ª captura. Lembrada entre sessões. |
| `gridAtivado` | Bool | Grid de terços sobreposto. Default `true`. |
| `nivelAtivado` | Bool | Indicador de nível/giroscópio. Default `true`. |
| `obturadorSilencioso` | Bool | Captura sem som. Default `true`. |
| `previewPbAtivado` | Bool | Preview P&B no Modo Rua (só afeta o preview). Default `false`. |
| `compraDesbloqueada` | Bool | Vira `true` após a compra confirmada (regra 11.4). Default `false`. |
| `dataCompra` | Date? | Preenchida quando a compra é confirmada; nulo antes. |
| `onboardingConcluido` | Bool | Controla se o onboarding reaparece (critério 8.6). Estado de UI persistido. |
| `receitaAtivaID` | UUID? | Última receita escolhida; nulo => usa a de `ordemExibicao = 1` (regra 11.3). |

> `onboardingConcluido` e `receitaAtivaID` não constam no DBML original — são estado de UI
> local que persiste entre sessões; ficam aqui por serem preferências singleton. Ver
> divergências (item 6).

### `receita` — `Receita.swift`

Catálogo fixo de 4 receitas de cor, inserido por seed na primeira execução, somente-leitura
no MVP. Cada campo alimenta o pipeline Core Image (regra 11.2/11.3).

| Campo | Tipo | Significado |
|---|---|---|
| `id` | UUID (pk) | Identificador. |
| `nomeExibicao` | String | Rótulo na UI ("Classic", "Soft", "Mono", "Positivo"). |
| `inspiracao` | String | Referência interna (não exibida como marca de terceiro). |
| `highlight` | Int (meio-passo ×2) | Curva de tom nas altas luzes. Guardado ×2 (v1.1). |
| `shadow` | Int (meio-passo ×2) | Curva de tom nas sombras. Guardado ×2. |
| `saturacao` | Int (meio-passo ×2) | Saturação; ignorada em receita monocromática. Guardado ×2. |
| `temperaturaWbKelvin` | Int? | Kelvin assumido da cena (dial de WB); nulo = segue o sensor. |
| `tintaWb` | Int (-9…+9) | Eixo **verde/magenta** (NÃO vermelho/azul). |
| `intensidadeGrao` | `IntensidadeGrao` | Força do grão: nenhum/fraco/medio/forte. |
| `nitidez` | Int (-4…+4) | Positivo = sharpen; negativo = leve desfoque. |
| `monocromatico` | Bool | Remove toda a cor no preview e no JPEG. |
| `filtroMono` | `FiltroMono?` | Filtro colorido simulado (nenhum/amarelo/vermelho/verde); só com mono. |
| `ordemExibicao` | Int | Ordem fixa no seletor; a de ordem 1 é o padrão neutro. |
| `ajusteVermelho` | Int (v1.1) | WB shift no eixo **vermelho** (modelo Fuji R/B); ganho no canal R. Default 0. |
| `ajusteAzul` | Int (v1.1) | WB shift no eixo **azul**; ganho no canal B. Default 0. |
| `efeitoColorChrome` | `EfeitoColorChrome` (v1.1) | Compressão de saturação nos tons saturados (eixo quente). |
| `efeitoColorChromeAzul` | `EfeitoColorChrome` (v1.1) | Idem, eixo azul. |
| `clareza` | Int -4…+4 (v1.1) | Contraste local (diferente de nitidez). |
| `tamanhoGrao` | `TamanhoGrao` (v1.1) | Tamanho do grão: pequeno/grande. |
| `criadaPeloUsuario` | Bool (v1.1) | false no catálogo fixo; prepara receitas customizadas (roadmap). |

> **Meio-passo ×2 (v1.1):** para aceitar -1,5 / +0,5 sem trocar o tipo `Int` (o que quebraria a
> migração SwiftData para quem já tem a v1 publicada), `highlight`/`shadow`/`saturacao` guardam o
> valor **dobrado** (ex.: -1,5 → -3). O `RecipeValues` divide por 2. Os campos novos têm default
> inline no `@Model`, então a migração da v1 → v1.1 é **aditiva e automática**.

Valores de seed (valor REAL; no store `hl/sh/sat` ficam ×2), em `Sources/Filtros/RecipeSeed.swift`.
Ordem 1 = Neutra/raw (padrão). As 5 primeiras vêm da tabela 11.2 (Soft revisada); as 4 últimas
são o enhancement v1.1 (inspiração em filmes clássicos, referência em `inspiracao`):

| Ordem | Receita | hl | sh | sat | temp WB | R/B | grão (força·tam) | nitidez | clareza | color chrome (Q·Az) |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Neutra | 0 | 0 | 0 | nulo | 0/0 | nenhum | 0 | 0 | –·– |
| 2 | Classic | -1 | +1 | +2 | 7000K | 0/0 | fraco·peq | +2 | 0 | –·– |
| 3 | Soft | -2 | 0 | -2 | 5600K | 0/0 | nenhum | -1 | 0 | –·– |
| 4 | Mono | -1 | +4 | 0 | nulo | 0/0 | forte·peq | -2 | 0 | –·– |
| 5 | Positivo | -3 | +3 | +3 | 5000K | 0/0 | nenhum | 0 | 0 | –·– |
| 6 | Vívida | 0 | +0,5 | +2 | 5500K | +2/-5 | fraco·peq | +1 | +3 | forte·– |

> **v1.1 — só a Vívida foi mantida.** As outras 3 receitas novas propostas (Retrô/Retrato/Dourada)
> foram removidas após validação visual no device (só a Vívida convenceu). O `sincronizarCatalogo`
> agora também **deleta** receitas fixas que saíram do catálogo (por `nomeExibicao`), respeitando
> `criadaPeloUsuario`, então elas somem de quem já tinha instalado a versão de teste.

**"Neutra"** (enhancement): todos os parâmetros neutros — o `RecipePipeline` faz early-return e
devolve o frame do sensor intacto (raw). É a `ordem 1`, o padrão neutro da regra 11.3. O
`sincronizarCatalogo` faz upsert por `nomeExibicao` (identidade estável) e copia TODOS os campos
(inclusive os novos), então a v1.1 propaga os valores/receitas na 1ª abertura sem invalidar
`receitaAtivaID` nem embaralhar as receitas existentes.

**Novos estágios do pipeline (v1.1), aditivos** — só agem quando o campo ≠ neutro, então as 5
receitas originais saem idênticas: `applyRedBlueShift` (ganho por canal R/B), `applyColorChrome`
(compressão de saturação — **aproximação** global, Core Image não tem compressão por hue nativa),
`applyClareza` (unsharp de raio grande = contraste local) e o grão passa a escalar o ruído quando
`tamanhoGrao == .grande`.

---

## 2. Relacionamento entre as entidades

**Não há relação entre `configuracao_usuario` e `receita`.** São entidades independentes, sem
chave estrangeira, sem `@Relationship`. A ligação "qual receita está ativa" é feita por valor
(`configuracao_usuario.receitaAtivaID` guarda o `id` da receita escolhida), não por relação
de modelo. Isso está declarado explicitamente aqui conforme exige a seção 19, item 2, e
condiz com o comentário final do `modelo-app-camera-rua.dbml`.

Também não há lógica no "banco": sem triggers, sem funções, sem RLS (SwiftData local).

---

## 3. Regras de negócio no código (seção 11)

Todas as regras vivem no código Swift (não há banco com triggers). Onde cada uma foi
implementada:

### 11.1 — Detecção de lentes disponíveis
- `Sources/Camera/LensDiscovery.swift`: `AVCaptureDevice.DiscoverySession` com
  `builtInUltraWideCamera` + `builtInWideAngleCamera`, posição traseira. Retorna só as lentes
  fisicamente presentes. Fallback (risco seção 23): sem nenhuma lente enumerada, usa
  `AVCaptureDevice.default(for: .video)` como wide.
- `Sources/Telas/Viewfinder/ViewfinderScreen.swift`: o `LensButton` só é exibido quando
  `camera.lentesDisponiveis.count > 1` — com 1 lente o ícone fica **oculto** (não desabilitado).

### 11.2 — Parâmetros das 4 receitas
- Seed em `Sources/Filtros/RecipeSeed.swift` (valores da tabela 11.2).
- Aplicação em `Sources/Filtros/RecipePipeline.swift`: cadeia de `CIFilter` —
  `temperatureAndTint` (WB) → `toneCurve` (highlight/shadow) → `colorControls`/`colorMatrix`
  (saturação ou monocromático + filtro colorido) → `sharpenLuminance`/`gaussianBlur` (nitidez)
  → grão procedural (`randomGenerator` + `softLightBlendMode`).

### 11.3 — Pipeline de captura
- `Sources/Camera/CameraCapture.swift`: a mesma `RecipePipeline` que gera o preview é aplicada
  ao último frame cru na captura, antes de codificar o JPEG (`ciContext.jpegRepresentation`).
- Não existe caminho "sem filtro": a receita de `ordemExibicao = 1` ("Classic") é o padrão
  neutro-relativo — resolvido em `ViewfinderViewModel.init` e `RecipeSeed`.
- O app não guarda cópia sem filtro: só o `Data` do JPEG final é produzido e salvo.

### 11.4 — Paywall
- Todas as telas/modos são navegáveis sem compra — nenhuma tela chama gate exceto o disparo.
- **Cota grátis (v1.1, `fotosGratisUsadas`):** as primeiras **10 fotos** são salvas de graça
  (`ViewfinderViewModel.quotaGratis = 10`); cada foto grátis incrementa `config.fotosGratisUsadas`.
  Assim o app é totalmente usável sem compra e sem login ("experimente antes de comprar" — e o
  revisor de loja acessa tudo). Um indicador discreto ("N fotos grátis") aparece no Modo Rua antes
  da compra. Paridade com o Android.
- Gate após a cota: `ViewfinderViewModel.disparar()` — se não comprado E `fotosGratisUsadas >= 10`,
  captura o frame para memória (`fotoPendente`) e apresenta o paywall; não salva ainda.
- Após compra confirmada: `ViewfinderViewModel.compraConcluida()` marca
  `compraDesbloqueada`/`dataCompra` e salva a `fotoPendente` sem novo toque.
- Validação local: `StoreManager.atualizarEntitlement()` lê `Transaction.currentEntitlements`
  — offline após a primeira confirmação.

---

## 4. Mapa tela → dados (seção 10)

| Tela | Arquivo | Lê | Escreve |
|---|---|---|---|
| Onboarding — Boas-vindas | `Telas/Onboarding/OnboardingView.swift` | — | — |
| Onboarding — Permissão câmera | idem | permissão do sistema | `configuracao_usuario.onboardingConcluido` |
| Viewfinder — Modo Rua | `Telas/Viewfinder/ViewfinderScreen.swift` | `configuracao_usuario`, `receita` | `ultimaLenteUsada`, `receitaAtivaID` |
| Viewfinder — Modo Pro | idem + `ProControlsPanel.swift` | `configuracao_usuario`, `receita` | `ultimaLenteUsada`, `gridAtivado`, `nivelAtivado` |
| Seletor de receita | `Telas/Viewfinder/RecipeSelectorSheet.swift` | `receita` | `receitaAtivaID` (via callback) |
| Paywall | `Telas/Paywall/PaywallView.swift` | produto StoreKit | `compraDesbloqueada`, `dataCompra` (via VM) |
| Configurações | `Telas/Configuracoes/SettingsView.swift` | `configuracao_usuario` | `idiomaPreferido`, `gridAtivado`, `nivelAtivado`, `obturadorSilencioso`, `previewPbAtivado`, `compraDesbloqueada`, `dataCompra` |
| Permissão negada | `Telas/Permissoes/PermissionDeniedView.swift` | — | — |

---

## 5. Lógica das principais funcionalidades por tela

### Roteamento inicial — `Sources/App/RootView.swift`
Cria a `configuracao_usuario` singleton se não existir, roda `RecipeSeed.seedIfNeeded`, aplica
o idioma salvo e roteia: onboarding → (permissão negada | visor). Mantém `CameraSession` e
`StoreManager` como `@StateObject` para toda a sessão.

### Preview ao vivo — `CameraSession` + `MetalCameraPreview` + `RecipePipeline`
`AVCaptureVideoDataOutput` entrega frames na `videoQueue`. Cada frame (`CameraCapture.swift`)
vira `CIImage`, é guardado cru (para a captura), recebe a receita ativa via `RecipePipeline`,
e — no Modo Pro — zebra/peaking. O resultado vai ao `CameraPreviewRenderer` (MTKView), que
desenha em aspect-fill sobre fundo preto. Preview P&B do Modo Rua força desaturação só no
preview.

### Toque para travar foco (Modo Rua) — épico 8.1
`ViewfinderScreen` converte o toque em ponto normalizado 0…1 e chama
`ViewfinderViewModel.tocarPara`, que trava foco/exposição no ponto (`ManualCameraControls`) e
mostra o `FocusLockIndicator` (some após ~1s).

### Captura silenciosa — épico 8.1 / regra 11.3
`ViewfinderViewModel.disparar()` chama `CameraSession.capturarFotoJPEG`, que aplica a receita
ao último frame cru (full-frame) e codifica JPEG — sem tocar som de obturador. Depois aplica o
gate de paywall ou salva.

### Pipeline de captura + gate de paywall — regra 11.3/11.4
Detalhado nos itens 3 (11.3) e 3 (11.4) acima. O salvamento na Fototeca é feito por
`PhotoLibrarySaver` (autorização "add only", pedida no 1º save). Se negada, a foto fica em
memória (`fotoPendente`) e um alerta oferece tentar de novo ou ir a Ajustes (fluxo de exceção
da seção 9).

### Modo Pro — épico 8.2
`ProControlsPanel` mapeia cada slider (`ProSlider`) para os setters de `ManualCameraControls`
(ISO, obturador, exposição, foco via `lensPosition`, WB temperatura/tinta) com
`lockForConfiguration`. Zebra (>95% de luminância, listras diagonais) e focus peaking (bordas
Sobel em âmbar) são sobreposições só de preview (`ZebraPeakingFilters`).

### Troca de idioma em tempo real — épico 8.8
`LocalizationManager` carrega manualmente o bundle `.lproj` do idioma atual e republica via
`@Published`, forçando o redraw. `SettingsView` chama `aplicar(_:)` e persiste
`idiomaPreferido`. Toda string de UI passa por `L("chave")` — nenhuma string hardcoded fora
do sistema de localização.

### Compra — épico 8.7
`StoreManager` (StoreKit 2): carrega o produto não-consumível `iseelife_desbloqueio_completo`,
compra, verifica a transação, finaliza e expõe posse via entitlement. `restaurar()` faz
`AppStore.sync()` e reconsulta. Preço vem do StoreKit (`displayPrice`), nunca hardcoded.

### Extensão de Control (Central de Controle / Tela de Bloqueio) — iOS 18+
Target separado **`ISeeLifeControls`** (WidgetKit `ControlWidget`), bundle
`com.dablab.iseelife.controls`, embutido no app. Em `Sources/Controls/`:
- `ShootControl.swift` — `ControlWidget` (botão) + `AbrirISeeLifeIntent` (`AppIntent` com
  `openAppWhenRun = true`). Nome exibido "I See Life", ícone SF Symbol `eye` (coerente com o
  ícone do app), tint âmbar.
- `ISeeLifeControlBundle.swift` — `@main WidgetBundle`.
- `Info.plist` — ponto de extensão `com.apple.widgetkit-extension`.

**Como se comunica com o app:** não compartilha estado (sem App Group). O Control apenas **abre
o app** (`openAppWhenRun`); como o app já abre no visor do Modo Rua por padrão
(`modo_padrao = rua`, sem tela intermediária após o onboarding), o atalho entrega o "pronto para
disparar" (princípio 0.1) sem tocar em nenhuma lógica existente (captura, receitas, paywall,
modelo). É puramente aditivo.

**Disponibilidade:** a partir do **iOS 18.0** (o target da extensão é iOS 18; o app principal
segue iOS 17.0). Em iOS 17 o app funciona igual, só não expõe o Control — mesmo comportamento de
Moment/LUX.

### Quick Action da Tela de Início (segurar o ícone) — todos os iOS
`Sources/App/Info.plist` → `UIApplicationShortcutItems`: um atalho estático **"Disparar /
Modo Rua"** (ícone de sistema `UIApplicationShortcutIconTypeCapturePhoto`). Segurar o ícone do
app na Home mostra o atalho; tocar abre o app, que já cai no visor do Modo Rua (princípio 0.1).
É estático (sem código), funciona em **qualquer versão do iOS** e **não depende** da extensão de
Control nem do iOS 18 — é o "atalho de segurar o ícone" que o usuário de fato usa (estilo Leica
LUX). Não confundir com o Control da Central de Controle (abaixo), que é outra coisa.

### Disparo pelos botões de volume (hardware) — iOS 17.2+
`Sources/Camera/HardwareShutter.swift` — `UIViewRepresentable` que adiciona um
`AVCaptureEventInteraction` (AVKit, API oficial da Apple) ao visor. Os DOIS botões de volume
(handlers `primary` e `secondary`) chamam o mesmo `ViewfinderViewModel.disparar()` no fim do
clique (`.phase == .ended`). Ativo só com a câmera em primeiro plano; ignorado enquanto um
sheet/paywall está aberto. Botão físico elimina o tremor do toque na tela (complementa a captura
no touch-down). O feedback tátil do disparo foi unificado em `disparar()` (vale para o botão da
tela e para o volume). Disponível a partir do **iOS 17.2** (`@available`); em 17.0–17.1 o app
funciona sem esse atalho.

---

## 6. Divergências em relação ao spec

1. **Captura híbrida silenciosa/nítida (obturador silencioso funcional).** O iOS não tem API
   pública para mutar o som do `AVCapturePhotoOutput`, então a captura tem dois caminhos,
   escolhidos pelo toggle `obturador_silencioso` (agora funcional, `CameraCapture.swift`):
   - **ON (padrão):** frame-grab do último quadro de vídeo — silencioso; resolução = frame de
     vídeo sob preset `.photo`.
   - **OFF:** `AVCapturePhotoOutput` (`photoQualityPrioritization = .quality`) — nítido, com
     estabilização e fotografia computacional da Apple; toca o som do obturador.
   Em ambos, a mesma receita é aplicada antes do JPEG. O disparo acontece no **touch-down** do
   botão (`ShutterButton`), pegando o quadro antes do tremor do clique — correção do motion blur
   observado no device.

1b. **Prioridade de obturador no Modo Rua (enhancement pós-spec, pedido no device).** O spec
   define o Rua como exposição totalmente automática; na validação com o Alexandre (fotógrafo de
   rua), ficou claro que o auto às vezes escolhia obturador lento demais → motion blur. O Rua
   agora usa **prioridade de obturador**: velocidade fixa (piso configurável) + ISO automático
   via um loop amortecido a ~8Hz (`CameraSession.ajustarISOParaObturadorFixo`). Piso escolhido em
   Configurações › Captura (1/250 padrão, 1/500, 1/1000), campo `ruaObturadorDenominador`. No Pro,
   o loop é desligado e valem os controles manuais.

1c. **Sem controle de abertura no Pro (limitação de hardware).** O iPhone tem abertura fixa
   (f/1.6 wide / f/2.4 ultra-wide no 13 mini); não há íris mecânica nem API para variá-la. Por
   isso o Pro expõe ISO, obturador, exposição, foco e WB — como o spec já previa —, sem abertura.

2. **Dois campos de UI a mais na `configuracao_usuario`.** `onboardingConcluido`,
   `receitaAtivaID` e `ruaObturadorDenominador` não estão no DBML original. Foram adicionados como
   estado de UI/preferência singleton que persiste entre sessões (não reabrir o onboarding —
   critério 8.6; lembrar a receita ativa; lembrar o piso de obturador do Rua). Campos opcionais,
   migração aditiva segura. Nenhuma relação nova foi criada.

2c. **Ajustes de UX do device.** Configurações acessíveis também no Modo Rua (engrenagem no topo);
   painel do Pro com altura limitada + rolagem e alça "Ocultar controles" (cabe no 13 mini);
   feedback de disparo (pop do botão + vibração + piscar do visor); catálogo de receitas
   sincronizado a cada abertura (`sincronizarCatalogo`) para que ajustes de receita propaguem.

2b. **Soft revisado por validação visual no device.** A tabela 11.2 dava Soft com WB 2650K +
   tint -8, que na cadeia Core Image produzia uma dominante verde-teal — longe do Astia/Soft
   real (suave, baixo contraste, saturação contida, pele levemente quente, sem verde). A pedido
   do Alexandre e conforme o DoD (ajuste por comparação visual), Soft foi revisado para WB
   **5600K** e tint **+1**. A escala global do tint na cadeia também caiu de ×10 para ×4 (o -8
   original ficava agressivo demais). Seed em `RecipeSeed.swift`; o catálogo agora sincroniza a
   cada abertura (`sincronizarCatalogo`), então ajustes futuros de receita propagam sozinhos.

3. **Valores concretos onde o spec dá faixa/qualitativo (tabela 11.2).** O modelo exige números;
   onde o spec traz faixa ou termo qualitativo, escolhi um valor dentro da orientação e anotei:
   Mono `shadow` "+3 a +4" → **+4**; Positivo `highlight` "-2 a -4" → **-3** e `shadow`
   "+2 a +4" → **+3**; Classic WB "quente" → **7000K**; Positivo WB "fria" → **5000K**; Mono WB
   "neutro" → **nulo**. A "correção de highlight ativa" do Positivo é coberta pelo `highlight`
   negativo forte. Os parâmetros Core Image ainda devem ser **validados visualmente** contra
   fotos reais (DoD / risco seção 23) — os números são ponto de partida, não verdade final.

4. **Modo Pro: WB do sensor vs. WB da receita.** O slider de WB do Modo Pro ajusta o white
   balance do sensor (`AVCaptureDevice`), e a receita aplica seu próprio grade de WB por cima
   (Core Image). São dois estágios independentes, ambos previstos no spec (seção 3 lista os dois);
   registro aqui para deixar explícito que não se anulam.

5. **Foco em `lensPosition` (0…1), sem metros.** Coerente com o spec: zone focus com presets de
   distância fica fora do MVP (seção 3/28) por não haver calibração em metros no iOS.

6. **Nível via CoreMotion.** O indicador de nível usa `CMMotionManager` (roll). Não muda
   comportamento de captura; é sobreposição discreta de visor.

### Itens que dependem de device / loja (não codificáveis aqui, DoD/seção 25)
- Preço final de listagem na App Store Connect (o `ISeeLife.storekit` usa R$ 49,90 só para
  teste em sandbox, conforme combinado).
- Teste de StoreKit em sandbox, permissões nos 3 estados e captura real de foto exigem device
  físico — o simulador não expõe câmera. As telas sem câmera (onboarding, Modo Rua/Pro,
  seletor, configurações, troca de idioma) foram validadas no simulador.
- Validação visual das 4 receitas e teste em um iPhone mais antigo além do 13 mini.
