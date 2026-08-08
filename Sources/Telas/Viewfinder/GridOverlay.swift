// GridOverlay.swift
// Grid de composição por terços sobreposto ao visor (critério 8.2 / config grid_ativado).
// Sobreposição discreta na própria imagem — não conta como um dos 4 elementos de UI do Modo
// Rua (spec seção 16). Linhas brancas finas de baixa opacidade para não competir com a cena.

import SwiftUI

struct GridOverlay: View {
    var body: some View {
        GeometryReader { geo in
            Path { p in
                let w = geo.size.width, h = geo.size.height
                // 2 linhas verticais
                for i in 1...2 {
                    let x = w * CGFloat(i) / 3
                    p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: h))
                }
                // 2 linhas horizontais
                for i in 1...2 {
                    let y = h * CGFloat(i) / 3
                    p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: w, y: y))
                }
            }
            .stroke(Color.white.opacity(0.22), lineWidth: 0.5)
        }
        .allowsHitTesting(false)
    }
}
