// FocusLockIndicator.swift
// Indicador visual de foco/exposição travados no ponto tocado (critério 8.1 / design tela 03b).
// Um retângulo âmbar com marcas de cantos e o rótulo "AE/AF LOCK". Aparece no toque e some
// após ~1s (temporização controlada pelo ViewfinderViewModel).

import SwiftUI

struct FocusLockIndicator: View {
    let ponto: CGPoint

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .stroke(Estilo.accent, lineWidth: 1.5)
                .frame(width: 96, height: 120)
            // Ticks nos quatro lados.
            ForEach(0..<4, id: \.self) { i in
                Rectangle()
                    .fill(Estilo.accent)
                    .frame(width: i < 2 ? 1.5 : 12, height: i < 2 ? 12 : 1.5)
                    .offset(
                        x: i == 2 ? -48 : (i == 3 ? 48 : 0),
                        y: i == 0 ? -60 : (i == 1 ? 60 : 0)
                    )
            }
            Text(L("focus_lock"))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Estilo.accent)
                .offset(y: 78)
        }
        .position(ponto)
        .transition(.opacity)
        .allowsHitTesting(false)
    }
}
