// MetalCameraPreview.swift
// Preview do visor renderizado em Metal. Exibe os frames JÁ filtrados que a CameraSession
// entrega (regra 11.2/11.3) — é o que garante o preview ao vivo da receita, do P&B e das
// sobreposições de zebra/peaking. Fundo sempre preto (princípio 0.4/16).
//
// CameraPreviewRenderer é um MTKView que recebe CIImage via `enfileirar(_:)` e desenha em
// aspect-fill. MetalCameraPreview é o wrapper SwiftUI que conecta o renderer à sessão.

import MetalKit
import CoreImage
import SwiftUI

// Renderer Metal — recebe CIImage e desenha na drawable.
final class CameraPreviewRenderer: MTKView, MTKViewDelegate {

    private var ciContext: CIContext?
    private var commandQueue: MTLCommandQueue?
    private var imagemAtual: CIImage?

    init() {
        let dispositivo = MTLCreateSystemDefaultDevice()
        super.init(frame: .zero, device: dispositivo)
        self.delegate = self
        self.framebufferOnly = false
        self.isPaused = true
        self.enableSetNeedsDisplay = true
        self.backgroundColor = .black
        self.isOpaque = true
        if let dispositivo {
            self.commandQueue = dispositivo.makeCommandQueue()
            self.ciContext = CIContext(mtlDevice: dispositivo, options: [.cacheIntermediates: false])
        }
    }

    required init(coder: NSCoder) { fatalError("init(coder:) não suportado") }

    // Recebe um frame filtrado (chamado da videoQueue) e agenda o redraw na main.
    func enfileirar(_ imagem: CIImage) {
        DispatchQueue.main.async { [weak self] in
            self?.imagemAtual = imagem
            self?.setNeedsDisplay()
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let ciContext,
              let commandQueue,
              let drawable = currentDrawable,
              let imagem = imagemAtual,
              let buffer = commandQueue.makeCommandBuffer() else { return }

        let destino = CGRect(origin: .zero, size: drawableSize)
        // Aspect-fill: escala a imagem para cobrir toda a drawable, centralizada.
        let escala = max(destino.width / imagem.extent.width, destino.height / imagem.extent.height)
        let larguraEscalada = imagem.extent.width * escala
        let alturaEscalada = imagem.extent.height * escala
        let dx = (destino.width - larguraEscalada) / 2
        let dy = (destino.height - alturaEscalada) / 2
        let ajustada = imagem
            .transformed(by: CGAffineTransform(scaleX: escala, y: escala))
            .transformed(by: CGAffineTransform(translationX: dx, y: dy))

        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        ciContext.render(ajustada,
                         to: drawable.texture,
                         commandBuffer: buffer,
                         bounds: destino,
                         colorSpace: colorSpace)
        buffer.present(drawable)
        buffer.commit()
    }
}

// Wrapper SwiftUI que injeta o renderer na CameraSession.
struct MetalCameraPreview: UIViewRepresentable {
    let session: CameraSession

    func makeUIView(context: Context) -> CameraPreviewRenderer {
        let renderer = CameraPreviewRenderer()
        session.renderer = renderer
        return renderer
    }

    func updateUIView(_ uiView: CameraPreviewRenderer, context: Context) {}
}
