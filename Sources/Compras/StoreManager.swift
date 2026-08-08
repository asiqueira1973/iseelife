// StoreManager.swift
// Camada de compra via StoreKit 2 — produto ÚNICO não-consumível (spec seção 4 e regra 11.4).
// Sem assinatura. Valida a posse localmente (Transaction.currentEntitlements), então o app
// segue 100% offline depois da primeira confirmação (princípio 0.5 / regra 11.4).
//
// Este manager cuida só do StoreKit. Quem persiste o desbloqueio em
// `configuracao_usuario.compra_desbloqueada` / `data_compra` é o PurchaseGate (bridge com o
// SwiftData), a partir do resultado reportado aqui.

import StoreKit

@MainActor
final class StoreManager: ObservableObject {

    // ID do produto — casa com o ISeeLife.storekit e com o App Store Connect.
    static let produtoID = "iseelife_desbloqueio_completo"

    enum EstadoCompra: Equatable {
        case ocioso
        case processando
        case erro
    }

    @Published var produto: Product?
    @Published var estado: EstadoCompra = .ocioso
    // true quando o entitlement do produto está presente (posse confirmada localmente).
    @Published var possuiProduto = false

    // Preço formatado na moeda local (ex.: "R$ 49,90") — vem do StoreKit, não hardcoded.
    var precoFormatado: String { produto?.displayPrice ?? "" }

    private var tarefaUpdates: Task<Void, Never>?

    init() {
        // Ouve transações que chegam fora do fluxo de compra (ex.: compra interrompida).
        tarefaUpdates = Task { [weak self] in
            for await resultado in Transaction.updates {
                await self?.processarTransacaoVerificada(resultado)
            }
        }
    }

    deinit { tarefaUpdates?.cancel() }

    // Carrega o produto da loja (ou do .storekit local em sandbox).
    func carregarProduto() async {
        do {
            let produtos = try await Product.products(for: [Self.produtoID])
            produto = produtos.first
        } catch {
            produto = nil
        }
    }

    // Efetua a compra (critério 8.7). Retorna true se concluída e posse confirmada.
    @discardableResult
    func comprar() async -> Bool {
        guard let produto else { estado = .erro; return false }
        estado = .processando
        do {
            let resultado = try await produto.purchase()
            switch resultado {
            case .success(let verificacao):
                let ok = await processarTransacaoVerificada(verificacao)
                estado = ok ? .ocioso : .erro
                return ok
            case .userCancelled:
                estado = .ocioso   // cancelar não é erro: volta ao paywall normal
                return false
            case .pending:
                estado = .ocioso   // aguardando aprovação (ex.: Ask to Buy)
                return false
            @unknown default:
                estado = .erro
                return false
            }
        } catch {
            estado = .erro
            return false
        }
    }

    // Restaura a compra (critério 8.7 — botão no paywall e nas configurações).
    @discardableResult
    func restaurar() async -> Bool {
        estado = .processando
        try? await AppStore.sync()
        let ok = await atualizarEntitlement()
        estado = ok ? .ocioso : .erro
        return ok
    }

    // Reconsulta o entitlement local — chamado no início do app e após restaurar (regra 11.4).
    @discardableResult
    func atualizarEntitlement() async -> Bool {
        for await resultado in Transaction.currentEntitlements {
            if case .verified(let transacao) = resultado, transacao.productID == Self.produtoID {
                possuiProduto = true
                return true
            }
        }
        possuiProduto = false
        return false
    }

    // Verifica a assinatura da transação, marca posse e finaliza.
    @discardableResult
    private func processarTransacaoVerificada(_ resultado: VerificationResult<Transaction>) async -> Bool {
        guard case .verified(let transacao) = resultado, transacao.productID == Self.produtoID else {
            return false
        }
        possuiProduto = true
        await transacao.finish()
        return true
    }
}
