# I See Life

App de câmera iOS com pegada de fotografia de rua: abre rápido, dispara rápido e
produz JPEG com caráter, através de 4 "receitas" de cor aplicadas em tempo real no
visor (inspiradas em simulações de filme). Dois modos: **Modo Rua** (ágil, quase sem
UI) e **Modo Pro** (controle manual completo de ISO, obturador, exposição, foco e WB).

Local-first, 100% offline, sem backend. Compra única via StoreKit 2.

## Stack

- Swift + SwiftUI
- SwiftData (persistência local — `configuracao_usuario`, `receita`)
- AVFoundation (captura, controle manual, discovery de lentes)
- Core Image (pipeline das receitas, em tempo real no preview e na captura)
- StoreKit 2 (compra única não-consumível)
- iOS 17.0+, iPhone apenas, retrato apenas

## Setup local

Pré-requisitos: Xcode 26+, [XcodeGen](https://github.com/yonaskolb/XcodeGen)
(`brew install xcodegen`).

```bash
# gera o .xcodeproj a partir do project.yml (fonte de verdade)
xcodegen generate

# abre no Xcode
open ISeeLife.xcodeproj
```

O esquema `ISeeLife` já vem com o `ISeeLife.storekit` configurado para testar o
paywall em sandbox. Rode em **device físico** para validar câmera e captura — o
simulador não expõe câmera.

## Estrutura

Ver seção 18 do `spec.md`. Documentação técnica completa em `DOCUMENTACAO-TECNICA.md`.

## Documentos

- `spec.md` — especificação completa do produto (fonte única de verdade).
- `modelo-app-camera-rua.dbml` — modelo de dados.
- `telas/` — telas de referência de UI.
- `DOCUMENTACAO-TECNICA.md` — documentação técnica da implementação (seção 19).
