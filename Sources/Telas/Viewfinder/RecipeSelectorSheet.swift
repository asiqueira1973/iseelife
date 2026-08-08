// RecipeSelectorSheet.swift
// Seletor de receita expandido (tela 05 / critério 8.4). Grade 2×2 com as 4 receitas,
// miniatura de preview ao vivo, nome e a receita ativa destacada (borda + check âmbar).
// Apresentado como sheet sobre o visor. Lê `receita`; escreve a escolha via callback.

import SwiftUI

struct RecipeSelectorSheet: View {
    let receitas: [Receita]
    let ativa: Receita
    let camera: CameraSession
    var aoSelecionar: (Receita) -> Void
    var aoFechar: () -> Void

    private let colunas = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(L("recipes_title"))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Button(L("close"), action: aoFechar)
                    .font(.system(size: 17))
                    .foregroundStyle(Estilo.textoSecundario)
            }
            .padding(.horizontal, 20).padding(.top, 24).padding(.bottom, 18)

            LazyVGrid(columns: colunas, spacing: 16) {
                ForEach(receitas) { receita in
                    tile(receita)
                }
            }
            .padding(.horizontal, 20)

            Text(L("recipes_live_note"))
                .font(.system(size: 14))
                .foregroundStyle(Estilo.textoSecundario)
                .padding(20)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.black.ignoresSafeArea())
    }

    private func tile(_ receita: Receita) -> some View {
        let ativoBool = receita.id == ativa.id
        return VStack(alignment: .leading, spacing: 10) {
            RecipeThumbnail(receita: receita, camera: camera, lado: 160, cantos: 14)
                .frame(maxWidth: .infinity)
            HStack {
                Text(receita.nomeExibicao)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(ativoBool ? Estilo.accent : .white)
                Spacer()
                if ativoBool {
                    Image(systemName: "checkmark").foregroundStyle(Estilo.accent)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(ativoBool ? Estilo.accent : Color.white.opacity(0.12),
                        lineWidth: ativoBool ? 2.5 : 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { aoSelecionar(receita) }
    }
}
