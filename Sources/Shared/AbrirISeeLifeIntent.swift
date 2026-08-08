// AbrirISeeLifeIntent.swift
// AppIntent que abre o app I See Life (traz para o primeiro plano). Usado pelo Control da
// Central de Controle (ShootControl). Fica em Sources/Shared e é compilado nos DOIS targets
// (app principal + extensão de Control): para `openAppWhenRun` funcionar e para o Control ser
// registrado/listado corretamente na galeria de Controls, o intent precisa existir também no
// processo do app, não só na extensão.
//
// Sem lógica extra: o roteamento padrão do app já cai no visor do Modo Rua (princípio 0.1).

import AppIntents

struct AbrirISeeLifeIntent: AppIntent {
    static var title: LocalizedStringResource = "Abrir o I See Life"
    // Faz o toque no Control abrir o app.
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}
