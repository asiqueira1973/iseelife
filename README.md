# I See Life

App de câmera para iPhone com pegada de fotografia de rua: abre rápido, dispara rápido e produz JPEG com caráter, com "receitas" de cor aplicadas em tempo real no visor.

[Baixar na App Store](https://apps.apple.com/br/app/i-see-life/id6799311673) · [Baixar na Google Play](https://play.google.com/store/apps/details?id=com.dablab.iseelife) · Código da versão Android: [iseelife-android](https://github.com/asiqueira1973/iseelife-android)

<p>
  <img src="appstore%20screenshots/pt/01-heroi.png" width="160" alt="I See Life">
  <img src="appstore%20screenshots/pt/02-receitas.png" width="160" alt="Receitas">
  <img src="appstore%20screenshots/pt/03-um-toque.png" width="160" alt="Um toque">
  <img src="appstore%20screenshots/pt/04-modo-pro.png" width="160" alt="Modo Pro">
  <img src="appstore%20screenshots/pt/05-nitidez.png" width="160" alt="Nitidez">
</p>

## Principais funcionalidades

- Dois modos: **Modo Rua** (ágil, quase sem interface, prioridade de obturador com ISO automático) e **Modo Pro** (controle manual de ISO, obturador, exposição, foco e balanço de branco).
- Receitas de cor e de preto e branco inspiradas em simulações de filme, aplicadas em tempo real no visor e na captura, além da receita Neutra (sem filtro).
- Seletor de distância focal (28, 35 e 40 mm) no Modo Rua.
- Disparo pelo botão na tela (no toque) ou pelos botões de volume; captura silenciosa por padrão.
- Atalho de câmera na Tela de Bloqueio e Quick Action no ícone do app.
- Fotos respeitam a orientação do aparelho (a interface segue em retrato).
- Interface em português e inglês.
- 100% offline, sem conta, sem backend. 10 fotos grátis para experimentar; depois, compra única.

## Stack técnica

- Swift + SwiftUI, iOS 17.0+ (iPhone, retrato)
- SwiftData (persistência local — `configuracao_usuario`, `receita`)
- AVFoundation (captura, controle manual, descoberta de lentes)
- Core Image + MetalKit (pipeline das receitas em tempo real)
- LockedCameraCapture e WidgetKit/AppIntents (câmera na Tela de Bloqueio e controles, iOS 18+)
- StoreKit 2 (compra única não-consumível)
- XcodeGen (`project.yml` gera o projeto Xcode)

## Como foi construído

Desenvolvido com Claude (Anthropic) a partir de uma especificação SDD: [spec.md](spec.md). As seções 0–29 descrevem o escopo original da v1.0; a seção 30 registra o estado atual, o changelog e os mecanismos que não podem ser quebrados numa manutenção. O sistema como implementado está em [DOCUMENTACAO-TECNICA.md](DOCUMENTACAO-TECNICA.md), e o modelo de dados em [`modelo-app-camera-rua.dbml`](modelo-app-camera-rua.dbml).

O repositório não tem testes automatizados; a validação de câmera e captura é feita em aparelho físico.

## Status

Publicado na App Store (iOS) e na Google Play (Android). A versão Android fica em um repositório separado.

## Licença

O código está disponível apenas para leitura e estudo. Veja [LICENSE](LICENSE).

## Contribuições

Issues são bem-vindas; pull requests não são aceitos. Veja [CONTRIBUTING.md](CONTRIBUTING.md).

## Como rodar

Pré-requisitos: Xcode 26+, [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

```bash
# gera o .xcodeproj a partir do project.yml (fonte de verdade)
xcodegen generate

# abre no Xcode
open ISeeLife.xcodeproj
```

O esquema `ISeeLife` já vem com o `ISeeLife.storekit` configurado para testar o paywall em sandbox. Rode em **aparelho físico** para validar câmera e captura — o simulador não expõe câmera.

### Documentos

- `spec.md` — especificação do produto (seção 30 = estado atual).
- `DOCUMENTACAO-TECNICA.md` — documentação técnica da implementação.
- `modelo-app-camera-rua.dbml` — modelo de dados.
- `prints/` e `appstore screenshots/` — telas do app.

---

Feito pela [Dab Lab](https://www.dablab.com.br/) — product studio de software e IA que constrói apps para pequenas empresas, startups e áreas dentro de grandes empresas, partindo de uma especificação (Spec-Driven Development) e com as disciplinas de engenharia de software robusta.
