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

    // Catálogo fixo (v1.2). Ordem 1 = "Neutra" (imagem crua do iPhone, padrão). Depois: Classic,
    // Soft, Retrato 400 (Fuji, aprovada no TestFlight) e 5 receitas inspiradas na Ricoh GR III
    // (Color Film, Americana Color, Analog Film, Monochrome Film, Black & White Negative).
    // Removidas em v1.2: Mono, Positivo, Vívida, Retrato 800 (o sincronizarCatalogo apaga as
    // não-canônicas na próxima abertura). Enhancement pós-spec pedido pelo Alexandre no device.
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
            // ---- Receita aprovada no TestFlight (mantida). hl/sh/sat em MEIO-PASSO ×2. Nome NÃO
            // usa marca de terceiro; o número 400 é a sensibilidade ISO (genérica).

            // "Retrato 400" — negativo de retrato ISO 400: tons de pele quentes, contido, grão fino.
            Receita(
                nomeExibicao: "Retrato 400",
                inspiracao: "Negativo de retrato ISO 400",
                highlight: 0,                 //  0
                shadow: -4,                   // -2
                saturacao: 4,                 // +2 (Color)
                temperaturaWbKelvin: 5200,
                tintaWb: 0,                   // eixo verde/magenta (o R/B vai nos ajustes abaixo)
                intensidadeGrao: .forte,      // Grain Effect: Strong
                nitidez: -2,                  // Sharpness -2
                monocromatico: false,
                filtroMono: nil,
                ordemExibicao: 4,
                ajusteVermelho: 1,            // WB +1 Red
                ajusteAzul: -6,               // WB -6 Blue
                efeitoColorChrome: .forte,    // Color Chrome: Strong
                efeitoColorChromeAzul: .desligado, // Color Chrome Blue: Off
                clareza: -2,                  // Clarity -2
                tamanhoGrao: .pequeno         // Grain: Small
            ),

            // ---- Receitas NOVAS (TestFlight) — inspiradas em receitas Ricoh GR III (Image Control).
            // O Image Control da Ricoh tem mais controles que o pipeline do app (Hue, High/Low Key,
            // Contrast base, Shading, Toning, Filter Effect, correções de highlight/shadow/iluminação
            // periférica) — SEM campo no modelo, então são APROXIMAÇÕES a calibrar no device:
            //   • saturacao  <- Saturation
            //   • highlight  <- Contrast (Highlight)   [sinal direto; se vier invertido, trocar]
            //   • shadow     <- Contrast (Shadow)       [sinal direto; idem]
            //   • nitidez    <- Sharpness   • clareza <- Clarity   • grão <- Grain Effect
            //   • WB: usa CT quando informado; a compensação A/G (âmbar/verde) vira ajuste R/B + tinta.
            // Hue, High/Low Key e Contrast base ficam de fora (sem campo). hl/sh/sat em MEIO-PASSO ×2.

            // "Color Film" — Effect Standard, natural com sombras suaves (Contrast Shadow -4).
            Receita(
                nomeExibicao: "Color Film",
                inspiracao: "Ricoh GR — Standard",
                highlight: 4,                 // Contrast (Highlight) +2  -> +2 ×2
                shadow: -8,                   // Contrast (Shadow) -4     -> -4 ×2
                saturacao: 2,                 // Saturation +1            -> +1 ×2
                temperaturaWbKelvin: nil,     // WB Auto (AWB) -> segue sensor; calor vai no R/B
                tintaWb: -1,                  // WB comp G:2 (verde leve)
                intensidadeGrao: .nenhum,     // Grain não especificado
                nitidez: 1,                   // Sharpness +1
                monocromatico: false,
                filtroMono: nil,
                ordemExibicao: 5,
                ajusteVermelho: 5,            // WB comp A:9 (âmbar/quente)
                ajusteAzul: -5,
                efeitoColorChrome: .desligado,
                efeitoColorChromeAzul: .desligado,
                clareza: -1                   // Clarity -1
            ),

            // "Americana Color" — Positive Film, saturada e contrastada, WB quente (CT 5250K).
            Receita(
                nomeExibicao: "Americana Color",
                inspiracao: "Ricoh GR — Positive Film",
                highlight: -6,                // Contrast (Highlight) -3  -> -3 ×2
                shadow: 8,                    // Contrast (Shadow) +4     -> +4 ×2
                saturacao: 4,                 // Saturation +2            -> +2 ×2
                temperaturaWbKelvin: 5250,    // CT 5250K
                tintaWb: -3,                  // WB comp G:5 (verde)
                intensidadeGrao: .nenhum,
                nitidez: 1,                   // Sharpness +1
                monocromatico: false,
                filtroMono: nil,
                ordemExibicao: 6,
                ajusteVermelho: 5,            // WB comp A:10 (âmbar) sobre o CT
                ajusteAzul: -5,
                efeitoColorChrome: .fraco,    // Positive Film comprime tons saturados (aprox.)
                efeitoColorChromeAzul: .desligado,
                clareza: 2                    // Clarity +2
            ),

            // "Analog Film" — Positive Film bem saturada (Sat +4), Hue -4 (sem campo -> aproximado
            // só pela saturação/WB), WB 6300K.
            Receita(
                nomeExibicao: "Analog Film",
                inspiracao: "Ricoh GR — Positive Film",
                highlight: -8,                // Contrast (Highlight) -4  -> -4 ×2
                shadow: 8,                    // Contrast (Shadow) +4     -> +4 ×2
                saturacao: 8,                 // Saturation +4            -> +4 ×2
                temperaturaWbKelvin: 6300,    // CT 6300K
                tintaWb: -3,                  // WB comp G:6 (verde)
                intensidadeGrao: .nenhum,
                nitidez: 0,                   // Sharpness 0
                monocromatico: false,
                filtroMono: nil,
                ordemExibicao: 7,
                ajusteVermelho: 1,            // WB comp A:1 (âmbar leve)
                ajusteAzul: -1,
                efeitoColorChrome: .fraco,    // Positive Film (aprox.)
                efeitoColorChromeAzul: .desligado,
                clareza: -2                   // Clarity -2
            ),

            // "Monochrome Film" — BW Monotone, contraste baixo (Contrast Highlight/Shadow -4/-4),
            // grão leve. Filter Effect 2 sem mapa limpo -> sem filtro.
            Receita(
                nomeExibicao: "Monochrome Film",
                inspiracao: "Ricoh GR — BW Monotone",
                highlight: -8,                // Contrast (Highlight) -4  -> -4 ×2
                shadow: -8,                   // Contrast (Shadow) -4     -> -4 ×2
                saturacao: 0,                 // mono
                temperaturaWbKelvin: nil,     // irrelevante em mono
                tintaWb: 0,
                intensidadeGrao: .fraco,      // Grain Effect 1
                nitidez: 1,                   // Sharpness +1
                monocromatico: true,
                filtroMono: nil,              // Filter Effect 2 (sem mapa) -> nenhum
                ordemExibicao: 8,
                clareza: 2,                   // Clarity +2
                tamanhoGrao: .pequeno
            ),

            // "Black & White Negative" — Hi-Contrast B&W, highlights suaves (Contrast Highlight -4),
            // grão mais presente (Grain Effect 2).
            Receita(
                nomeExibicao: "Black & White Negative",
                inspiracao: "Ricoh GR — Hi-Contrast B&W",
                highlight: -8,                // Contrast (Highlight) -4  -> -4 ×2
                shadow: 0,                    // Contrast (Shadow) 0
                saturacao: 0,                 // mono
                temperaturaWbKelvin: nil,     // irrelevante em mono
                tintaWb: 0,
                intensidadeGrao: .medio,      // Grain Effect 2
                nitidez: -1,                  // Sharpness -1
                monocromatico: true,
                filtroMono: nil,              // Filter Effect Off
                ordemExibicao: 9,
                clareza: 2,                   // Clarity +2
                tamanhoGrao: .pequeno
            ),
        ]
    }
}
