// ViewfinderViewModel.swift
// Orquestra o visor: modo (Rua/Pro), receita ativa, troca de lente, toque para travar foco
// (épico 8.1), disparo com gate de paywall (regra 11.4) e salvamento na Fototeca (épico 8.5).
// É a cola entre a CameraSession, o StoreManager e a `configuracao_usuario` (SwiftData).

import SwiftUI
import SwiftData
import UIKit

@MainActor
final class ViewfinderViewModel: ObservableObject {

    // Feedback tátil do disparo — unificado para o botão da tela E os botões de volume.
    private let haptico = UIImpactFeedbackGenerator(style: .heavy)

    let camera: CameraSession
    let store: StoreManager
    private let context: ModelContext
    let config: ConfiguracaoUsuario
    let receitas: [Receita]

    @Published var modo: ModoCaptura
    @Published var receitaAtiva: Receita
    @Published var mostrandoSeletor = false
    @Published var mostrandoConfiguracoes = false
    @Published var mostrandoPaywall = false
    @Published var capturando = false                 // flash breve de captura
    @Published var focoTravadoPontoView: CGPoint?     // ponto do indicador AE/AF LOCK
    @Published var fotoPendente: Data?                // foto em memória aguardando salvar
    @Published var mostrandoAlertaFotos = false       // permissão de fotos negada (seção 9)

    init(camera: CameraSession, store: StoreManager, context: ModelContext,
         config: ConfiguracaoUsuario, receitas: [Receita]) {
        self.camera = camera
        self.store = store
        self.context = context
        self.config = config
        self.receitas = receitas
        self.modo = config.modoPadrao

        // Receita ativa: a última salva, ou a de ordem 1 como padrão neutro (regra 11.3).
        let padrao = receitas.first(where: { $0.ordemExibicao == 1 }) ?? receitas.first!
        self.receitaAtiva = receitas.first(where: { $0.id == config.receitaAtivaID }) ?? padrao

        camera.definirReceitaAtiva(receitaAtiva)
        camera.definirPreviewPB(config.previewPbAtivado)
        camera.definirModoPro(modo == .pro)
        haptico.prepare()
    }

    // MARK: - Ciclo de vida

    // Inicia a sessão na última lente usada (épico 8.3) e sincroniza posse do produto.
    func aoAparecer() {
        camera.atualizarStatusPermissao()
        // Define o piso de obturador do Rua antes de iniciar (o loop liga quando a sessão sobe).
        camera.ruaShutterAlvoSegundos = 1.0 / Double(ruaObturadorDenominador)
        // Restaura a focal escolhida no Rua antes de iniciar (o crop é aplicado ao configurar a lente).
        camera.focalRuaMm = config.focalRuaMm
        camera.iniciar(lentePreferida: config.ultimaLenteUsada)
        camera.definirPreviewPB(config.previewPbAtivado)
        Task {
            await store.carregarProduto()
            if await store.atualizarEntitlement(), !config.compraDesbloqueada {
                // App reinstalado / comprado em outro aparelho: reflete a posse localmente.
                marcarCompra()
            }
        }
    }

    // Encerra a sessão ao sair (economia de bateria — spec seção 17).
    func aoDesaparecer() { camera.parar() }

    // MARK: - Modo, receita, lente

    // Troca Modo Rua <-> Pro (fluxo 2 / épico 8.2). Transição imediata, mesmo viewfinder.
    // definirModoPro já cuida de ligar/desligar a prioridade de obturador do Rua.
    func trocarModo(_ novo: ModoCaptura) {
        modo = novo
        camera.definirModoPro(novo == .pro)
    }

    // Denominador do obturador mínimo do Rua (250/500/1000), com fallback 250.
    var ruaObturadorDenominador: Int { config.ruaObturadorDenominador ?? 250 }

    // Aplica o piso de obturador do Rua na câmera (chamado no início e ao trocar nas Configurações).
    func aplicarObturadorMinimoRua() {
        camera.definirObturadorMinimoRua(denominador: ruaObturadorDenominador)
    }

    // Seleciona receita e persiste a escolha (critério 8.4).
    func selecionarReceita(_ receita: Receita) {
        receitaAtiva = receita
        camera.definirReceitaAtiva(receita)
        config.receitaAtivaID = receita.id
        salvarConfig()
        // No Rua, trocar de receita dá um "refresh": foco/WB voltam pro automático, para não
        // carregar ajustes manuais feitos no Pro (v1.1).
        if modo == .rua { camera.resetarFocoWBContinuo() }
    }

    // MARK: - Distância focal no Modo Rua (enhancement pós-spec)

    // Focais oferecidas (mm) e a atual (para o seletor do visor).
    var focaisRua: [Int] { CameraSession.focaisRuaMm }
    var focalAtual: Int { camera.focalRuaMm }

    // Escolhe a focal (28/35/40) e persiste. O crop é aplicado na lente wide (a CameraSession
    // garante a wide se estiver na ultra-wide).
    func selecionarFocal(_ mm: Int) {
        guard mm != camera.focalRuaMm else { return }
        camera.definirFocalRua(mm)
        config.focalRuaMm = mm
        salvarConfig()
    }

    // Alterna para a próxima lente disponível (épico 8.3). Lembra a última usada.
    func trocarLente() {
        let lentes = camera.lentesDisponiveis.map { $0.id }
        guard lentes.count > 1, let idx = lentes.firstIndex(of: camera.lenteAtual) else { return }
        let proxima = lentes[(idx + 1) % lentes.count]
        camera.trocarLente(para: proxima)
        config.ultimaLenteUsada = proxima
        salvarConfig()
    }

    // MARK: - Toque para travar foco/exposição (épico 8.1)

    // `pontoView` em pontos da view; `pontoNormalizado` 0..1 no espaço da câmera.
    func tocarPara(pontoNormalizado: CGPoint, pontoView: CGPoint) {
        camera.travarFocoExposicao(pontoNormalizado: pontoNormalizado)
        focoTravadoPontoView = pontoView
        // O indicador aparece e some após ~1s (critério 8.1).
        let ponto = pontoView
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            if self?.focoTravadoPontoView == ponto { self?.focoTravadoPontoView = nil }
        }
    }

    // Cota de fotos grátis antes do paywall (regra 11.4). Paridade com o Android.
    static let quotaGratis = 10

    // Fotos grátis restantes (para o indicador do visor).
    var gratisRestantes: Int { max(0, Self.quotaGratis - config.fotosGratisUsadas) }

    // MARK: - Disparo + gate de paywall (regra 11.4) + salvar (épico 8.5)

    // Captura o frame no instante do toque (preserva o momento), depois aplica o gate.
    func disparar() {
        // Feedback tátil firme (vale para o botão da tela e para os botões de volume).
        haptico.impactOccurred(intensity: 1.0)
        // Pisca o obturador por ~120ms, independente do tempo de salvar (feedback visível).
        capturando = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.capturando = false
        }
        camera.capturarFotoJPEG(silencioso: config.obturadorSilencioso) { [weak self] data in
            guard let self else { return }
            guard let data else { return }
            if self.config.compraDesbloqueada {
                self.salvarFoto(data)
            } else if self.config.fotosGratisUsadas < Self.quotaGratis {
                // Cota grátis (regra 11.4): salva de graça e consome uma. Assim o app é totalmente
                // usável sem compra e sem login (paridade com o Android).
                self.config.fotosGratisUsadas += 1
                self.salvarConfig()
                self.salvarFoto(data)
            } else {
                // Cota esgotada: guarda a foto e mostra o paywall.
                self.fotoPendente = data
                self.mostrandoPaywall = true
            }
        }
    }

    // Chamado quando a compra é confirmada no paywall (critério 8.7): destrava e salva a foto
    // que motivou o paywall, sem exigir novo toque no disparador.
    func compraConcluida() {
        marcarCompra()
        mostrandoPaywall = false
        if let foto = fotoPendente { salvarFoto(foto) }
    }

    // Salva o JPEG na Fototeca; trata permissão negada mantendo a foto em memória (seção 9).
    func salvarFoto(_ data: Data) {
        Task {
            let resultado = await PhotoLibrarySaver.salvar(data)
            switch resultado {
            case .salvo:
                fotoPendente = nil
            case .permissaoNegada, .falha:
                fotoPendente = data
                mostrandoAlertaFotos = true
            }
        }
    }

    // Tenta salvar de novo a foto pendente (botão do alerta — seção 9).
    func tentarSalvarPendente() {
        if let foto = fotoPendente { salvarFoto(foto) }
    }

    func descartarPendente() {
        fotoPendente = nil
        mostrandoAlertaFotos = false
    }

    // Status de fotos para decidir entre reabrir prompt ou mandar para Ajustes (seção 9).
    var fotosNegadaPermanentemente: Bool {
        let s = PhotoLibrarySaver.statusAtual()
        return s == .denied || s == .restricted
    }

    // MARK: - Persistência

    private func marcarCompra() {
        config.compraDesbloqueada = true
        if config.dataCompra == nil { config.dataCompra = Date() }
        salvarConfig()
    }

    func salvarConfig() { try? context.save() }
}
