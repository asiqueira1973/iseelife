// OnboardingView.swift
// Onboarding em no máximo 2 telas (épico 8.6 / design telas 01-02): (1) boas-vindas com o
// nome e a proposta de valor; (2) pedido de permissão de câmera com justificativa antes do
// prompt do sistema (critério 8.5). Ao final marca `onboarding_concluido` para não reaparecer.

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var camera: CameraSession
    @Bindable var config: ConfiguracaoUsuario
    var aoConcluir: () -> Void

    @State private var pagina = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if pagina == 0 { boasVindas } else { permissaoCamera }
        }
        .animation(.easeInOut, value: pagina)
    }

    // Tela 01 — Boas-vindas.
    private var boasVindas: some View {
        VStack(spacing: 20) {
            Spacer()
            Image("AppLogo")
                .resizable().scaledToFit()
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            Text("I See Life")
                .font(.system(size: 40, weight: .bold)).foregroundStyle(.white)
            Text(L("onboarding_welcome_tagline"))
                .font(.system(size: 19)).foregroundStyle(Estilo.textoSecundario)
                .multilineTextAlignment(.center).padding(.horizontal, 40)
            Spacer()
            botaoPrincipal(L("onboarding_continue")) { pagina = 1 }
        }
        .padding(.bottom, 24)
    }

    // Tela 02 — Permissão de câmera.
    private var permissaoCamera: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            Image(systemName: "camera")
                .font(.system(size: 44, weight: .light)).foregroundStyle(.white)
            Text(L("onboarding_camera_title"))
                .font(.system(size: 34, weight: .bold)).foregroundStyle(.white)
            Text(L("onboarding_camera_body"))
                .font(.system(size: 19)).foregroundStyle(Estilo.textoSecundario)
            Spacer()
            VStack(spacing: 12) {
                botaoPrincipal(L("onboarding_camera_allow")) { Task { await pedirCamera() } }
                Text(L("onboarding_camera_note"))
                    .font(.system(size: 14)).foregroundStyle(Estilo.textoSecundario)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 28).padding(.bottom, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func pedirCamera() async {
        await camera.solicitarAcessoCamera()
        config.onboardingConcluido = true
        aoConcluir() // RootView decide entre visor e tela de permissão negada.
    }

    private func botaoPrincipal(_ titulo: String, aoTocar: @escaping () -> Void) -> some View {
        Button(action: aoTocar) {
            Text(titulo)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity).padding(.vertical, 18)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white))
        }
        .padding(.horizontal, 24)
    }
}
