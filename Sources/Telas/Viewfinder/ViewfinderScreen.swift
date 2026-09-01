// ViewfinderScreen.swift
// Tela principal do visor (telas 03/04 / inventário seção 10). Compõe: preview Metal em tela
// cheia (fundo preto — princípio 0.4), toque para travar foco (épico 8.1), grid/nível
// sobrepostos, controles do Modo Rua (toggle de modo, lente, carrossel de receitas, disparo)
// e o painel do Modo Pro. Hospeda os sheets de seletor de receita, paywall e configurações.

import SwiftUI
import SwiftData

struct ViewfinderScreen: View {
    @StateObject private var vm: ViewfinderViewModel
    @ObservedObject var camera: CameraSession
    let config: ConfiguracaoUsuario
    // Painel de controles do Pro recolhido? Permite ver o visor limpo sem sair do Modo Pro.
    @State private var proRecolhido = false

    // Cria o ViewModel uma única vez (via @StateObject) a partir das dependências da raiz.
    init(camera: CameraSession, store: StoreManager, context: ModelContext,
         config: ConfiguracaoUsuario, receitas: [Receita]) {
        self.camera = camera
        self.config = config
        _vm = StateObject(wrappedValue: ViewfinderViewModel(
            camera: camera, store: store, context: context, config: config, receitas: receitas))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Estilo.fundoVisor.ignoresSafeArea()

                // Preview ao vivo + toque para travar foco/exposição (épico 8.1).
                MetalCameraPreview(session: camera)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { local in
                        let norm = CGPoint(x: local.x / geo.size.width, y: local.y / geo.size.height)
                        vm.tocarPara(pontoNormalizado: norm, pontoView: local)
                    }

                // Disparo pelos botões de volume (hardware), iOS 17.2+. Não dispara enquanto
                // um sheet/paywall está aberto.
                if #available(iOS 17.2, *) {
                    HardwareShutter {
                        guard !vm.mostrandoPaywall, !vm.mostrandoConfiguracoes, !vm.mostrandoSeletor else { return }
                        vm.disparar()
                    }
                    .allowsHitTesting(false)
                    .frame(width: 1, height: 1)
                }

                // Sobreposições discretas (não contam como os 4 elementos de UI — seção 16).
                if config.gridAtivado { GridOverlay().ignoresSafeArea() }
                if config.nivelAtivado { LevelOverlay().ignoresSafeArea() }

                // Indicador de foco travado (some após ~1s).
                if let ponto = vm.focoTravadoPontoView {
                    FocusLockIndicator(ponto: ponto)
                }

                // Piscar de obturador: escurece o visor por um instante (leitura de "clic").
                if vm.capturando {
                    Color.black.ignoresSafeArea()
                        .transition(.opacity)
                }

                // Controles inferiores fixados na base (carrossel/Rua ou painel/Pro).
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    controlesInferiores(geo: geo)
                }
                // Barra superior fixada no topo, SEMPRE por cima e acessível — assim o toggle
                // RUA/PRO nunca é empurrado para fora por um painel alto (bug do 13 mini).
                VStack(spacing: 0) {
                    barraSuperior
                    Spacer(minLength: 0)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: vm.capturando)
            .animation(.easeInOut(duration: 0.2), value: vm.modo)
        }
        .statusBarHidden(true)
        .onAppear { vm.aoAparecer() }
        .onDisappear { vm.aoDesaparecer() }
        // Seletor de receita expandido (tela 05).
        .sheet(isPresented: $vm.mostrandoSeletor) {
            RecipeSelectorSheet(
                receitas: vm.receitas, ativa: vm.receitaAtiva, camera: camera,
                aoSelecionar: { vm.selecionarReceita($0); vm.mostrandoSeletor = false },
                aoFechar: { vm.mostrandoSeletor = false }
            )
            .presentationDetents([.large])
        }
        // Paywall no primeiro disparo (regra 11.4).
        .fullScreenCover(isPresented: $vm.mostrandoPaywall) {
            PaywallView(store: vm.store,
                        aoComprar: { vm.compraConcluida() },
                        aoFechar: { vm.mostrandoPaywall = false })
        }
        // Configurações.
        .sheet(isPresented: $vm.mostrandoConfiguracoes) {
            SettingsView(config: config, store: vm.store, camera: camera,
                         aoAlterar: { vm.salvarConfig() },
                         aoFechar: { vm.mostrandoConfiguracoes = false })
        }
        // Alerta de permissão de fotos negada (fluxo de exceção, seção 9).
        .alert(L("photos_alert_title"), isPresented: $vm.mostrandoAlertaFotos) {
            Button(vm.fotosNegadaPermanentemente ? L("denied_open_settings") : L("photos_alert_retry")) {
                if vm.fotosNegadaPermanentemente { abrirAjustes() } else { vm.tentarSalvarPendente() }
            }
            Button(L("photos_alert_discard"), role: .destructive) { vm.descartarPendente() }
        } message: {
            Text(L("photos_alert_body"))
        }
    }

    // MARK: - Controles sobre o visor

    // Barra superior: atalho de configurações à esquerda, toggle de modo ao centro, lente à
    // direita. Fixada no topo — nunca é empurrada para fora por painel alto.
    private var barraSuperior: some View {
        HStack {
            Button { vm.mostrandoConfiguracoes = true } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 20)).foregroundStyle(.white).frame(width: 44, height: 44)
            }
            Spacer()
            ModeToggle(modo: $vm.modo, aoTrocar: { vm.trocarModo($0) })
            Spacer()
            if camera.lentesDisponiveis.count > 1 {
                LensButton(lente: camera.lenteAtual) { vm.trocarLente() }
            } else {
                Color.clear.frame(width: 44, height: 44) // 11.1: seletor oculto com 1 lente
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .background(
            // Leve gradiente para legibilidade da barra sobre o visor.
            LinearGradient(colors: [.black.opacity(0.5), .clear],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .top)
        )
    }

    // Controles da base: Modo Rua = carrossel de receitas; Modo Pro = painel de sliders (com
    // altura limitada e rolagem, para caber em telas pequenas como o 13 mini).
    @ViewBuilder
    private func controlesInferiores(geo: GeometryProxy) -> some View {
        if vm.modo == .rua {
            VStack(spacing: 0) {
                RecipeCarousel(
                    receitas: vm.receitas, ativa: vm.receitaAtiva, camera: camera,
                    aoSelecionar: { vm.selecionarReceita($0) }
                )
                .padding(.horizontal, 12)
                .onLongPressGesture { vm.mostrandoSeletor = true } // abre o seletor expandido
                // Indicador discreto de fotos grátis restantes (só antes da compra) — regra 11.4.
                if !config.compraDesbloqueada {
                    Text(L("gratis_restantes", vm.gratisRestantes))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.top, 10)
                }
                ShutterButton { vm.disparar() }
                    .padding(.top, config.compraDesbloqueada ? 18 : 8).padding(.bottom, 8)
            }
        } else {
            VStack(spacing: 6) {
                // Alça para recolher/expandir o painel (poder ver o visor limpo no Pro).
                Button { withAnimation(.easeInOut(duration: 0.2)) { proRecolhido.toggle() } } label: {
                    HStack(spacing: 6) {
                        Image(systemName: proRecolhido ? "slider.horizontal.3" : "chevron.down")
                            .font(.system(size: 13, weight: .semibold))
                        Text(proRecolhido ? L("pro_show_controls") : L("pro_hide_controls"))
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.vertical, 7).padding(.horizontal, 16)
                    .background(Capsule().fill(Color.black.opacity(0.55)))
                }

                // Painel limitado a ~62% da altura; com o spacing apertado costuma caber inteiro
                // (sem rolar), o que também evita o conflito scroll×slider. Rola só se não couber.
                if !proRecolhido {
                    ScrollView(.vertical, showsIndicators: true) {
                        ProControlsPanel(camera: camera, config: config,
                                         aoAlterarConfig: { vm.salvarConfig() })
                            .padding(.horizontal, 12)
                    }
                    .frame(maxHeight: geo.size.height * 0.62)
                    .scrollBounceBehavior(.basedOnSize)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                HStack {
                    // Receita ativa em miniatura + nome (design tela 04, canto inferior esquerdo).
                    HStack(spacing: 8) {
                        RecipeThumbnail(receita: vm.receitaAtiva, camera: camera, lado: 40, cantos: 8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Estilo.accent, lineWidth: 2))
                        Text(vm.receitaAtiva.nomeExibicao)
                            .font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                    }
                    .onTapGesture { vm.mostrandoSeletor = true }
                    Spacer()
                    ShutterButton { vm.disparar() }
                    Spacer()
                    Color.clear.frame(width: 80, height: 44) // simetria
                }
                .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 8)
            }
        }
    }

    private func abrirAjustes() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
