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

    // MARK: - Distância focal no Modo Rua (enhancement pós-spec)
    // Enquadramento por CROP do sensor na lente WIDE, ao estilo telêmetro de foco fixo: o
    // fotógrafo escolhe 28 / 35 / 40 mm (equivalentes clássicos de rua). Convertido em
    // videoZoomFactor sobre a focal nativa da wide (~26mm equiv. na maioria dos iPhones, incl.
    // 13 mini). O crop vale para o preview E para a captura (WYSIWYG). Só no Modo Rua.
    static let focaisRuaMm = [28, 35, 40]
    private let baseFocalMm: Double = 26.0
    @Published var focalRuaMm: Int = 28

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

    // MARK: - Prioridade de obturador no Modo Rua (enhancement pós-spec)
    // Mantém a velocidade do obturador fixa (piso escolhido pelo usuário) e deixa o ISO
    // automático subir para compensar a luz — congela o movimento na rua. Ativo só no Rua.
    var ruaShutterAlvoSegundos: Double = 1.0 / 250.0
    var shutterPriorityAtivo = false
    private var aeTimer: DispatchSourceTimer?

    // MARK: - AVFoundation
    private let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    // Saída de foto REAL — usada na captura nítida (obturador silencioso OFF): estabilização
    // óptica + fotografia computacional da Apple, sem o motion blur do frame-grab em pouca luz.
    let photoOutput = AVCapturePhotoOutput()
    let videoQueue = DispatchQueue(label: "com.dablab.iseelife.video")
    var currentDevice: AVCaptureDevice?
    private var currentInput: AVCaptureDeviceInput?
    // Mantém o delegate de foto vivo durante a captura assíncrona.
    var photoDelegate: NSObject?

    // Rotação de captura/preview conforme a orientação FÍSICA do aparelho (iOS 17+). A UI segue
    // travada em retrato, mas a foto E o preview acompanham como o telefone é segurado
    // (retrato/paisagem) — via o sensor, sem depender da orientação da interface.
    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
    private var rotationObservation: NSKeyValueObservation?

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
        // O preset agora é definido dentro de configurarEntrada: .inputPriority + um formato de
        // ALTA resolução para o frame que a captura silenciosa congela (o .photo entregava ~1MP).
        configurarEntrada(lente: alvo)
        if session.canAddOutput(videoOutput) {
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
            session.addOutput(videoOutput)
        }
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.maxPhotoQualityPrioritization = .quality
        }
        session.commitConfiguration()
        // Só AGORA, com o photoOutput conectado, dá pra setar a resolução máxima da foto real.
        aplicarMaxPhotoDimensions()
        configurarRotationCoordinator()

        videoQueue.async { [weak self] in
            guard let self else { return }
            self.session.startRunning()
            let rodando = self.session.isRunning
            DispatchQueue.main.async { self.sessaoRodando = rodando }
            // No Modo Rua, liga a prioridade de obturador assim que a sessão está rodando.
            if rodando, !self.modoProAtivo { self.iniciarShutterPriority() }
        }
    }

    // Encerra a sessão (economia de bateria — spec seção 17: não fica ativa em segundo plano).
    func parar() {
        pararShutterPriority()
        rotationObservation?.invalidate()
        rotationObservation = nil
        rotationCoordinator = nil
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
        aplicarMaxPhotoDimensions()   // o formato pode ter mudado com a lente; reaplica
        configurarRotationCoordinator()   // recria o coordenador p/ o novo device
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
            // Sobe a resolução do frame de vídeo (que a captura silenciosa congela) ANTES de ler
            // ranges/zoom, pois trocar o activeFormat reseta esses valores. (maxPhotoDimensions é
            // aplicado SÓ depois do commit, quando o photoOutput já está conectado — senão crasha.)
            configurarFormatoAltaResolucao(disp.device)
            lerRangesDoDispositivo(disp.device)
            // Reaplica o crop de focal do Rua ao (re)configurar a lente: wide -> focal escolhida;
            // ultra-wide -> nativo (1.0). Assim trocar de lente mantém a focal coerente.
            aplicarZoomParaLenteAtual()
        }
    }

    // MARK: - Resolução de captura (conserto do "1MP")
    // A captura silenciosa congela o último frame de VÍDEO. Com sessionPreset = .photo esse frame
    // vem em ~1MP (resolução de preview) -> foto salva minúscula. Aqui trocamos para
    // .inputPriority + o MAIOR formato 4:3 a >=30fps, elevando o frame silencioso a vários MP.
    // O preview é reduzido à parte (downscaleParaPreview), então não fica pesado.

    // Escolhe e aplica o melhor formato de vídeo. Fallback: mantém .photo (comportamento anterior).
    private func configurarFormatoAltaResolucao(_ device: AVCaptureDevice) {
        guard let fmt = melhorFormatoDeVideo(device) else {
            session.sessionPreset = .photo
            return
        }
        session.sessionPreset = .inputPriority
        do {
            try device.lockForConfiguration()
            device.activeFormat = fmt
            device.unlockForConfiguration()
        } catch {
            session.sessionPreset = .photo
        }
    }

    // Maior formato 4:3 (enquadramento de foto) que sustenta >= 30fps (preview fluido). Sem 4:3,
    // usa o maior disponível. nil se não houver candidato utilizável.
    private func melhorFormatoDeVideo(_ device: AVCaptureDevice) -> AVCaptureDevice.Format? {
        func dims(_ f: AVCaptureDevice.Format) -> CMVideoDimensions {
            CMVideoFormatDescriptionGetDimensions(f.formatDescription)
        }
        func area(_ f: AVCaptureDevice.Format) -> Int { let d = dims(f); return Int(d.width) * Int(d.height) }
        let candidatos = device.formats.filter { f in
            f.videoSupportedFrameRateRanges.contains { $0.maxFrameRate >= 30 }
        }
        guard !candidatos.isEmpty else { return nil }
        let quatroTres = candidatos.filter { f in
            let d = dims(f); return abs(Double(d.width) / Double(d.height) - 4.0 / 3.0) < 0.02
        }
        let pool = quatroTres.isEmpty ? candidatos : quatroTres
        return pool.max(by: { area($0) < area($1) })
    }

    // Foto real (AVCapturePhotoOutput, silencioso OFF) na resolução máxima do formato ativo (12MP).
    // Necessário com .inputPriority (o .photo maximizava sozinho).
    func aplicarMaxPhotoDimensions() {
        guard #available(iOS 16.0, *), let device = currentDevice else { return }
        // Só toca no photoOutput se ele JÁ estiver conectado à sessão (senão lança exceção/crash).
        guard session.outputs.contains(photoOutput) else { return }
        let dims = device.activeFormat.supportedMaxPhotoDimensions
        guard let maxDim = dims.max(by: { Int($0.width) * Int($0.height) < Int($1.width) * Int($1.height) })
        else { return }
        photoOutput.maxPhotoDimensions = maxDim
    }

    // MARK: - Zoom / distância focal (Rua)

    // Converte a focal do Rua em videoZoomFactor e aplica na lente ATUAL. Só a wide recebe o
    // crop; a ultra-wide fica no nativo (1.0). Roda na videoQueue (serializa com o loop de AE
    // que também trava a configuração do device).
    // O crop de focal só vale no Modo Rua e na lente WIDE. Fora disso (Pro, ou ultra-wide) o
    // enquadramento é o nativo da lente (1.0).
    func aplicarZoomParaLenteAtual() {
        let cropAtivo = (lenteAtual == .wide) && !modoProAtivo
        let mm = focalRuaMm
        videoQueue.async { [weak self] in
            guard let self, let device = self.currentDevice else { return }
            let alvo: CGFloat = cropAtivo ? CGFloat(Double(mm) / self.baseFocalMm) : 1.0
            let fator = min(max(alvo, 1.0), device.maxAvailableVideoZoomFactor)
            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = fator
                device.unlockForConfiguration()
            } catch { /* mantém o zoom anterior */ }
        }
    }

    // UI (Modo Rua): escolhe a focal. Garante a lente wide (a focal é um crop da wide) e aplica.
    func definirFocalRua(_ mm: Int) {
        focalRuaMm = mm
        if lenteAtual != .wide, lentesDisponiveis.contains(where: { $0.id == .wide }) {
            trocarLente(para: .wide)   // trocarLente -> configurarEntrada -> aplicarZoomParaLenteAtual
        } else {
            aplicarZoomParaLenteAtual()
        }
    }

    // Orientação de captura/preview seguindo a orientação FÍSICA do aparelho (iOS 17+). Usa o
    // AVCaptureDevice.RotationCoordinator, que lê o sensor e dá o ângulo "horizonte nivelado" —
    // sem precisar mapear à mão as direções de paisagem. Recriado a cada troca de lente.
    private func configurarRotationCoordinator() {
        guard #available(iOS 17.0, *), let device = currentDevice else { return }
        rotationObservation?.invalidate()
        let coord = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: nil)
        rotationCoordinator = coord
        // .initial já aplica o ângulo atual; depois acompanha a rotação do aparelho em tempo real
        // (preview e captura giram juntos), mesmo com a UI travada em retrato.
        rotationObservation = coord.observe(
            \.videoRotationAngleForHorizonLevelCapture, options: [.initial, .new]
        ) { [weak self] coordenador, _ in
            self?.aplicarAnguloRotacao(coordenador.videoRotationAngleForHorizonLevelCapture)
        }
    }

    // Aplica o ângulo às conexões do preview (videoOutput) e da captura real (photoOutput).
    private func aplicarAnguloRotacao(_ angulo: CGFloat) {
        guard #available(iOS 17.0, *) else { return }
        for conn in [videoOutput.connection(with: .video), photoOutput.connection(with: .video)] {
            guard let conn, conn.isVideoRotationAngleSupported(angulo) else { continue }
            conn.videoRotationAngle = angulo
        }
    }

    // MARK: - Frames de preview (delegate está na extensão abaixo)

    // Atualiza o snapshot da receita ativa (chamado da main quando o usuário troca de receita).
    func definirReceitaAtiva(_ receita: Receita) {
        receitaAtivaValores = RecipeValues(from: receita)
    }

    func definirPreviewPB(_ ativo: Bool) { previewPB = ativo }

    // Alterna Rua/Pro: no Pro, para a prioridade de obturador e volta ao auto contínuo (base
    // para os ajustes manuais); no Rua, (re)liga a prioridade de obturador.
    func definirModoPro(_ ativo: Bool) {
        modoProAtivo = ativo
        if ativo {
            pararShutterPriority()
            retomarAutoContinuo()
        } else {
            // Entrando no Rua: reseta foco/WB manuais do Pro pro automático (não deixa "grudar"),
            // e reestabelece a prioridade de obturador (exposição).
            resetarFocoWBContinuo()
            iniciarShutterPriority()
        }
        // Pro = quadro cheio; Rua = crop da focal escolhida. aplicarZoom respeita o modo atual.
        aplicarZoomParaLenteAtual()
    }

    // Define o piso de obturador do Rua (denominador: 250 => 1/250s) e reaplica se estiver no Rua.
    func definirObturadorMinimoRua(denominador: Int) {
        ruaShutterAlvoSegundos = 1.0 / Double(max(denominador, 1))
        if !modoProAtivo { iniciarShutterPriority() }
    }

    // MARK: - Loop de prioridade de obturador (Rua)

    // Liga o loop: fixa a duração do obturador e ajusta o ISO a ~8Hz para acompanhar a luz.
    func iniciarShutterPriority() {
        guard currentDevice != nil else { return }   // sessão ainda não configurada
        shutterPriorityAtivo = true
        aeTimer?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: videoQueue)
        timer.schedule(deadline: .now() + 0.2, repeating: 0.125)
        timer.setEventHandler { [weak self] in self?.ajustarISOParaObturadorFixo() }
        aeTimer = timer
        timer.resume()
    }

    func pararShutterPriority() {
        shutterPriorityAtivo = false
        aeTimer?.cancel()
        aeTimer = nil
    }

    // Um passo do loop: mantém a duração fixa e move o ISO em direção à exposição correta
    // (com amortecimento e banda morta para não tremular).
    private func ajustarISOParaObturadorFixo() {
        guard shutterPriorityAtivo, let device = currentDevice else { return }
        let offset = device.exposureTargetOffset            // EV; + = mais claro que o alvo
        guard abs(offset) > 0.08 else { return }             // banda morta
        let isoAtualDev = device.iso
        let alvoISO = isoAtualDev * pow(2, -offset)          // corrige a exposição via ISO
        let suavizado = isoAtualDev + (alvoISO - isoAtualDev) * 0.4   // amortecimento
        let fmt = device.activeFormat
        let clamped = min(max(suavizado, fmt.minISO), fmt.maxISO)
        let dur = CMTime(seconds: ruaShutterAlvoSegundos, preferredTimescale: 1_000_000)
        do {
            try device.lockForConfiguration()
            device.setExposureModeCustom(duration: dur, iso: clamped)
            device.unlockForConfiguration()
        } catch { /* mantém o último estado válido */ }
        DispatchQueue.main.async { self.isoAtual = clamped }
    }
}
