// PaywallView.swift
// Paywall de compra única (telas 06/06b / épico 8.7 e regra 11.4). Aparece no primeiro toque
// em disparar sem compra. Mostra proposta, itens inclusos, preço (vindo do StoreKit) e botões
// de comprar e restaurar. Estados: normal, processando e erro (design tela 06b). Ao concluir a
// compra, chama `aoComprar` — o ViewfinderViewModel destrava e salva a foto pendente.

import SwiftUI

struct PaywallView: View {
    @ObservedObject var store: StoreManager
    var aoComprar: () -> Void
    var aoFechar: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            conteudo
            if store.estado == .processando { overlayProcessando }
        }
        .task { if store.produto == nil { await store.carregarProduto() } }
        .alert(L("paywall_error_title"), isPresented: bindingErro) {
            Button(L("paywall_retry")) { Task { await comprar() } }
            Button(L("paywall_not_now"), role: .cancel) { store.estado = .ocioso }
        } message: {
            Text(L("paywall_error_body"))
        }
    }

    private var conteudo: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                Button(action: aoFechar) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold)).foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Color.white.opacity(0.15)))
                }
            }
            .padding(.horizontal, 20).padding(.top, 12)

            Text(L("paywall_title"))
                .font(.system(size: 40, weight: .bold)).foregroundStyle(.white)
                .padding(.top, 24)
            Text(L("paywall_subtitle"))
                .font(.system(size: 19)).foregroundStyle(Estilo.textoSecundario)
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 18) {
                item(L("paywall_feature_1"))
                item(L("paywall_feature_2"))
                item(L("paywall_feature_3"))
                item(L("paywall_feature_4"))
            }
            .padding(.top, 32)

            Spacer()

            VStack(spacing: 4) {
                Text(store.precoFormatado.isEmpty ? "—" : store.precoFormatado)
                    .font(.system(size: 34, weight: .bold)).foregroundStyle(.white)
                Text(L("paywall_one_time"))
                    .font(.system(size: 15)).foregroundStyle(Estilo.textoSecundario)
            }
            .frame(maxWidth: .infinity)

            Button { Task { await comprar() } } label: {
                Text(L("paywall_buy"))
                    .font(.system(size: 18, weight: .semibold)).foregroundStyle(.black)
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white))
            }
            .disabled(store.produto == nil || store.estado == .processando)
            .padding(.top, 16)

            Button { Task { await restaurar() } } label: {
                Text(L("paywall_restore"))
                    .font(.system(size: 16)).foregroundStyle(Estilo.textoSecundario)
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
            }
        }
        .padding(.horizontal, 24).padding(.bottom, 24)
    }

    private func item(_ texto: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "checkmark").foregroundStyle(Estilo.accent)
                .font(.system(size: 18, weight: .semibold))
            Text(texto).font(.system(size: 18)).foregroundStyle(.white)
            Spacer(minLength: 0)
        }
    }

    // Estado A — processando (design tela 06b).
    private var overlayProcessando: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView().tint(Estilo.accent).scaleEffect(1.4)
                Text(L("paywall_processing_title"))
                    .font(.system(size: 20, weight: .semibold)).foregroundStyle(.white)
                Text(L("paywall_processing_note"))
                    .font(.system(size: 15)).foregroundStyle(Estilo.textoSecundario)
            }
            .padding(32)
            .background(RoundedRectangle(cornerRadius: 20).fill(Estilo.painel))
        }
    }

    private var bindingErro: Binding<Bool> {
        Binding(get: { store.estado == .erro }, set: { if !$0 { store.estado = .ocioso } })
    }

    private func comprar() async {
        if await store.comprar() { aoComprar() }
    }

    private func restaurar() async {
        if await store.restaurar() { aoComprar() }
    }
}
