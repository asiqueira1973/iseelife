// Enums.swift
// Enumerações de domínio do modelo de dados (spec seção 7 / modelo-app-camera-rua.dbml).
// Nomes de entidade permanecem em português (convenção da seção 7/18); os casos de enum
// seguem inglês idiomático da plataforma (assunção 24.1), com rawValue em português para
// casar com o vocabulário do modelo e persistir de forma estável.

import Foundation

// idioma_preferido — idioma da interface (pt/en). Usado pela troca em tempo real (épico 8.8).
enum Idioma: String, Codable, CaseIterable {
    case pt
    case en
}

// modo_captura — modo padrão de abertura do visor (spec seção 7).
enum ModoCaptura: String, Codable, CaseIterable {
    case rua   // Modo Rua — ágil, até um toque (princípio 0.1)
    case pro   // Modo Pro — controle manual completo (épico 8.2)
}

// lente_camera — lentes traseiras suportadas no MVP (spec seção 3, regra 11.1).
// Sem telephoto no MVP (iPhone 13 mini de teste só expõe wide/ultra-wide).
enum LenteCamera: String, Codable, CaseIterable {
    case wide       // lente principal (~1x)
    case ultra_wide // ultra-angular (~0.5x)
}

// intensidade_grao — grão procedural aplicado pela receita (regra 11.2).
enum IntensidadeGrao: String, Codable, CaseIterable {
    case nenhum
    case fraco
    case medio
    case forte
}

// filtro_mono — filtro colorido simulado em receitas monocromáticas (regra 11.2, ex.: Acros+R).
// Só é relevante quando `monocromatico == true`.
enum FiltroMono: String, Codable, CaseIterable {
    case nenhum
    case amarelo
    case vermelho
    case verde
}

// efeito_color_chrome — compressão de saturação em tons muito saturados (presente em quase toda
// receita Fuji). Dois eixos: um "quente/vermelho" e um "azul" (efeito_color_chrome_azul).
// Enhancement pós-spec (v1.1).
enum EfeitoColorChrome: String, Codable, CaseIterable {
    case desligado
    case fraco
    case forte
}

// tamanho_grao — segunda dimensão do grão, além da intensidade (receitas de referência
// especificam os dois, ex.: "Strong Small", "Weak Large"). Enhancement pós-spec (v1.1).
enum TamanhoGrao: String, Codable, CaseIterable {
    case pequeno
    case grande
}
