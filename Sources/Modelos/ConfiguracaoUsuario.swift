// ConfiguracaoUsuario.swift
// Entidade SwiftData `configuracao_usuario` (spec seção 7). Linha única (singleton),
// criada no primeiro uso do app — guarda todas as preferências locais do usuário.
// Sem backend, sem sincronização, sem múltiplos perfis. Atualizada in-place; nunca
// excluída pelo usuário no MVP (spec seção 7 — estratégia de exclusão).

import Foundation
import SwiftData

@Model
final class ConfiguracaoUsuario {
    // id: UUID [pk]
    var id: UUID

    // idioma_preferido — pt por padrão (spec seção 7).
    var idiomaPreferido: Idioma

    // modo_padrao — Modo Rua por padrão, respeitando o princípio 0.1 (abrir já pronto).
    var modoPadrao: ModoCaptura

    // ultima_lente_usada — nulo até a primeira captura; lembrada entre sessões (épico 8.3).
    var ultimaLenteUsada: LenteCamera?

    // grid_ativado — grid de terços sobreposto ao visor (épico 8.2/8.8). Default true.
    var gridAtivado: Bool

    // nivel_ativado — indicador de nível/giroscópio (spec seção 3). Default true.
    var nivelAtivado: Bool

    // obturador_silencioso — captura sem som (critério 8.1). Default true.
    var obturadorSilencioso: Bool

    // preview_pb_ativado — preview em preto e branco no Modo Rua (spec seção 3). Default false.
    var previewPbAtivado: Bool

    // compra_desbloqueada — vira true após a compra confirmada (regra 11.4). Default false.
    var compraDesbloqueada: Bool

    // data_compra — nulo até a compra ser confirmada (critério 8.7).
    var dataCompra: Date?

    // Onboarding só aparece uma vez (critério 8.6). Não está no DBML original porque é
    // estado de UI local; mora aqui por ser preferência de sessão persistida in-place.
    var onboardingConcluido: Bool

    // id da receita ativa no seletor (ordem_exibicao). Não está no DBML — é estado de UI
    // persistido para lembrar a última receita escolhida entre sessões. Nulo => usa a
    // primeira receita (ordem_exibicao = 1) como padrão neutro (regra 11.3).
    var receitaAtivaID: UUID?

    // Piso de velocidade do obturador no Modo Rua (prioridade de obturador — enhancement pós-spec
    // pedido pelo Alexandre no device). Guarda o DENOMINADOR: 250 => 1/250s. Opcional para
    // migração segura; nil => 250 (padrão). Opções na UI: 250, 500, 1000.
    var ruaObturadorDenominador: Int?

    // cria a linha única com os defaults exatos da seção 7 / DBML.
    init(
        id: UUID = UUID(),
        idiomaPreferido: Idioma = .pt,
        modoPadrao: ModoCaptura = .rua,
        ultimaLenteUsada: LenteCamera? = nil,
        gridAtivado: Bool = true,
        nivelAtivado: Bool = true,
        obturadorSilencioso: Bool = true,
        previewPbAtivado: Bool = false,
        compraDesbloqueada: Bool = false,
        dataCompra: Date? = nil,
        onboardingConcluido: Bool = false,
        receitaAtivaID: UUID? = nil,
        ruaObturadorDenominador: Int? = nil
    ) {
        self.id = id
        self.idiomaPreferido = idiomaPreferido
        self.modoPadrao = modoPadrao
        self.ultimaLenteUsada = ultimaLenteUsada
        self.gridAtivado = gridAtivado
        self.nivelAtivado = nivelAtivado
        self.obturadorSilencioso = obturadorSilencioso
        self.previewPbAtivado = previewPbAtivado
        self.compraDesbloqueada = compraDesbloqueada
        self.dataCompra = dataCompra
        self.onboardingConcluido = onboardingConcluido
        self.receitaAtivaID = receitaAtivaID
        self.ruaObturadorDenominador = ruaObturadorDenominador
    }
}
