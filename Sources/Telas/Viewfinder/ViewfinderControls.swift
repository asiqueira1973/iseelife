// ViewfinderControls.swift
// Controles pequenos e reutilizáveis sobre o visor: toggle de modo (Rua/Pro), ícone de troca
// de lente e botão de disparo (design telas 03/04). Ícones outline minimalistas, accent só nos
// estados ativos (spec seção 16). No Modo Rua há no máximo 4 elementos simultâneos (seção 16).

import SwiftUI

// Toggle segmentado Rua/Pro (design: pílula com o lado ativo em âmbar).
struct ModeToggle: View {
    @Binding var modo: ModoCaptura
    var aoTrocar: (ModoCaptura) -> Void

    var body: some View {
        HStack(spacing: 0) {
            segmento(.rua, titulo: L("mode_street"))
            segmento(.pro, titulo: L("mode_pro"))
        }
        .padding(3)
        .background(Capsule().fill(Color.black.opacity(0.55)))
        .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
    }

    private func segmento(_ valor: ModoCaptura, titulo: String) -> some View {
        let ativo = modo == valor
        return Text(titulo)
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(ativo ? Estilo.accent : Estilo.textoSecundario)
            .padding(.vertical, 8).padding(.horizontal, 22)
            .background(
                Capsule().fill(ativo ? Color.white.opacity(0.08) : .clear)
            )
            .contentShape(Capsule())
            .onTapGesture { if !ativo { aoTrocar(valor) } }
            .accessibilityAddTraits(ativo ? [.isSelected, .isButton] : .isButton)
    }
}

// Ícone de troca de lente com o rótulo de zoom (0.5×/1×). Oculto pela tela quando há só 1 lente.
struct LensButton: View {
    let lente: LenteCamera
    var aoTocar: () -> Void

    var body: some View {
        Button(action: aoTocar) {
            VStack(spacing: 2) {
                Image(systemName: "camera.rotate")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(.white)
                Text(LensDiscovery.rotuloZoom(lente))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 44, height: 44)
        }
    }
}

// Botão de disparo — círculo branco com anel (design telas 03/04). 44pt+ (acessibilidade 17).
struct ShutterButton: View {
    var aoDisparar: () -> Void

    var body: some View {
        Button(action: aoDisparar) {
            ZStack {
                Circle().stroke(Color.white, lineWidth: 4).frame(width: 78, height: 78)
                Circle().fill(Color.white).frame(width: 64, height: 64)
            }
        }
        .accessibilityLabel(Text("shutter"))
    }
}
