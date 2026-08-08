// PhotoLibrarySaver.swift
// Salva o JPEG capturado direto na Fototeca do sistema (spec seção 20 — sem galeria própria).
// A permissão de biblioteca de fotos é pedida SÓ no momento da primeira captura, não no
// onboarding (critério 8.5). Se negada, quem chama mantém o Data em memória e pode tentar de
// novo (fluxo de exceção da seção 9). Usa autorização "add only" — o app só adiciona, não lê.

import Photos

enum PhotoSaveResultado {
    case salvo
    case permissaoNegada   // negada agora ou permanentemente -> orientar Ajustes
    case falha
}

enum PhotoLibrarySaver {

    // Status atual de adição à Fototeca, sem disparar prompt.
    static func statusAtual() -> PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .addOnly)
    }

    // Garante permissão de adição e salva o JPEG. Pede o prompt do sistema se ainda não decidido.
    static func salvar(_ jpeg: Data) async -> PhotoSaveResultado {
        var status = statusAtual()
        if status == .notDetermined {
            status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        }
        guard status == .authorized || status == .limited else {
            return .permissaoNegada
        }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                let req = PHAssetCreationRequest.forAsset()
                req.addResource(with: .photo, data: jpeg, options: nil)
            }
            return .salvo
        } catch {
            return .falha
        }
    }
}
