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
    // `nomeExibicao` (a identidade estável da receita): insere o que falta e atualiza in-place o
    // que existe, mantendo o mesmo `id` — assim `configuracao_usuario.receitaAtivaID` continua
    // válido mesmo quando a ORDEM muda (ex.: ao inserir "Neutra" na frente, "Classic" continua
    // sendo o mesmo objeto, só muda a ordem_exibicao). Ajustes de receita propagam na próxima
    // abertura, mesmo em app já instalado.
    static func sincronizarCatalogo(context: ModelContext) {
        let existentes = (try? context.fetch(FetchDescriptor<Receita>())) ?? []
        let porNome = Dictionary(existentes.map { ($0.nomeExibicao, $0) }, uniquingKeysWith: { a, _ in a })

        for canonica in receitasPadrao() {
            if let atual = porNome[canonica.nomeExibicao] {
                atual.ordemExibicao = canonica.ordemExibicao
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
                atual.ajusteVermelho = canonica.ajusteVermelho
                atual.ajusteAzul = canonica.ajusteAzul
                atual.efeitoColorChrome = canonica.efeitoColorChrome
                atual.efeitoColorChromeAzul = canonica.efeitoColorChromeAzul
                atual.clareza = canonica.clareza
                atual.tamanhoGrao = canonica.tamanhoGrao
                atual.criadaPeloUsuario = canonica.criadaPeloUsuario
            } else {
                context.insert(canonica)
            }
        }

        // Remove receitas FIXAS que saíram do catálogo (ex.: Retrô/Retrato/Dourada removidas na
        // v1.1). Não mexe em receitas criadas pelo usuário (roadmap).
        let nomesCanonicos = Set(receitasPadrao().map { $0.nomeExibicao })
        for r in existentes where !r.criadaPeloUsuario && !nomesCanonicos.contains(r.nomeExibicao) {
            context.delete(r)
        }

        try? context.save()
    }

    // Catálogo fixo. Ordem 1 = "Neutra" (imagem crua do iPhone, padrão). As 4 receitas de cor
    // seguem a tabela 11.2. Enhancement pós-spec pedido pelo Alexandre no device.
    static func receitasPadrao() -> [Receita] {
        [
            // "Neutra" — imagem crua, SEM receita. Todos os parâmetros neutros: o RecipePipeline
            // passa o frame do sensor sem alteração. É a receita de ordem 1 (padrão neutro,
            // regra 11.3) — agora, de fato, o raw do iPhone.
            Receita(
                nomeExibicao: "Neutra",
                inspiracao: "Câmera do iPhone (sem receita)",
                highlight: 0,
                shadow: 0,
                saturacao: 0,
                temperaturaWbKelvin: nil,     // segue o WB do sensor, sem shift
                tintaWb: 0,
                intensidadeGrao: .nenhum,
                nitidez: 0,
                monocromatico: false,
                filtroMono: nil,
                ordemExibicao: 1
            ),
            // "Classic" — insp. Fuji Classic Chrome. WB "quente" => 7000K.
            Receita(
                nomeExibicao: "Classic",
                inspiracao: "Classic Chrome",
                highlight: -2,  // -1,0 em meio-passo ×2
                shadow: 2,      // +1,0
                saturacao: 4,   // +2,0
                temperaturaWbKelvin: 7000,   // "quente" (qualitativo no spec) -> Kelvin alto
                tintaWb: 0,
                intensidadeGrao: .fraco,
                nitidez: 2,
                monocromatico: false,
                filtroMono: nil,
                ordemExibicao: 2
            ),
            // "Soft" — insp. Astia/Soft. AJUSTE VISUAL (device, a pedido do Alexandre): o spec
            // dava WB 2650K + tint -8, que juntos deixavam a receita verde-teal — longe do
            // Astia real (suave, baixo contraste, saturação contida, pele levemente quente, sem
            // dominante verde). Revisado para bater com a referência: WB neutra-suave e um sopro
            // de magenta no lugar do verde. Registrado em DOCUMENTACAO-TECNICA.md (divergências).
            Receita(
                nomeExibicao: "Soft",
                inspiracao: "Astia/Soft",
                highlight: -4,  // -2,0 em meio-passo ×2
                shadow: 0,      //  0
                saturacao: -4,  // -2,0
                temperaturaWbKelvin: 5600,   // era 2650 (azul demais) -> neutra-suave
                tintaWb: 1,                  // era -8 (verde) -> +1 sopro de magenta (pele)
                intensidadeGrao: .nenhum,
                nitidez: -1,
                monocromatico: false,
                filtroMono: nil,
                ordemExibicao: 3
            ),
            // "Mono" — insp. Acros + filtro vermelho. shadow "+3 a +4" -> +4 (extremo mais
            // "moody", casando com a inspiração "Moody Monochrome"). saturação "—" (N/A em mono).
            Receita(
                nomeExibicao: "Mono",
                inspiracao: "Acros+R",
                highlight: -2,                // -1,0 em meio-passo ×2
                shadow: 8,                    // +4,0 (faixa +3 a +4 -> +4)
                saturacao: 0,                 // "—" no spec (irrelevante em monocromático)
                temperaturaWbKelvin: nil,     // "neutro" -> segue sensor, sem shift
                tintaWb: -1,
                intensidadeGrao: .forte,
                nitidez: -2,
                monocromatico: true,
                filtroMono: .vermelho,
                ordemExibicao: 4
            ),
            // "Positivo" — insp. Ricoh GR III Positive Film. highlight "-2 a -4" -> -3;
            // shadow "+2 a +4" -> +3 (pontos médios). WB "fria, correção de highlight ativa"
            // -> 5000K (levemente fria); a correção de highlight é coberta pelo highlight -3.
            Receita(
                nomeExibicao: "Positivo",
                inspiracao: "Ricoh GR Positive Film",
                highlight: -6,                // -3,0 em meio-passo ×2 (faixa -2 a -4 -> -3)
                shadow: 6,                    // +3,0 (faixa +2 a +4 -> +3)
                saturacao: 6,                 // +3,0
                temperaturaWbKelvin: 5000,    // "fria" (qualitativo) -> Kelvin levemente baixo
                tintaWb: 3,
                intensidadeGrao: .nenhum,
                nitidez: 0,
                monocromatico: false,
                filtroMono: nil,
                ordemExibicao: 5
            ),

            // ---- Receita nova (v1.1) — só a Vívida foi aprovada visualmente no device; Retrô,
            // Retrato e Dourada foram removidas. hl/sh/sat em MEIO-PASSO ×2.

            // "Vívida" — insp. Kodachrome 64 (cores punchy, clareza alta, grão fino).
            Receita(
                nomeExibicao: "Vívida",
                inspiracao: "Kodachrome 64",
                highlight: 0,                 //  0
                shadow: 1,                    // +0,5
                saturacao: 4,                 // +2,0
                temperaturaWbKelvin: 5500,    // Daylight
                tintaWb: 0,
                intensidadeGrao: .fraco,
                nitidez: 1,
                monocromatico: false,
                filtroMono: nil,
                ordemExibicao: 6,
                ajusteVermelho: 2,
                ajusteAzul: -5,
                efeitoColorChrome: .forte,
                efeitoColorChromeAzul: .desligado,
                clareza: 3,
                tamanhoGrao: .pequeno
            ),
        ]
    }
}
