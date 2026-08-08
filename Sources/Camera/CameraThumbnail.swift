// CameraThumbnail.swift
// Renderização de miniaturas de preview AO VIVO para o seletor de receitas (critério 8.4 —
// "thumbnail de preview ao vivo de cada uma, não estático"). Cada miniatura aplica uma
// receita diferente sobre o último frame cru da câmera, em tamanho reduzido. Atualizada em
// baixa cadência pela UI (TimelineView), o que é barato e claramente não-estático.

import CoreImage
import UIKit

extension CameraSession {

    // Gera um CGImage pequeno do frame atual com a receita aplicada (regra 11.2).
    // Retorna nil quando ainda não há frame (ex.: simulador) — a UI cai no swatch de fallback.
    func renderMiniatura(_ valores: RecipeValues, tamanho: CGSize) -> CGImage? {
        frameLock.lock()
        let raw = ultimoFrameCru
        frameLock.unlock()
        guard let raw else { return nil }

        // Reduz primeiro (aspect-fill) para baratear o pipeline.
        let escala = max(tamanho.width / raw.extent.width, tamanho.height / raw.extent.height)
        let pequena = raw.transformed(by: CGAffineTransform(scaleX: escala, y: escala))
        let filtrada = pipeline.apply(valores, to: pequena)

        // Recorte central no tamanho alvo.
        let ox = filtrada.extent.midX - tamanho.width / 2
        let oy = filtrada.extent.midY - tamanho.height / 2
        let rect = CGRect(x: ox, y: oy, width: tamanho.width, height: tamanho.height)
        return ciContext.createCGImage(filtrada, from: rect)
    }
}
