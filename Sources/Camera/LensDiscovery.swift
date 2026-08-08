// LensDiscovery.swift
// Descoberta de lentes disponíveis via AVCaptureDevice.DiscoverySession (regra 11.1).
// Mostra apenas as lentes fisicamente presentes NAQUELE aparelho, em tempo de execução.
// No MVP o app trabalha com wide e ultra-wide (sem telephoto — spec seção 3). Se o aparelho
// tiver só uma lente traseira, o seletor deve ficar OCULTO (tratado na UI). Fallback: se a
// DiscoverySession não retornar nada, usa a câmera traseira padrão do sistema (risco seção 23).

import AVFoundation

struct LenteDisponivel: Identifiable, Equatable {
    let id: LenteCamera
    let device: AVCaptureDevice
    static func == (lhs: LenteDisponivel, rhs: LenteDisponivel) -> Bool { lhs.id == rhs.id }
}

enum LensDiscovery {

    // Retorna as lentes traseiras presentes no aparelho, na ordem ultra-wide -> wide
    // (0.5x antes de 1x, como no app nativo). Regra 11.1.
    static func lentesDisponiveis() -> [LenteDisponivel] {
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInUltraWideCamera, .builtInWideAngleCamera],
            mediaType: .video,
            position: .back
        )

        var resultado: [LenteDisponivel] = []
        for device in discovery.devices {
            switch device.deviceType {
            case .builtInUltraWideCamera:
                resultado.append(LenteDisponivel(id: .ultra_wide, device: device))
            case .builtInWideAngleCamera:
                resultado.append(LenteDisponivel(id: .wide, device: device))
            default:
                break
            }
        }

        // Ordena: ultra_wide primeiro, depois wide.
        resultado.sort { lhs, _ in lhs.id == .ultra_wide }

        // Fallback (risco seção 23): nenhuma lente enumerada -> usa a traseira padrão como wide.
        if resultado.isEmpty, let padrao = AVCaptureDevice.default(for: .video) {
            resultado.append(LenteDisponivel(id: .wide, device: padrao))
        }
        return resultado
    }

    // Fator de zoom nominal exibido no ícone de lente (0.5× / 1×) — apenas rótulo de UI.
    static func rotuloZoom(_ lente: LenteCamera) -> String {
        switch lente {
        case .ultra_wide: return "0.5×"
        case .wide:       return "1×"
        }
    }
}
