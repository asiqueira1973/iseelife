// LocalizationManager.swift
// Localização com troca de idioma EM TEMPO REAL (épico 8.8 — "trocar o idioma reflete
// imediatamente em toda a interface, sem precisar reabrir o app"). O iOS nativo só troca
// idioma ao relançar; por isso carregamos manualmente o bundle .lproj correto em runtime e
// republicamos via @Published para forçar o redraw das views.
//
// A fonte do idioma é `configuracao_usuario.idioma_preferido` (seção 7): a tela de
// Configurações atualiza o model e chama `aplicar(_:)`; o app injeta o idioma salvo no início.

import SwiftUI

final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    // Idioma corrente da interface. Trocar republica e re-renderiza tudo que observa.
    @Published private(set) var idioma: Idioma = .pt

    private var bundleAtual: Bundle = .main

    private init() { recarregarBundle() }

    // Aplica um novo idioma (chamado pela tela de Configurações — critério 8.8).
    func aplicar(_ novo: Idioma) {
        guard novo != idioma else { return }
        idioma = novo
        recarregarBundle()
    }

    // Traduz uma chave usando o bundle do idioma atual.
    func str(_ chave: String) -> String {
        bundleAtual.localizedString(forKey: chave, value: chave, table: nil)
    }

    // Versão com argumentos de formato (ex.: "versão %@"). Recebe o array já montado para
    // evitar splat ambíguo de variádico-para-variádico.
    func str(_ chave: String, arguments args: [CVarArg]) -> String {
        String(format: bundleAtual.localizedString(forKey: chave, value: chave, table: nil), arguments: args)
    }

    private func recarregarBundle() {
        // pt-BR é o idioma de desenvolvimento; en é o alternativo (ver Info.plist / .lproj).
        let codigo = idioma == .pt ? "pt-BR" : "en"
        if let path = Bundle.main.path(forResource: codigo, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            bundleAtual = bundle
        } else {
            bundleAtual = .main
        }
    }
}

// Açúcar sintático para uso nas views: `L("chave")`.
func L(_ chave: String) -> String { LocalizationManager.shared.str(chave) }
func L(_ chave: String, _ args: CVarArg...) -> String {
    LocalizationManager.shared.str(chave, arguments: args)
}
