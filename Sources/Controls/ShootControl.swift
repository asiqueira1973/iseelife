// ShootControl.swift
// Control do iOS (Central de Controle / Tela de Bloqueio) do I See Life — extensão WidgetKit,
// disponível a partir do iOS 18 (API ControlWidget). Toque no Control abre o app: como o app
// já abre no visor do Modo Rua por padrão (modo_padrao = rua, sem tela intermediária depois do
// onboarding), o atalho entrega o "pronto para disparar" do princípio 0.1 sem tocar em nenhuma
// lógica existente (captura, receitas, paywall, modelo de dados). Puramente aditivo.
//
// Toda esta extensão tem deployment target iOS 18, então não precisa de @available interno.

import AppIntents
import SwiftUI
import WidgetKit

// O Control em si: um botão que abre o app.
struct ShootControl: ControlWidget {
    // Identificador estável do Control.
    static let kind = "com.dablab.iseelife.control.shoot"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: AbrirISeeLifeIntent()) {
                // Ícone remete ao app (olho, como o ícone iseelifeicon.png).
                Label("I See Life", systemImage: "eye")
            }
            .tint(Color(red: 1.0, green: 0xB0 / 255.0, blue: 0.0)) // accent âmbar #FFB000
        }
        .displayName("I See Life")
        .description("Abre o I See Life pronto para disparar no Modo Rua.")
    }
}

// O AppIntent AbrirISeeLifeIntent está em Sources/Shared (compilado no app E na extensão).
