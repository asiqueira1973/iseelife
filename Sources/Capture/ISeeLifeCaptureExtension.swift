// ISeeLifeCaptureExtension.swift
// Extensão de captura da Tela de Bloqueio (framework LockedCameraCapture, iOS 18+).
//
// POR QUE ELA EXISTE: é a PRESENÇA de uma extensão `LockedCameraCapture` que faz o iOS oferecer
// o I See Life como opção de câmera na Central de Controle, na Tela de Bloqueio (botão inferior)
// e no Botão de Ação — a doc da Apple é explícita quanto a isso. Um Control comum (ver
// ShootControl) só abre o app pela galeria de Controls; NÃO habilita o slot de câmera.
//
// NÍVEL A (esta implementação): ao ser acionada na tela de bloqueio, a extensão pede ao sistema
// para ABRIR O APP (`session.openApplication`). Se o aparelho não estiver autenticado, o iOS pede
// Face ID (normalmente imperceptível) e então abre o I See Life direto no Modo Rua, pronto para
// disparar. Ela NÃO fotografa com o aparelho bloqueado — isso seria o Nível B (rodar o pipeline
// de câmera dentro da extensão e gravar em `session.sessionContentURL`), um épico à parte.
//
// Todo este target tem deployment target iOS 18, então não precisa de @available interno.

import LockedCameraCapture
import SwiftUI

@main
struct ISeeLifeCaptureExtension: LockedCameraCaptureExtension {
    var body: some LockedCameraCaptureExtensionScene {
        LockedCameraCaptureUIScene { session in
            AberturaBloqueioView(session: session)
        }
    }
}

// Tela mínima e "marca" mostrada por um instante na tela de bloqueio. Ao aparecer, já pede para
// abrir o app (single-tap: tocar no botão da câmera → abre o I See Life). O botão é um fallback
// visível caso a abertura automática não role (ex.: erro de lançamento).
private struct AberturaBloqueioView: View {
    let session: LockedCameraCaptureSession

    // Accent âmbar #FFB000 (mesmo do app / DesignSystem).
    private let accent = Color(red: 1.0, green: 0xB0 / 255.0, blue: 0.0)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "eye")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(accent)
                Text("I See Life")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Text("Abrindo o visor…")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        // Tocar em qualquer lugar reabre (fallback além do onAppear).
        .contentShape(Rectangle())
        .onTapGesture { abrirApp() }
        .onAppear { abrirApp() }
    }

    private func abrirApp() {
        Task {
            // Pede ao sistema para trazer o app principal ao primeiro plano. Se bloqueado, o iOS
            // solicita autenticação antes. O tipo NSUserActivityTypeLockedCameraCapture identifica
            // que a origem foi a captura da tela de bloqueio (o app pode rotear para o Modo Rua).
            let atividade = NSUserActivity(activityType: NSUserActivityTypeLockedCameraCapture)
            try? await session.openApplication(for: atividade)
        }
    }
}
