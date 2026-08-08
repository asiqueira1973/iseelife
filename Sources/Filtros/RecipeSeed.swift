// RecipeSeed.swift
// Seed das 4 receitas de `receita` na primeira execução do app (spec seção 7 e regra 11.2).
// Inserção idempotente: só popula se a tabela `receita` estiver vazia (verificado no
// onAppear do app root). Somente-leitura depois disso — o usuário não edita receitas no MVP.
//
// Os valores vêm literalmente da tabela 11.2. Onde a spec dá faixa ("+3 a +4") ou termo
// qualitativo ("quente", "fria", "neutro"), o valor concreto escolhido está anotado aqui e
// registrado como interpretação em DOCUMENTACAO-TECNICA.md (item 6 — divergências).
//
// Convenção de temperatura_wb_kelvin: é o Kelvin ASSUMIDO da cena (como o dial de WB de uma
// câmera). Valor BAIXO esfria/azula o resultado; valor ALTO esquenta — por isso Soft "fria"
// = 2650K (explícito no spec) e Classic "quente" = Kelvin alto. nil = segue o WB automático
// do sensor, sem shift (regra 11.2).

import Foundation
import SwiftData

enum RecipeSeed {

    // Sincroniza o catálogo fixo (regra 11.2 / seção 7). `receita` é dado somente-leitura do
    // app, não do usuário — então SEMPRE reflete os valores canônicos do código. Faz upsert por
    // `ordemExibicao`: insere o que falta e atualiza in-place o que existe (mantendo o `id`, para
    // não invalidar `configuracao_usuario.receitaAtivaID`). Assim, ajuste de parâmetro de receita
    // propaga na próxima abertura, mesmo em app já instalado.
    static func sincronizarCatalogo(context: ModelContext) {
        let existentes = (try? context.fetch(FetchDescriptor<Receita>())) ?? []
        let porOrdem = Dictionary(existentes.map { ($0.ordemExibicao, $0) }, uniquingKeysWith: { a, _ in a })

        for canonica in receitasPadrao() {
            if let atual = porOrdem[canonica.ordemExibicao] {
                atual.nomeExibicao = canonica.nomeExibicao
                atual.inspiracao = canonica.inspiracao
                atual.highlight = canonica.highlight
                atual.shadow = canonica.shadow
                atual.saturacao = canonica.saturacao
                atual.temperaturaWbKelvin = canonica.temperaturaWbKelvin
                atual.tintaWb = canonica.tintaWb
                atual.intensidadeGrao = canonica.intensidadeGrao
                atual.nitidez = canonica.nitidez
                atual.monocromatico = canonica.monocromatico
                atual.filtroMono = canonica.filtroMono
            } else {
                context.insert(canonica)
            }
        }
        try? context.save()
    }

    // Catálogo fixo — reflete a tabela 11.2 linha a linha.
    static func receitasPadrao() -> [Receita] {
        [
            // "Classic" — insp. Fuji Classic Chrome. É a receita de ordem 1: padrão neutro-relativo
            // usado quando nenhuma receita foi escolhida (regra 11.3). WB "quente" => 7000K.
            Receita(
                nomeExibicao: "Classic",
                inspiracao: "Classic Chrome",
                highlight: -1,
                shadow: 1,
                saturacao: 2,
                temperaturaWbKelvin: 7000,   // "quente" (qualitativo no spec) -> Kelvin alto
                tintaWb: 0,
                intensidadeGrao: .fraco,
                nitidez: 2,
                monocromatico: false,
                filtroMono: nil,
                ordemExibicao: 1
            ),
            // "Soft" — insp. Astia/Soft. AJUSTE VISUAL (device, a pedido do Alexandre): o spec
            // dava WB 2650K + tint -8, que juntos deixavam a receita verde-teal — longe do
            // Astia real (suave, baixo contraste, saturação contida, pele levemente quente, sem
            // dominante verde). Revisado para bater com a referência: WB neutra-suave e um sopro
            // de magenta no lugar do verde. Registrado em DOCUMENTACAO-TECNICA.md (divergências).
            Receita(
                nomeExibicao: "Soft",
                inspiracao: "Astia/Soft",
                highlight: -2,
                shadow: 0,
                saturacao: -2,
                temperaturaWbKelvin: 5600,   // era 2650 (azul demais) -> neutra-suave
                tintaWb: 1,                  // era -8 (verde) -> +1 sopro de magenta (pele)
                intensidadeGrao: .nenhum,
                nitidez: -1,
                monocromatico: false,
                filtroMono: nil,
                ordemExibicao: 2
            ),
            // "Mono" — insp. Acros + filtro vermelho. shadow "+3 a +4" -> +4 (extremo mais
            // "moody", casando com a inspiração "Moody Monochrome"). saturação "—" (N/A em mono).
            Receita(
                nomeExibicao: "Mono",
                inspiracao: "Acros+R",
                highlight: -1,
                shadow: 4,                    // faixa +3 a +4 -> +4
                saturacao: 0,                 // "—" no spec (irrelevante em monocromático)
                temperaturaWbKelvin: nil,     // "neutro" -> segue sensor, sem shift
                tintaWb: -1,
                intensidadeGrao: .forte,
                nitidez: -2,
                monocromatico: true,
                filtroMono: .vermelho,
                ordemExibicao: 3
            ),
            // "Positivo" — insp. Ricoh GR III Positive Film. highlight "-2 a -4" -> -3;
            // shadow "+2 a +4" -> +3 (pontos médios). WB "fria, correção de highlight ativa"
            // -> 5000K (levemente fria); a correção de highlight é coberta pelo highlight -3.
            Receita(
                nomeExibicao: "Positivo",
                inspiracao: "Ricoh GR Positive Film",
                highlight: -3,                // faixa -2 a -4 -> -3
                shadow: 3,                    // faixa +2 a +4 -> +3
                saturacao: 3,
                temperaturaWbKelvin: 5000,    // "fria" (qualitativo) -> Kelvin levemente baixo
                tintaWb: 3,
                intensidadeGrao: .nenhum,
                nitidez: 0,
                monocromatico: false,
                filtroMono: nil,
                ordemExibicao: 4
            ),
        ]
    }
}
