// ISeeLifeApp.swift
// Ponto de entrada do app I See Life.
// Responsabilidades: montar o ModelContainer do SwiftData (entidades `configuracao_usuario`
// e `receita`), rodar o seed das 4 receitas na primeira execução (regra 11.2 / seção 7) e
// entregar o roteamento inicial (onboarding -> viewfinder) ao AppRouter.

import SwiftUI
import SwiftData

@main
struct ISeeLifeApp: App {
    // Container único do app. Local-first, sem CloudKit (spec seção 4).
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: ConfiguracaoUsuario.self, Receita.self)
        } catch {
            fatalError("Falha ao criar o ModelContainer do SwiftData: \(error)")
        }
        // Garante a config singleton e sincroniza o catálogo de receitas ANTES de qualquer view
        // (regra 11.2 / seção 7). Feito no init para que ajustes de receita sempre reflitam.
        let ctx = container.mainContext
        let configs = (try? ctx.fetch(FetchDescriptor<ConfiguracaoUsuario>())) ?? []
        if configs.isEmpty { ctx.insert(ConfiguracaoUsuario()) }
        RecipeSeed.sincronizarCatalogo(context: ctx)
        try? ctx.save()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                // Visor e telas sempre em tema escuro (princípio 0.4/16).
                .preferredColorScheme(.dark)
        }
        .modelContainer(container)
    }
}
