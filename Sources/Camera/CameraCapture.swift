// CameraCapture.swift
// Recepção de frames de preview e captura silenciosa (épicos 8.1 e 8.4 / regra 11.3).
//
// Preview: cada frame vira CIImage, é guardado cru (para a captura) e recebe a receita ativa
// via RecipePipeline. No Modo Rua respeita o preview P&B; no Modo Pro aplica zebra/peaking
// quando ligados. O resultado é entregue ao renderer Metal em tempo real (< 200ms — 17.1).
//
// Captura: usa o último frame cru em full-frame, aplica a MESMA receita e codifica JPEG —
// sem tocar som de obturador (obturador silencioso, critério 8.1). O app NÃO guarda cópia
// sem filtro (regra 11.3): só o JPEG final é produzido.

import AVFoundation
import CoreImage
import UIKit

extension CameraSession: AVCaptureVideoDataOutputSampleBufferDelegate {

    // Callback de frame de vídeo (roda na videoQueue).
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let raw = CIImage(cvPixelBuffer: pixelBuffer)

        // Guarda o frame cru (full-frame) para a captura silenciosa.
        frameLock.lock()
        ultimoFrameCru = raw
        frameLock.unlock()

        // Aplica a receita ativa (regra 11.2/11.3). No preview do Modo Rua, respeita o P&B.
        var imagem = pipeline.apply(receitaAtivaValores, to: raw, forceMonochrome: previewPB && !modoProAtivo)

        // Sobreposições de assistência só no Modo Pro e só com o toggle ligado (épico 8.2).
        if modoProAtivo {
            if zebraAtivada { imagem = ZebraPeakingFilters.applyZebra(to: imagem) }
            if peakingAtivado { imagem = ZebraPeakingFilters.applyPeaking(to: imagem) }
        }

        renderer?.enfileirar(imagem)
    }

    // Ponto único de captura (épico 8.1 / regra 11.3). Escolhe o caminho conforme o toggle
    // `obturador_silencioso`:
    //  - silencioso ON  -> frame-grab do vídeo (silencioso, porém sujeito a motion blur em
    //    pouca luz, pois usa o quadro do preview);
    //  - silencioso OFF -> AVCapturePhotoOutput (nítido, com estabilização e fotografia
    //    computacional da Apple; toca o som do obturador do sistema).
    // Em ambos, a MESMA receita ativa é aplicada antes de gerar o JPEG final.
    func capturarFotoJPEG(silencioso: Bool, completion: @escaping (Data?) -> Void) {
        if silencioso {
            capturarPorFrameGrab(completion: completion)
        } else {
            capturarPorPhotoOutput(completion: completion)
        }
    }

    // Captura silenciosa a partir do último frame cru do vídeo.
    private func capturarPorFrameGrab(completion: @escaping (Data?) -> Void) {
        videoQueue.async { [weak self] in
            guard let self else { completion(nil); return }
            self.frameLock.lock()
            let raw = self.ultimoFrameCru
            self.frameLock.unlock()

            let base: CIImage
            if let raw {
                base = raw
            } else {
                // No SIMULADOR não há câmera: usa um quadro neutro para o fluxo seguir (permite
                // testar/capturar o paywall). Em DEVICE real sempre há frame — se não houver,
                // não inventa imagem: aborta o disparo.
                #if targetEnvironment(simulator)
                base = CIImage(color: CIColor(red: 0.5, green: 0.5, blue: 0.5))
                    .cropped(to: CGRect(x: 0, y: 0, width: 1170, height: 2532))
                #else
                DispatchQueue.main.async { completion(nil) }
                return
                #endif
            }

            let filtrada = self.pipeline.apply(self.receitaAtivaValores, to: base)
            let data = self.codificarJPEG(filtrada)
            DispatchQueue.main.async { completion(data) }
        }
    }

    // Captura nítida via AVCapturePhotoOutput; a receita é aplicada no delegate.
    private func capturarPorPhotoOutput(completion: @escaping (Data?) -> Void) {
        let settings = AVCapturePhotoSettings()
        settings.photoQualityPrioritization = .quality
        let delegate = PhotoCaptureDelegate(pipeline: pipeline, receita: receitaAtivaValores,
                                            codificar: { [weak self] img in self?.codificarJPEG(img) }) { [weak self] data in
            self?.photoDelegate = nil
            DispatchQueue.main.async { completion(data) }
        }
        photoDelegate = delegate
        photoOutput.capturePhoto(with: settings, delegate: delegate)
    }

    // Codifica uma CIImage em JPEG sRGB (usado pelos dois caminhos).
    func codificarJPEG(_ imagem: CIImage) -> Data? {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        return ciContext.jpegRepresentation(
            of: imagem,
            colorSpace: colorSpace,
            options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 0.92]
        )
    }
}

// Delegate da captura real (AVCapturePhotoOutput). Aplica a receita ativa (regra 11.3) sobre a
// foto processada pela Apple e devolve o JPEG final.
final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let pipeline: RecipePipeline
    private let receita: RecipeValues
    private let codificar: (CIImage) -> Data?
    private let completion: (Data?) -> Void

    init(pipeline: RecipePipeline, receita: RecipeValues,
         codificar: @escaping (CIImage) -> Data?, completion: @escaping (Data?) -> Void) {
        self.pipeline = pipeline
        self.receita = receita
        self.codificar = codificar
        self.completion = completion
    }

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        // applyOrientationProperty baca a orientação EXIF na imagem (evita foto deitada).
        guard error == nil, let dados = photo.fileDataRepresentation(),
              let ci = CIImage(data: dados, options: [.applyOrientationProperty: true]) else {
            completion(nil); return
        }
        let filtrada = pipeline.apply(receita, to: ci)
        completion(codificar(filtrada))
    }
}
