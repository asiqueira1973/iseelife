// RecipeCarousel.swift
// Carrossel horizontal de receitas na base do Modo Rua (design tela 03 / critério 8.4).
// Cada item é uma miniatura de preview ao vivo; a receita ativa ganha borda e rótulo âmbar
// (accent só no estado ativo — spec seção 16). É um dos 4 elementos de UI do Modo Rua.

import SwiftUI

struct RecipeCarousel: View {
    let receitas: [Receita]
    let ativa: Receita
    let camera: CameraSession
    var aoSelecionar: (Receita) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(receitas) { receita in
                    let ativoBool = receita.id == ativa.id
                    VStack(spacing: 6) {
                        RecipeThumbnail(receita: receita, camera: camera, lado: 64)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(ativoBool ? Estilo.accent : .clear, lineWidth: 2.5)
                            )
                        Text(receita.nomeExibicao)
                            .font(.system(size: 13, weight: ativoBool ? .bold : .regular))
                            .foregroundStyle(ativoBool ? Estilo.accent : Estilo.textoSecundario)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { aoSelecionar(receita) }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black.opacity(0.45))
        )
    }
}
