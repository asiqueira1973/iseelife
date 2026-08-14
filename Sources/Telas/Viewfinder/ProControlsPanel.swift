// ProControlsPanel.swift
// Painel de controles manuais do Modo Pro (design tela 04 / épico 8.2). Reúne os toggles de
// assistência (Zebra, Peaking, Grid, Nível) e os sliders de ISO, obturador, exposição, foco e
// white balance (temperatura + tinta), cada um com o valor numérico ao lado. Arrastar reflete
// em tempo real via CameraSession (setters em ManualCameraControls).

import SwiftUI

struct ProControlsPanel: View {
    @ObservedObject var camera: CameraSession
    @Bindable var config: ConfiguracaoUsuario
    var aoAlterarConfig: () -> Void

    // Feature flag (v1.1): Zebra/Peaking escondidos até a zebra ser corrigida/calibrada (a
    // implementação estava clareando a tela toda no device e parecia bug). Código mantido.
    private let mostrarZebraPeaking = false

    // Faixas fixas de WB para o slider (o sensor aceita além, mas isto cobre o uso de rua).
    private let tempRange: ClosedRange<Float> = 2500...8000
    private let tintRange: ClosedRange<Float> = -100...100

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            togglesAssistencia
            sliderISO
            sliderObturador
            sliderExposicao
            sliderFoco
            sliderWBTemp
            sliderWBTint
        }
        .padding(.horizontal, 18).padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.black.opacity(0.80))
        )
    }

    // MARK: - Toggles

    private var togglesAssistencia: some View {
        HStack(spacing: 10) {
            if mostrarZebraPeaking {
                pill(L("pro_zebra"), ativo: camera.zebraAtivada) { camera.zebraAtivada.toggle() }
                pill(L("pro_peaking"), ativo: camera.peakingAtivado) { camera.peakingAtivado.toggle() }
            }
            pill(L("pro_grid"), ativo: config.gridAtivado) {
                config.gridAtivado.toggle(); aoAlterarConfig()
            }
            pill(L("pro_level"), ativo: config.nivelAtivado) {
                config.nivelAtivado.toggle(); aoAlterarConfig()
            }
            Spacer(minLength: 0)
            botaoAuto  // "Restaurar valores" -> volta pro automático (v1.1)
        }
    }

    // Botão que restaura os controles do Pro para o automático da câmera.
    private var botaoAuto: some View {
        Button { camera.restaurarAutomatico() } label: {
            HStack(spacing: 5) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 12, weight: .semibold))
                Text(L("pro_auto"))
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.vertical, 8).padding(.horizontal, 14)
            .background(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1.5))
        }
    }

    private func pill(_ titulo: String, ativo: Bool, aoTocar: @escaping () -> Void) -> some View {
        Button(action: aoTocar) {
            HStack(spacing: 6) {
                if ativo { Circle().fill(Estilo.accent).frame(width: 6, height: 6) }
                Text(titulo)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(ativo ? Estilo.accent : Estilo.textoSecundario)
            }
            .padding(.vertical, 8).padding(.horizontal, 14)
            .background(
                Capsule().stroke(ativo ? Estilo.accent : Color.white.opacity(0.25), lineWidth: 1.5)
            )
        }
    }

    // MARK: - Sliders

    private var sliderISO: some View {
        ProSlider(
            titulo: L("pro_iso"),
            valorTexto: "\(Int(camera.isoAtual))",
            progresso: norm(camera.isoAtual, camera.isoRange)
        ) { p in camera.definirISO(valor(p, camera.isoRange)) }
    }

    private var sliderObturador: some View {
        ProSlider(
            titulo: L("pro_shutter"),
            valorTexto: textoObturador(camera.duracaoObturadorAtual),
            progresso: normD(camera.duracaoObturadorAtual, camera.duracaoObturadorRange)
        ) { p in camera.definirObturador(valorD(p, camera.duracaoObturadorRange)) }
    }

    private var sliderExposicao: some View {
        ProSlider(
            titulo: L("pro_exposure"),
            valorTexto: "\(decimal(Double(camera.exposicaoEV), casas: 1, sinal: true)) EV",
            progresso: norm(camera.exposicaoEV, camera.exposicaoEVRange)
        ) { p in camera.definirExposicaoEV(valor(p, camera.exposicaoEVRange)) }
    }

    private var sliderFoco: some View {
        ProSlider(
            titulo: L("pro_focus"),
            valorTexto: decimal(Double(camera.focoLensPosition), casas: 2, sinal: false),
            progresso: Double(camera.focoLensPosition)
        ) { p in camera.definirFoco(Float(p)) }
    }

    private var sliderWBTemp: some View {
        ProSlider(
            titulo: L("pro_wb_temp"),
            valorTexto: "\(Int(camera.wbTemperatura))K",
            progresso: norm(camera.wbTemperatura, tempRange)
        ) { p in camera.definirWhiteBalance(temperatura: valor(p, tempRange), tinta: camera.wbTinta) }
    }

    private var sliderWBTint: some View {
        ProSlider(
            titulo: L("pro_wb_tint"),
            valorTexto: "\(Int(camera.wbTinta) >= 0 ? "+" : "")\(Int(camera.wbTinta))",
            progresso: norm(camera.wbTinta, tintRange)
        ) { p in camera.definirWhiteBalance(temperatura: camera.wbTemperatura, tinta: valor(p, tintRange)) }
    }

    // MARK: - Helpers de conversão/formatação

    private func norm(_ v: Float, _ r: ClosedRange<Float>) -> Double {
        guard r.upperBound > r.lowerBound else { return 0 }
        return Double((v - r.lowerBound) / (r.upperBound - r.lowerBound))
    }
    private func valor(_ p: Double, _ r: ClosedRange<Float>) -> Float {
        r.lowerBound + Float(p) * (r.upperBound - r.lowerBound)
    }
    private func normD(_ v: Double, _ r: ClosedRange<Double>) -> Double {
        guard r.upperBound > r.lowerBound else { return 0 }
        return (v - r.lowerBound) / (r.upperBound - r.lowerBound)
    }
    private func valorD(_ p: Double, _ r: ClosedRange<Double>) -> Double {
        r.lowerBound + p * (r.upperBound - r.lowerBound)
    }

    // "1/250s" para frações; "0,5s" para longas.
    private func textoObturador(_ seg: Double) -> String {
        if seg <= 0 { return "—" }
        if seg < 1 { return "1/\(Int(round(1 / seg)))s" }
        return "\(decimal(seg, casas: 1, sinal: false))s"
    }

    // Formata decimal respeitando vírgula em pt (design tela 04 mostra "−0,3 EV" e "0,62").
    private func decimal(_ v: Double, casas: Int, sinal: Bool) -> String {
        let base = String(format: "%\(sinal ? "+" : "").\(casas)f", v)
        return LocalizationManager.shared.idioma == .pt ? base.replacingOccurrences(of: ".", with: ",") : base
    }
}
