// ZebraPeakingFilters.swift
// Sobreposições de assistência do Modo Pro (épico 8.2): zebra stripes e focus peaking.
// São aplicadas SOMENTE no preview ao vivo (não entram no JPEG salvo) e SOMENTE quando os
// respectivos toggles estão ligados. Rodam depois da receita na cadeia do preview.

import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

struct ZebraPeakingFilters {

    // Zebra stripes — marca em padrão diagonal qualquer área com luminância acima de 95%
    // (critério 8.2). Útil para identificar estouro de altas luzes.
    static func applyZebra(to image: CIImage) -> CIImage {
        // Máscara binária em UM passo: mask = clamp( luma*20 - 19 ) -> ~0 abaixo de 0,95, ~1
        // perto de 1,0. (A versão antiga usava colorClamp que colapsava o frame inteiro em 0,95,
        // clareando a tela toda — bug corrigido na v1.1.)
        let f = CIFilter.colorMatrix()
        f.inputImage = image
        let k: CGFloat = 20
        let v = CIVector(x: 0.2126 * k, y: 0.7152 * k, z: 0.0722 * k, w: 0)
        f.rVector = v; f.gVector = v; f.bVector = v
        f.aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
        f.biasVector = CIVector(x: -0.95 * k, y: -0.95 * k, z: -0.95 * k, w: 0)
        guard let masked = f.outputImage else { return image }
        let clamp = CIFilter.colorClamp()
        clamp.inputImage = masked
        clamp.minComponents = CIVector(x: 0, y: 0, z: 0, w: 0)
        clamp.maxComponents = CIVector(x: 1, y: 1, z: 1, w: 1)
        let finalMask = (clamp.outputImage ?? masked).cropped(to: image.extent)

        // Padrão de listras diagonais (45°).
        let stripes = CIFilter.stripesGenerator()
        stripes.color0 = CIColor(red: 0, green: 0, blue: 0, alpha: 0.55)
        stripes.color1 = CIColor(red: 1, green: 1, blue: 1, alpha: 0.0)
        stripes.width = 6
        stripes.center = CGPoint(x: 0, y: 0)
        let diagonal = (stripes.outputImage ?? image)
            .transformed(by: CGAffineTransform(rotationAngle: .pi / 4))
            .cropped(to: image.extent)

        // Mostra as listras só onde a máscara é branca (áreas estouradas).
        let blend = CIFilter.blendWithMask()
        blend.inputImage = diagonal
        blend.backgroundImage = image
        blend.maskImage = finalMask
        return blend.outputImage ?? image
    }

    // Focus peaking — contorna em amarelo as bordas com maior contraste de foco (critério 8.2).
    static func applyPeaking(to image: CIImage) -> CIImage {
        // Detecção de bordas (Sobel).
        let edges = CIFilter.edges()
        edges.inputImage = image
        edges.intensity = 8
        guard let edged = edges.outputImage else { return image }

        // Realça e binariza as bordas fortes.
        let contrast = CIFilter.colorControls()
        contrast.inputImage = edged
        contrast.contrast = 6
        contrast.brightness = -0.2
        let strong = (contrast.outputImage ?? edged).cropped(to: image.extent)

        // Tinge de amarelo (accent de foco) e sobrepõe à imagem.
        let yellow = CIFilter.colorMatrix()
        yellow.inputImage = strong
        yellow.rVector = CIVector(x: 1, y: 1, z: 1, w: 0)  // R = intensidade da borda
        yellow.gVector = CIVector(x: 0.69, y: 0.69, z: 0.69, w: 0) // G ~ 0xB0 (accent)
        yellow.bVector = CIVector(x: 0, y: 0, z: 0, w: 0)  // sem azul -> amarelo/âmbar
        yellow.aVector = CIVector(x: 0.7, y: 0.7, z: 0.7, w: 0) // alpha proporcional à borda
        let overlay = (yellow.outputImage ?? strong).cropped(to: image.extent)

        let comp = CIFilter.sourceOverCompositing()
        comp.inputImage = overlay
        comp.backgroundImage = image
        return comp.outputImage ?? image
    }
}
