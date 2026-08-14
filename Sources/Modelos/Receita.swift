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

    // highlight/shadow/saturacao — guardados em MEIO-PASSO ×2 (v1.1): o valor armazenado é o
    // dobro do valor real, para permitir -1,5 / +0,5 sem mudar o tipo Int (evita migração de
    // schema). Ex.: -1,5 é guardado como -3. O RecipeValues divide por 2. Faixa real -4..+4.
    var highlight: Int

    var shadow: Int

    // saturacao — meio-passo ×2. Ignorada quando monocromatico == true.
    var saturacao: Int

    // temperatura_wb_kelvin — nulo = segue WB automático do sensor (regra 11.2).
    var temperaturaWbKelvin: Int?

    // tinta_wb — eixo VERDE/MAGENTA, faixa -9 a +9 (regra 11.2). Default 0. (NÃO confundir com o
    // eixo vermelho/azul, que são os campos ajuste_vermelho/ajuste_azul abaixo.)
    var tintaWb: Int

    // intensidade_grao — força do grão procedural (regra 11.2). Default nenhum.
    var intensidadeGrao: IntensidadeGrao

    // nitidez — faixa -4 a +4 (regra 11.2).
    var nitidez: Int

    // monocromatico — remove toda a cor no preview e no JPEG final (critério 8.4). Default false.
    var monocromatico: Bool

    // filtro_mono — filtro colorido simulado; só relevante com monocromatico == true (regra 11.2).
    var filtroMono: FiltroMono?

    // ordem_exibicao — ordem fixa no seletor; a de ordem 1 é o padrão neutro (regra 11.3).
    var ordemExibicao: Int

    // ---- Campos de fidelidade (v1.1) — defaults inline para migração automática (aditiva) ----

    // WB shift no eixo VERMELHO/AZUL (modelo Fuji "Red & Blue"), aplicado como ganho por canal.
    // Faixa típica -9..+9. Default 0 (as 5 receitas originais não usam este eixo).
    var ajusteVermelho: Int = 0
    var ajusteAzul: Int = 0

    // Color Chrome — compressão de saturação nos tons muito saturados. Eixo quente/vermelho e
    // eixo azul. Default desligado.
    var efeitoColorChrome: EfeitoColorChrome = EfeitoColorChrome.desligado
    var efeitoColorChromeAzul: EfeitoColorChrome = EfeitoColorChrome.desligado

    // clareza — contraste local (diferente de nitidez). Faixa -4..+4 (inteiro cheio). Default 0.
    var clareza: Int = 0

    // tamanho_grao — segunda dimensão do grão. Default pequeno (= comportamento original do grão,
    // então as 5 receitas originais ficam idênticas).
    var tamanhoGrao: TamanhoGrao = TamanhoGrao.pequeno

    // criada_pelo_usuario — false para o catálogo fixo; prepara o terreno para receitas
    // customizadas (roadmap). Default false.
    var criadaPeloUsuario: Bool = false

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
        ordemExibicao: Int,
        ajusteVermelho: Int = 0,
        ajusteAzul: Int = 0,
        efeitoColorChrome: EfeitoColorChrome = .desligado,
        efeitoColorChromeAzul: EfeitoColorChrome = .desligado,
        clareza: Int = 0,
        tamanhoGrao: TamanhoGrao = .pequeno,
        criadaPeloUsuario: Bool = false
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
        self.ajusteVermelho = ajusteVermelho
        self.ajusteAzul = ajusteAzul
        self.efeitoColorChrome = efeitoColorChrome
        self.efeitoColorChromeAzul = efeitoColorChromeAzul
        self.clareza = clareza
        self.tamanhoGrao = tamanhoGrao
        self.criadaPeloUsuario = criadaPeloUsuario
    }
}
