// RootView.swift
// Raiz da navegação (fluxo 1 / seção 9). Garante a linha única de `configuracao_usuario`,
// semeia as receitas (regra 11.2) e roteia:
//   onboarding não concluído            -> OnboardingView (épico 8.6)
//   concluído + câmera negada           -> PermissionDeniedView(.camera) (critério 8.5)
//   concluído + câmera autorizada       -> ViewfinderScreen (épico 8.1+)
// Cria e mantém a CameraSession e o StoreManager para toda a sessão.

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query private var configs: [ConfiguracaoUsuario]
    @Query(sort: \Receita.ordemExibicao) private var receitas: [Receita]

    @StateObject private var camera = CameraSession()
    @StateObject private var store = StoreManager()
    @StateObject private var loc = LocalizationManager.shared

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let config = configs.first, !receitas.isEmpty {
                conteudo(config: config)
            } else {
                // Enquanto semeia (primeiro frame).
                Color.black.ignoresSafeArea()
            }
        }
        .onAppear(perform: bootstrap)
        // Re-renderiza toda a árvore quando o idioma muda (critério 8.8).
        .environment(\.locale, loc.idioma == .pt ? Locale(identifier: "pt_BR") : Locale(identifier: "en"))
    }

    @ViewBuilder
    private func conteudo(config: ConfiguracaoUsuario) -> some View {
        if !config.onboardingConcluido {
            OnboardingView(camera: camera, config: config, aoConcluir: { camera.atualizarStatusPermissao() })
        } else if camera.permissao == .negada {
            PermissionDeniedView(tipo: .camera)
        } else {
            ViewfinderScreen(camera: camera, store: store, context: context,
                             config: config, receitas: receitas)
        }
    }

    // A config singleton e o catálogo de receitas já são garantidos no init do app.
    // Aqui só aplica o idioma salvo e atualiza o status de permissão da câmera.
    private func bootstrap() {
        if let config = configs.first {
            loc.aplicar(config.idiomaPreferido)
        }
        camera.atualizarStatusPermissao()
    }
}
