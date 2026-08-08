// SettingsView.swift
// Configurações (tela 07 / épico 8.8). Troca de idioma (pt/en) com efeito imediato em toda a
// interface (via LocalizationManager), toggles de grid, nível, obturador silencioso e preview
// P&B, versão do app e link de restaurar compra. Lê/escreve `configuracao_usuario`.

import SwiftUI

struct SettingsView: View {
    @Bindable var config: ConfiguracaoUsuario
    @ObservedObject var store: StoreManager
    @ObservedObject var camera: CameraSession
    var aoAlterar: () -> Void

    @ObservedObject private var loc = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var restaurando = false

    var body: some View {
        NavigationStack {
            List {
                secaoIdioma
                secaoVisor
                secaoCaptura
                secaoCompra
                secaoRodape
            }
            .scrollContentBackground(.hidden)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle(L("settings_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L("close")) { dismiss() }.foregroundStyle(Estilo.accent)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    // IDIOMA — troca em tempo real (critério 8.8).
    private var secaoIdioma: some View {
        Section(L("settings_language")) {
            HStack(spacing: 10) {
                idiomaBotao(.pt, L("settings_lang_pt"))
                idiomaBotao(.en, L("settings_lang_en"))
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10))
        }
        .listRowBackground(Color.clear)
    }

    private func idiomaBotao(_ idioma: Idioma, _ titulo: String) -> some View {
        let ativo = config.idiomaPreferido == idioma
        return Button {
            config.idiomaPreferido = idioma
            loc.aplicar(idioma)      // reflete imediatamente em toda a interface
            aoAlterar()
        } label: {
            Text(titulo)
                .font(.system(size: 17, weight: ativo ? .bold : .regular))
                .foregroundStyle(ativo ? Estilo.accent : .white)
                .frame(maxWidth: .infinity).padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(ativo ? Estilo.accent : Color.white.opacity(0.15), lineWidth: ativo ? 2 : 1)
                        .background(RoundedRectangle(cornerRadius: 12).fill(ativo ? Estilo.accent.opacity(0.12) : .clear))
                )
        }
        .buttonStyle(.plain)
    }

    // VISOR — grid, nível, preview P&B.
    private var secaoVisor: some View {
        Section(L("settings_viewfinder")) {
            toggle(L("settings_grid"), isOn: $config.gridAtivado)
            toggle(L("settings_level"), isOn: $config.nivelAtivado)
            toggle(L("settings_bw_preview"), isOn: $config.previewPbAtivado) {
                camera.definirPreviewPB(config.previewPbAtivado)
            }
        }
        .listRowBackground(Estilo.painel)
    }

    // CAPTURA — obturador silencioso.
    private var secaoCaptura: some View {
        Section(L("settings_capture")) {
            toggle(L("settings_silent"), isOn: $config.obturadorSilencioso)
        }
        .listRowBackground(Estilo.painel)
    }

    // COMPRA — restaurar.
    private var secaoCompra: some View {
        Section(L("settings_purchase")) {
            Button {
                restaurando = true
                Task {
                    if await store.restaurar() {
                        config.compraDesbloqueada = true
                        if config.dataCompra == nil { config.dataCompra = Date() }
                        aoAlterar()
                    }
                    restaurando = false
                }
            } label: {
                HStack {
                    Text(L("settings_restore")).foregroundStyle(.white)
                    Spacer()
                    if restaurando { ProgressView().tint(Estilo.accent) }
                    else { Image(systemName: "chevron.right").foregroundStyle(Estilo.textoSecundario) }
                }
            }
        }
        .listRowBackground(Estilo.painel)
    }

    private var secaoRodape: some View {
        Section {
            Text("I See Life · \(L("settings_version", versaoApp))")
                .font(.system(size: 14)).foregroundStyle(Estilo.textoSecundario)
                .frame(maxWidth: .infinity)
        }
        .listRowBackground(Color.clear)
    }

    private func toggle(_ titulo: String, isOn: Binding<Bool>, aoMudar: (() -> Void)? = nil) -> some View {
        Toggle(isOn: Binding(get: { isOn.wrappedValue }, set: { novo in
            isOn.wrappedValue = novo
            aoAlterar()
            aoMudar?()
        })) {
            Text(titulo).foregroundStyle(.white)
        }
        .tint(Estilo.accent)
    }

    private var versaoApp: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}
