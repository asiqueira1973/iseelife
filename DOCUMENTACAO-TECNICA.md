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
| `highlight` | Int (-4…+4) | Curva de tom nas altas luzes. |
| `shadow` | Int (-4…+4) | Curva de tom nas sombras. |
| `saturacao` | Int (-4…+4) | Saturação; ignorada em receita monocromática. |
| `temperaturaWbKelvin` | Int? | Kelvin assumido da cena (dial de WB); nulo = segue o sensor. |
| `tintaWb` | Int (-9…+9) | Eixo verde/magenta. |
| `intensidadeGrao` | `IntensidadeGrao` | nenhum/fraco/medio/forte. |
| `nitidez` | Int (-4…+4) | Positivo = sharpen; negativo = leve desfoque. |
| `monocromatico` | Bool | Remove toda a cor no preview e no JPEG. |
| `filtroMono` | `FiltroMono?` | Filtro colorido simulado (nenhum/amarelo/vermelho/verde); só com mono. |
| `ordemExibicao` | Int | Ordem fixa no seletor; a de ordem 1 é o padrão neutro. |

Valores de seed (tabela 11.2), em `Sources/Filtros/RecipeSeed.swift`:

| Receita | hl | sh | sat | temp WB | tinta | grão | nitidez | mono |
|---|---|---|---|---|---|---|---|---|
| Classic | -1 | +1 | +2 | 7000K | 0 | fraco | +2 | não |
| Soft | -2 | 0 | -2 | 2650K | -8 | nenhum | -1 | não |
| Mono | -1 | +4 | 0 | nulo | -1 | forte | -2 | sim (vermelho) |
| Positivo | -3 | +3 | +3 | 5000K | +3 | nenhum | 0 | não |

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
- Gate no primeiro disparo: `ViewfinderViewModel.disparar()` — se `compraDesbloqueada == false`,
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

---

## 6. Divergências em relação ao spec

1. **Captura sempre silenciosa (frame-grab).** O iOS não tem API pública para mutar o som do
   `AVCapturePhotoOutput`. Para garantir o obturador silencioso (default e princípio do
   produto), a captura usa o último frame de vídeo em full-frame em vez do `AVCapturePhotoOutput`.
   Consequência: a captura é sempre silenciosa; o toggle `obturador_silencioso` é persistido e
   exibido, mas **não** alterna para um caminho audível de foto (não implementado no MVP). Também
   implica resolução de captura = resolução do frame de vídeo sob preset `.photo` (alta, porém
   não necessariamente a máxima do `AVCapturePhotoOutput`). Recomendo validar a resolução no
   iPhone 13 mini antes do lançamento.

2. **Dois campos de UI a mais na `configuracao_usuario`.** `onboardingConcluido` e
   `receitaAtivaID` não estão no DBML original. Foram adicionados como estado de UI singleton
   que precisa persistir entre sessões (não reabrir o onboarding — critério 8.6; lembrar a
   receita ativa). Nenhuma relação nova foi criada.

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
