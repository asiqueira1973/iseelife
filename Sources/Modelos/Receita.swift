// Receita.swift
// Entidade SwiftData `receita` (spec seção 7). Catálogo fixo de 4 receitas de cor
// (film simulation), inserido por seed na primeira execução e somente-leitura no MVP
// (o usuário não cria nem edita receitas — isso é roadmap, seção 28). Cada campo
// alimenta o pipeline Core Image da regra 11.2/11.3.

import Foundation
import SwiftData

@Model
final class Receita {
    // id: UUID [pk]
    var id: UUID

    // nome_exibicao — rótulo mostrado no seletor (ex.: "Classic", "Soft", "Mono", "Positivo").
    var nomeExibicao: String

    // inspiracao — referência interna (NÃO exibida como marca de terceiro na UI — spec seção 7).
    var inspiracao: String

    // highlight — curva de tom nas altas luzes, faixa -4 a +4 (regra 11.2).
    var highlight: Int

    // shadow — curva de tom nas sombras, faixa -4 a +4 (regra 11.2).
    var shadow: Int

    // saturacao — faixa -4 a +4 (regra 11.2). Ignorada quando monocromatico == true.
    var saturacao: Int

    // temperatura_wb_kelvin — nulo = segue WB automático do sensor (regra 11.2).
    var temperaturaWbKelvin: Int?

    // tinta_wb — eixo verde/magenta, faixa -9 a +9 (regra 11.2). Default 0.
    var tintaWb: Int

    // intensidade_grao — grão procedural (regra 11.2). Default nenhum.
    var intensidadeGrao: IntensidadeGrao

    // nitidez — faixa -4 a +4 (regra 11.2).
    var nitidez: Int

    // monocromatico — remove toda a cor no preview e no JPEG final (critério 8.4). Default false.
    var monocromatico: Bool

    // filtro_mono — filtro colorido simulado; só relevante com monocromatico == true (regra 11.2).
    var filtroMono: FiltroMono?

    // ordem_exibicao — ordem fixa no seletor; a de ordem 1 é o padrão neutro (regra 11.3).
    var ordemExibicao: Int

    init(
        id: UUID = UUID(),
        nomeExibicao: String,
        inspiracao: String,
        highlight: Int,
        shadow: Int,
        saturacao: Int,
        temperaturaWbKelvin: Int?,
        tintaWb: Int,
        intensidadeGrao: IntensidadeGrao,
        nitidez: Int,
        monocromatico: Bool,
        filtroMono: FiltroMono?,
        ordemExibicao: Int
    ) {
        self.id = id
        self.nomeExibicao = nomeExibicao
        self.inspiracao = inspiracao
        self.highlight = highlight
        self.shadow = shadow
        self.saturacao = saturacao
        self.temperaturaWbKelvin = temperaturaWbKelvin
        self.tintaWb = tintaWb
        self.intensidadeGrao = intensidadeGrao
        self.nitidez = nitidez
        self.monocromatico = monocromatico
        self.filtroMono = filtroMono
        self.ordemExibicao = ordemExibicao
    }
}
