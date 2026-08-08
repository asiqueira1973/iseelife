// RecipeThumbnail.swift
// Miniatura de preview AO VIVO de uma receita (critério 8.4). Atualiza em baixa cadência via
// TimelineView, aplicando a receita sobre o frame atual da câmera. Sem frame (simulador ou
// antes do primeiro frame), mostra o swatch de fallback da receita — a UI nunca fica vazia.

import SwiftUI

struct RecipeThumbnail: View {
    let receita: Receita
    let camera: CameraSession
    var lado: CGFloat = 64
    var cantos: CGFloat = 10

    var body: some View {
        // ~6 fps: claramente não-estático, mas barato (critério 8.4).
        TimelineView(.periodic(from: .now, by: 0.16)) { _ in
            imagemAtual
                .frame(width: lado, height: lado)
                .clipShape(RoundedRectangle(cornerRadius: cantos, style: .continuous))
        }
    }

    @ViewBuilder
    private var imagemAtual: some View {
        if let cg = camera.renderMiniatura(RecipeValues(from: receita),
                                           tamanho: CGSize(width: lado * 2, height: lado * 2)) {
            Image(decorative: cg, scale: 1.0)
                .resizable()
                .scaledToFill()
        } else {
            // Fallback: swatch da receita com um leve gradiente para não parecer chapado.
            LinearGradient(
                colors: [Estilo.swatch(receita).opacity(0.9), Estilo.swatch(receita)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }
}
