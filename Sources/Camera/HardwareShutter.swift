// HardwareShutter.swift
// Disparo pelos botões físicos de VOLUME (+ e –), como o app nativo de Câmera e o Moment.
// Usa a API oficial da Apple `AVCaptureEventInteraction` (AVKit, iOS 17.2+) — sem gambiarra de
// KVO de volume. Só fica ativa enquanto o app está em primeiro plano usando a câmera. Botão
// físico = sem o tremor do toque na tela (complementa a captura no touch-down).
//
// Puramente aditivo: chama o MESMO `disparar()` do ViewfinderViewModel, sem tocar em captura,
// pipeline, receitas ou paywall.

import SwiftUI
import AVKit

@available(iOS 17.2, *)
struct HardwareShutter: UIViewRepresentable {
    var aoDisparar: () -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        // primary = um botão de volume, secondary = o outro. Ambos disparam.
        let interaction = AVCaptureEventInteraction(
            primary: { event in context.coordinator.tratar(event) },
            secondary: { event in context.coordinator.tratar(event) }
        )
        interaction.isEnabled = true
        view.addInteraction(interaction)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.aoDisparar = aoDisparar
    }

    func makeCoordinator() -> Coordinator { Coordinator(aoDisparar: aoDisparar) }

    final class Coordinator {
        var aoDisparar: () -> Void
        init(aoDisparar: @escaping () -> Void) { self.aoDisparar = aoDisparar }

        // Dispara ao concluir o clique do botão (.ended) — um disparo por pressionada.
        func tratar(_ event: AVCaptureEvent) {
            if event.phase == .ended {
                DispatchQueue.main.async { self.aoDisparar() }
            }
        }
    }
}
