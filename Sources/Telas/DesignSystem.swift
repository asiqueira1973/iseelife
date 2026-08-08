// DesignSystem.swift
// Constantes visuais compartilhadas (spec seção 16). Accent âmbar #FFB000 usado só para foco
// travado, receita ativa e toggles ligados — nunca decorativo (princípio de design). Fundo do
// visor sempre preto (princípio 0.4). Swatches de fallback das receitas para quando ainda não
// há frame de câmera (ex.: simulador), casando com a cor dos tiles do design (telas 03/05).

import SwiftUI

enum Estilo {
    // Accent oficial amostrado do design (#FFB000).
    static let accent = Color(red: 1.0, green: 0xB0 / 255.0, blue: 0.0)
    static let fundoVisor = Color.black
    // Painel translúcido escuro dos controles (Modo Pro, seletor de receita).
    static let painel = Color(white: 0.10)
    static let textoSecundario = Color(white: 0.62)

    // Cor de fallback de cada receita (usada só sem frame ao vivo). Aproxima o tile do design.
    static func swatch(_ receita: Receita) -> Color {
        if receita.monocromatico { return Color(white: 0.32) } // Mono -> cinza neutro
        switch receita.nomeExibicao {
        case "Neutra":   return Color(white: 0.55) // raw -> cinza neutro claro
        case "Classic":  return Color(red: 0.30, green: 0.22, blue: 0.13) // âmbar quente
        case "Soft":     return Color(red: 0.20, green: 0.24, blue: 0.30) // azul frio
        case "Positivo": return Color(red: 0.18, green: 0.26, blue: 0.21) // verde dessaturado
        default:         return Color(white: 0.25)
        }
    }
}
