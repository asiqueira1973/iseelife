// ProSlider.swift
// Slider em formato de régua do Modo Pro (design tela 04). Mostra o rótulo à esquerda, o valor
// numérico à direita e uma régua de ticks com o indicador âmbar na posição atual. Arrastar
// atualiza o valor em tempo real (critério 8.2 — reflete no preview sem travar a interface).

import SwiftUI

struct ProSlider: View {
    let titulo: String
    let valorTexto: String
    /// Posição atual normalizada 0...1.
    let progresso: Double
    /// Chamado durante o arraste com a nova posição normalizada.
    var aoArrastar: (Double) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(titulo)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Estilo.textoSecundario)
                    .tracking(0.5)
                Spacer()
                Text(valorTexto)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
            regua
        }
    }

    private var regua: some View {
        GeometryReader { geo in
            let largura = geo.size.width
            let x = CGFloat(min(max(progresso, 0), 1)) * largura
            ZStack(alignment: .leading) {
                // Ticks de referência.
                HStack(spacing: 0) {
                    ForEach(0..<40, id: \.self) { i in
                        Rectangle()
                            .fill(Color.white.opacity(i % 5 == 0 ? 0.5 : 0.22))
                            .frame(width: 1, height: i % 5 == 0 ? 16 : 9)
                        if i < 39 { Spacer(minLength: 0) }
                    }
                }
                .frame(height: 20, alignment: .center)
                // Indicador âmbar na posição atual.
                Rectangle()
                    .fill(Estilo.accent)
                    .frame(width: 2.5, height: 24)
                    .position(x: x, y: 10)
            }
            .frame(height: 24)
            .contentShape(Rectangle())
            .gesture(
                // minimumDistance > 0 e checagem de dominância horizontal: arrasto vertical passa
                // pro ScrollView (não mexe no valor). Resolve o conflito scroll×slider (v1.1).
                DragGesture(minimumDistance: 6)
                    .onChanged { g in
                        guard abs(g.translation.width) >= abs(g.translation.height) else { return }
                        let novo = Double(min(max(g.location.x, 0), largura) / largura)
                        aoArrastar(novo)
                    }
            )
        }
        .frame(height: 24)
    }
}
