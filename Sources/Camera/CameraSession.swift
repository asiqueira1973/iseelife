// CameraSession.swift
// ViewModel de câmera (AVFoundation) — coração do visor. Gerencia a AVCaptureSession, a
// entrada de vídeo da lente ativa, a saída de frames para o preview filtrado, a captura
// silenciosa (épico 8.1) e os controles manuais do Modo Pro (épico 8.2).
//
// Preview ao vivo: cada frame de AVCaptureVideoDataOutput vira CIImage, recebe a receita
// ativa via RecipePipeline (regra 11.2/11.3) e — no Modo Pro — as sobreposições de zebra/
// peaking, sendo entregue ao renderer Metal. A MESMA receita é aplicada na captura final.
//
// Captura silenciosa: com obturador_silencioso (default true) o disparo usa o último frame
// de vídeo em full-frame, sem tocar o som de obturador do sistema (não há API pública para
// mutar o som do AVCapturePhotoOutput). Decisão registrada em DOCUMENTACAO-TECNICA.md.

import AVFoundation
import CoreImage
import UIKit

final class CameraSession: NSObject, ObservableObject {

    // Estado de permissão de câmera (épico 8.5).
    enum PermissaoCamera { case naoDeterminada, autorizada, negada }

    // MARK: - Estado publicado (lido pela UI)
    @Published var permissao: PermissaoCamera = .naoDeterminada
    @Published var lentesDisponiveis: [LenteDisponivel] = []
    @Published var lenteAtual: LenteCamera = .wide
    @Published var sessaoRodando = false

    // Valores atuais dos controles manuais (Modo Pro) — refletidos em texto ao lado do slider.
    @Published var isoAtual: Float = 100
    @Published var isoRange: ClosedRange<Float> = 50...3200
    @Published var duracaoObturadorAtual: Double = 1.0 / 250.0   // segundos
    @Published var duracaoObturadorRange: ClosedRange<Double> = (1.0/2000.0)...(1.0/30.0)
    @Published var exposicaoEV: Float = 0                        // bias de exposição
    @Published var exposicaoEVRange: ClosedRange<Float> = -3...3
    @Published var focoLensPosition: Float = 0.5                 // 0..1 (não calibrado em metros)
    @Published var wbTemperatura: Float = 5200                  // Kelvin (dial do sensor)
    @Published var wbTinta: Float = 0

    // MARK: - Toggles de assistência (Modo Pro)
    @Published var zebraAtivada = false
    @Published var peakingAtivado = false

    // MARK: - Preview / pipeline
    weak var renderer: CameraPreviewRenderer?
    let ciContext = CIContext(options: [.cacheIntermediates: false])
    lazy var pipeline = RecipePipeline(context: ciContext)

    // Receita ativa como snapshot queue-safe (regra 11.3). Atualizada da main.
    var receitaAtivaValores = RecipeValues(from: RecipeSeed.receitasPadrao()[0])
    // Preview P&B do Modo Rua (config preview_pb_ativado) — só afeta o preview.
    var previewPB = false
    // Aplica overlays de zebra/peaking só no Modo Pro.
    var modoProAtivo = false

    // MARK: - AVFoundation
    private let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    let videoQueue = DispatchQueue(label: "com.dablab.iseelife.video")
    var currentDevice: AVCaptureDevice?
    private var currentInput: AVCaptureDeviceInput?

    // Dispositivo ativo (usado pelos controles manuais em ManualCameraControls).
    var dispositivoAtivo: AVCaptureDevice? { currentDevice }

    // Último frame cru (pré-filtro), em full-frame, para a captura silenciosa (épico 8.1).
    var ultimoFrameCru: CIImage?
    let frameLock = NSLock()

    // MARK: - Permissão de câmera (épico 8.5)

    // Consulta o status atual sem disparar prompt.
    func atualizarStatusPermissao() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: permissao = .autorizada
        case .notDetermined: permissao = .naoDeterminada
        default: permissao = .negada
        }
    }

    // Pede acesso à câmera (chamado no onboarding — critério 8.5).
    func solicitarAcessoCamera() async {
        let concedido = await AVCaptureDevice.requestAccess(for: .video)
        await MainActor.run { self.permissao = concedido ? .autorizada : .negada }
    }

    // MARK: - Ciclo de vida da sessão

    // Configura e inicia a sessão na lente informada (ou na última usada / wide).
    func iniciar(lentePreferida: LenteCamera?) {
        guard permissao == .autorizada else { return }
        lentesDisponiveis = LensDiscovery.lentesDisponiveis()
        let alvo = lentePreferida ?? lentesDisponiveis.first(where: { $0.id == .wide })?.id
            ?? lentesDisponiveis.first?.id ?? .wide

        session.beginConfiguration()
        session.sessionPreset = .photo
        configurarEntrada(lente: alvo)
        if session.canAddOutput(videoOutput) {
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
            session.addOutput(videoOutput)
        }
        session.commitConfiguration()
        aplicarOrientacaoRetrato()

        videoQueue.async { [weak self] in
            self?.session.startRunning()
            let rodando = self?.session.isRunning ?? false
            DispatchQueue.main.async { self?.sessaoRodando = rodando }
        }
    }

    // Encerra a sessão (economia de bateria — spec seção 17: não fica ativa em segundo plano).
    func parar() {
        videoQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning { self.session.stopRunning() }
            DispatchQueue.main.async { self.sessaoRodando = false }
        }
    }

    // Troca de lente sem interromper a sessão perceptivelmente (critério 8.3, <300ms).
    func trocarLente(para lente: LenteCamera) {
        guard lente != lenteAtual, lentesDisponiveis.contains(where: { $0.id == lente }) else { return }
        session.beginConfiguration()
        if let currentInput { session.removeInput(currentInput) }
        configurarEntrada(lente: lente)
        session.commitConfiguration()
        aplicarOrientacaoRetrato()
    }

    private func configurarEntrada(lente: LenteCamera) {
        guard let disp = lentesDisponiveis.first(where: { $0.id == lente })
            ?? lentesDisponiveis.first else { return }
        guard let input = try? AVCaptureDeviceInput(device: disp.device) else { return }
        if session.canAddInput(input) {
            session.addInput(input)
            currentInput = input
            currentDevice = disp.device
            lenteAtual = disp.id
            lerRangesDoDispositivo(disp.device)
        }
    }

    // Orientação retrato (spec seção 17). iOS 17+: videoRotationAngle em graus.
    private func aplicarOrientacaoRetrato() {
        guard let conn = videoOutput.connection(with: .video) else { return }
        if #available(iOS 17.0, *), conn.isVideoRotationAngleSupported(90) {
            conn.videoRotationAngle = 90
        }
    }

    // MARK: - Frames de preview (delegate está na extensão abaixo)

    // Atualiza o snapshot da receita ativa (chamado da main quando o usuário troca de receita).
    func definirReceitaAtiva(_ receita: Receita) {
        receitaAtivaValores = RecipeValues(from: receita)
    }

    func definirPreviewPB(_ ativo: Bool) { previewPB = ativo }
    func definirModoPro(_ ativo: Bool) { modoProAtivo = ativo }
}
