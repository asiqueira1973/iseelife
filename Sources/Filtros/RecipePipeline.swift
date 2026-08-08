// RecipePipeline.swift
// Pipeline de filtro das receitas (regra 11.2 e 11.3). Aplica, em cadeia de CIFilter, os
// parâmetros de uma `Receita` sobre uma CIImage. A MESMA função é usada no preview ao vivo
// (MetalCameraPreview) e na captura final antes de codificar o JPEG — garantindo que "a
// receita ativa no momento do disparo é a que é aplicada ao JPEG final" (critério 8.4 / 11.3).
//
// Ordem da cadeia: white balance -> curva de tom (highlight/shadow) -> saturação/monocromático
// -> nitidez -> grão. O grão vem por último para assentar sobre a imagem já tonalizada.
//
// Não existe caminho "sem filtro": a receita de ordem 1 ("Classic") é o padrão neutro-relativo
// (regra 11.3). O `forceMonochrome` é usado só pelo preview P&B do Modo Rua (config
// preview_pb_ativado) e NÃO afeta o arquivo salvo — só receitas com monocromatico=true afetam.

import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

// Snapshot de valor (queue-safe) dos parâmetros de uma `Receita`. A entidade SwiftData
// `receita` é um @Model e não deve ser lida fora da thread do seu contexto; o preview roda
// numa fila de vídeo dedicada, então o pipeline trabalha sobre esta cópia imutável.
struct RecipeValues {
    let highlight: Int
    let shadow: Int
    let saturacao: Int
    let temperaturaWbKelvin: Int?
    let tintaWb: Int
    let intensidadeGrao: IntensidadeGrao
    let nitidez: Int
    let monocromatico: Bool
    let filtroMono: FiltroMono?

    init(highlight: Int, shadow: Int, saturacao: Int, temperaturaWbKelvin: Int?, tintaWb: Int,
         intensidadeGrao: IntensidadeGrao, nitidez: Int, monocromatico: Bool, filtroMono: FiltroMono?) {
        self.highlight = highlight
        self.shadow = shadow
        self.saturacao = saturacao
        self.temperaturaWbKelvin = temperaturaWbKelvin
        self.tintaWb = tintaWb
        self.intensidadeGrao = intensidadeGrao
        self.nitidez = nitidez
        self.monocromatico = monocromatico
        self.filtroMono = filtroMono
    }

    // true quando a receita não altera nada (todos os parâmetros neutros) — a "Neutra"/raw.
    var ehNeutra: Bool {
        highlight == 0 && shadow == 0 && saturacao == 0 && temperaturaWbKelvin == nil
            && tintaWb == 0 && intensidadeGrao == .nenhum && nitidez == 0 && !monocromatico
    }

    // Cópia a partir da entidade SwiftData (lida na main/contexto do modelo).
    init(from receita: Receita) {
        self.init(
            highlight: receita.highlight,
            shadow: receita.shadow,
            saturacao: receita.saturacao,
            temperaturaWbKelvin: receita.temperaturaWbKelvin,
            tintaWb: receita.tintaWb,
            intensidadeGrao: receita.intensidadeGrao,
            nitidez: receita.nitidez,
            monocromatico: receita.monocromatico,
            filtroMono: receita.filtroMono
        )
    }
}

struct RecipePipeline {

    // CIContext compartilhado (caro de criar). Um por pipeline, reaproveitado a cada frame.
    let context: CIContext

    init(context: CIContext) {
        self.context = context
    }

    // Aplica a receita à imagem. `forceMonochrome` desatura só para o preview P&B (não persiste).
    func apply(_ recipe: RecipeValues, to input: CIImage, forceMonochrome: Bool = false) -> CIImage {
        // Receita "Neutra": imagem crua, sem nenhuma etapa (a menos que o preview P&B esteja
        // forçando desaturação). Retorna o frame do sensor intacto.
        if recipe.ehNeutra && !forceMonochrome { return input }

        var image = input

        image = applyWhiteBalance(recipe, to: image)          // regra 11.2 — temp/tinta WB
        image = applyToneCurve(recipe, to: image)             // regra 11.2 — highlight/shadow
        image = applyColor(recipe, to: image, forceMonochrome: forceMonochrome) // saturação/mono
        image = applySharpness(recipe, to: image)             // regra 11.2 — nitidez
        image = applyGrain(recipe, to: image)                 // regra 11.2 — grão procedural

        // Recorta ao extent original (blur/grão podem extrapolar as bordas).
        return image.cropped(to: input.extent)
    }

    // MARK: - White balance (temperatura + tinta) — regra 11.2

    // Convenção: temperatura_wb_kelvin é o Kelvin ASSUMIDO da cena (dial de WB). Valor baixo
    // esfria o resultado, alto esquenta. nil = segue o sensor (sem shift de temperatura).
    private func applyWhiteBalance(_ recipe: RecipeValues, to image: CIImage) -> CIImage {
        let temp = recipe.temperaturaWbKelvin
        let tint = recipe.tintaWb
        guard temp != nil || tint != 0 else { return image }

        let f = CIFilter.temperatureAndTint()
        f.inputImage = image
        // neutral = ponto neutro assumido da fonte; targetNeutral = padrão daylight (6500,0).
        // Escala do tint reduzida para 4 após validação visual no device (Soft estava verde
        // demais com ×10 — ajuste sancionado pela seção 23/DoD). tinta -9..9 -> ~-36..36.
        f.neutral = CIVector(x: CGFloat(temp ?? 6500), y: CGFloat(tint) * 4.0)
        f.targetNeutral = CIVector(x: 6500, y: 0)
        return f.outputImage ?? image
    }

    // MARK: - Curva de tom (highlight/shadow) — regra 11.2

    // highlight/shadow vão de -4 a +4. shadow>0 levanta sombras; highlight<0 abaixa altas luzes.
    // Modela uma tone curve suave de 5 pontos.
    private func applyToneCurve(_ recipe: RecipeValues, to image: CIImage) -> CIImage {
        guard recipe.highlight != 0 || recipe.shadow != 0 else { return image }
        let shadowShift = CGFloat(recipe.shadow) / 4.0 * 0.12   // ±0.12 no ponto de sombra
        let highlightShift = CGFloat(recipe.highlight) / 4.0 * 0.12 // ±0.12 no ponto de alta luz

        func clamp(_ v: CGFloat) -> CGFloat { min(max(v, 0), 1) }

        let f = CIFilter.toneCurve()
        f.inputImage = image
        f.point0 = CGPoint(x: 0.0, y: 0.0)
        f.point1 = CGPoint(x: 0.25, y: clamp(0.25 + shadowShift))
        f.point2 = CGPoint(x: 0.5, y: 0.5)
        f.point3 = CGPoint(x: 0.75, y: clamp(0.75 + highlightShift))
        f.point4 = CGPoint(x: 1.0, y: 1.0)
        return f.outputImage ?? image
    }

    // MARK: - Cor: saturação ou monocromático + filtro colorido — regra 11.2 / critério 8.4

    private func applyColor(_ recipe: RecipeValues, to image: CIImage, forceMonochrome: Bool) -> CIImage {
        // Receita monocromática (ou preview P&B forçado) remove toda a cor (critério 8.4).
        if recipe.monocromatico || forceMonochrome {
            let weights = monoWeights(recipe.monocromatico ? recipe.filtroMono : FiltroMono.nenhum)
            let f = CIFilter.colorMatrix()
            f.inputImage = image
            // Cada canal de saída recebe o mesmo somatório ponderado -> tons de cinza.
            let v = CIVector(x: weights.r, y: weights.g, z: weights.b, w: 0)
            f.rVector = v
            f.gVector = v
            f.bVector = v
            f.aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
            return f.outputImage ?? image
        }

        // Receita colorida: ajusta saturação. -4..+4 -> 0.5..1.5.
        guard recipe.saturacao != 0 else { return image }
        let f = CIFilter.colorControls()
        f.inputImage = image
        f.saturation = Float(1.0 + Double(recipe.saturacao) / 4.0 * 0.5)
        return f.outputImage ?? image
    }

    // Pesos de luminância para simular filtro colorido de fotografia P&B (regra 11.2, ex.: Acros+R).
    // Um filtro vermelho clareia vermelhos e escurece azuis/verdes (céu mais dramático), etc.
    private func monoWeights(_ filtro: FiltroMono?) -> (r: CGFloat, g: CGFloat, b: CGFloat) {
        switch filtro ?? .nenhum {
        case .nenhum:   return (0.299, 0.587, 0.114) // luminância padrão Rec.601
        case .vermelho: return (0.80, 0.10, 0.10)    // filtro vermelho — céu escuro, pele clara
        case .amarelo:  return (0.50, 0.40, 0.10)    // filtro amarelo — contraste suave
        case .verde:    return (0.10, 0.70, 0.20)    // filtro verde — folhagem/pele equilibradas
        }
    }

    // MARK: - Nitidez — regra 11.2

    // nitidez -4..+4. Positivo -> sharpen de luminância; negativo -> leve desfoque gaussiano.
    private func applySharpness(_ recipe: RecipeValues, to image: CIImage) -> CIImage {
        if recipe.nitidez > 0 {
            let f = CIFilter.sharpenLuminance()
            f.inputImage = image
            f.sharpness = Float(Double(recipe.nitidez) / 4.0) // 0..1
            return f.outputImage ?? image
        } else if recipe.nitidez < 0 {
            let f = CIFilter.gaussianBlur()
            f.inputImage = image
            f.radius = Float(Double(-recipe.nitidez) / 4.0 * 1.5) // 0..1.5 px
            return f.outputImage ?? image
        }
        return image
    }

    // MARK: - Grão procedural — regra 11.2

    // Intensidade nenhum/fraco/medio/forte -> opacidade do grão em soft light.
    private func applyGrain(_ recipe: RecipeValues, to image: CIImage) -> CIImage {
        let opacity: CGFloat
        switch recipe.intensidadeGrao {
        case .nenhum: return image
        case .fraco:  opacity = 0.05
        case .medio:  opacity = 0.11
        case .forte:  opacity = 0.18
        }

        // Ruído monocromático deslocado aleatoriamente para não "grudar" entre frames.
        let noise = CIFilter.randomGenerator().outputImage ?? image
        let dx = CGFloat.random(in: 0...512)
        let dy = CGFloat.random(in: 0...512)
        let shifted = noise.transformed(by: CGAffineTransform(translationX: dx, y: dy))

        // Converte o ruído em cinza de baixo contraste centrado em 0,5, com a opacidade alvo.
        let gray = CIFilter.colorMatrix()
        gray.inputImage = shifted
        let w = CIVector(x: 0.2126 * opacity, y: 0.7152 * opacity, z: 0.0722 * opacity, w: 0)
        gray.rVector = w
        gray.gVector = w
        gray.bVector = w
        gray.aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
        gray.biasVector = CIVector(x: 0.5 - opacity / 2, y: 0.5 - opacity / 2, z: 0.5 - opacity / 2, w: 0)
        let grain = (gray.outputImage ?? shifted).cropped(to: image.extent)

        // Soft light mescla o grão preservando a tonalidade geral.
        let blend = CIFilter.softLightBlendMode()
        blend.inputImage = grain
        blend.backgroundImage = image
        return blend.outputImage ?? image
    }
}
