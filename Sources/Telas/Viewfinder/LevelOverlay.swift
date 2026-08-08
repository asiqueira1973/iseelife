// LevelOverlay.swift
// Indicador de nível/giroscópio sobreposto ao visor (spec seção 3 / config nivel_ativado).
// Mostra uma referência horizontal central; o segmento do meio inclina conforme o roll do
// aparelho e fica ÂMBAR quando fora do nível, branco quando nivelado (design tela 03b).
// Sobreposição discreta — não conta como um dos 4 elementos de UI do Modo Rua (seção 16).

import SwiftUI
import CoreMotion

// Fonte de movimento — lê o roll do aparelho via CoreMotion.
final class MotionLevel: ObservableObject {
    private let manager = CMMotionManager()
    @Published var rollGraus: Double = 0

    func iniciar() {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let motion else { return }
            // roll em torno do eixo vertical do aparelho em retrato.
            self?.rollGraus = motion.attitude.roll * 180 / .pi
        }
    }

    func parar() { manager.stopDeviceMotionUpdates() }
}

struct LevelOverlay: View {
    @StateObject private var motion = MotionLevel()

    // Tolerância para considerar "nivelado" (±1.5°).
    private var nivelado: Bool { abs(motion.rollGraus) < 1.5 }

    var body: some View {
        GeometryReader { geo in
            let cx = geo.size.width / 2
            let cy = geo.size.height / 2
            ZStack {
                // Ticks laterais fixos (referência).
                Rectangle().frame(width: 46, height: 1.5)
                    .foregroundStyle(Color.white.opacity(0.6))
                    .position(x: cx - 70, y: cy)
                Rectangle().frame(width: 46, height: 1.5)
                    .foregroundStyle(Color.white.opacity(0.6))
                    .position(x: cx + 70, y: cy)
                // Segmento central que inclina com o roll.
                Rectangle().frame(width: 70, height: 1.5)
                    .foregroundStyle(nivelado ? Color.white : Estilo.accent)
                    .rotationEffect(.degrees(-motion.rollGraus))
                    .position(x: cx, y: cy)
            }
        }
        .allowsHitTesting(false)
        .onAppear { motion.iniciar() }
        .onDisappear { motion.parar() }
    }
}
