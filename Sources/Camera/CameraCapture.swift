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

    // Captura silenciosa: aplica a receita ao último frame cru e devolve o JPEG (épico 8.1).
    // Não aplica o P&B de preview — só a receita persiste no arquivo (regra 11.3).
    func capturarFotoJPEG(completion: @escaping (Data?) -> Void) {
        videoQueue.async { [weak self] in
            guard let self else { completion(nil); return }
            self.frameLock.lock()
            let raw = self.ultimoFrameCru
            self.frameLock.unlock()
            guard let raw else { DispatchQueue.main.async { completion(nil) }; return }

            let filtrada = self.pipeline.apply(self.receitaAtivaValores, to: raw)
            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
            let data = self.ciContext.jpegRepresentation(
                of: filtrada,
                colorSpace: colorSpace,
                options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 0.92]
            )
            DispatchQueue.main.async { completion(data) }
        }
    }
}
