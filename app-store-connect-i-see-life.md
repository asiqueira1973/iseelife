# App Store Connect — I See Life

Pacote pronto para colar no App Store Connect. App: **I See Life** — câmera de fotografia de
rua iOS, local-first, 100% offline, compra única. Bundle `com.dablab.iseelife`.

> Todos os campos com limite foram medidos com `check_limits.py` (resultado no fim do documento).

---

## 1. App Information

- **Name (≤30):** `I See Life`  *(10/30)*
- **Subtitle (≤30):** `Câmera de fotografia de rua`  *(27/30)*
- **Primary Category:** Photo & Video  *(mesmo precedente do Geara — app de foto da Dab Lab)*
- **Secondary Category:** (opcional) Lifestyle — ou deixar em branco
- **Copyright:** `© 2026 Alexandre Siqueira`
- **Bundle ID:** `com.dablab.iseelife`

---

## 2. Version Information

### Promotional Text (≤170) — *(160/170)*
```
O 1º app brasileiro de fotografia de rua. O filtro entra na hora do disparo e vira o arquivo final, sem edição depois. Rápido no Modo Rua, completo no Modo Pro.
```

### Description (≤4000) — *(1527/4000)*
> Colar como texto puro. A App Store não renderiza markdown — os blocos em MAIÚSCULAS e os
> traços "-" são intencionais (é assim que a Apple exibe listas simples).

```
O I See Life é o primeiro app brasileiro feito para fotografia de rua.

A ideia é simples: a foto sai pronta na hora. O visual é aplicado no momento do disparo e vira o arquivo final. Nada de passar horas editando depois. É a filosofia out-of-the-camera: você escolhe a receita, aponta e dispara.

RECEITAS COM CARÁTER
Comece na Neutra (a imagem crua do iPhone, sem filtro) ou escolha um dos quatro visuais, aplicados ao vivo no visor e gravados direto no JPEG:
- Classic: cores quentes, clima analógico
- Soft: suave, contido, tons de pele bonitos
- Mono: preto e branco contrastado
- Positivo: verde e saturado, cara de slide de filme

MODO RUA: UM TOQUE E ACABOU
Abriu o app, já está pronto para fotografar. Sem menu no caminho até o clique. Toque na tela para travar o foco, dispare, e a foto vai direto para a sua Fototeca. Obturador silencioso por padrão. E, no iOS 18, adicione o atalho do I See Life à Central de Controle para abrir a câmera direto da tela de bloqueio.

MODO PRO: CONTROLE TOTAL
Quando quiser mandar na câmera: ISO, velocidade do obturador, exposição, foco e white balance na mão, com zebra e focus peaking para cravar a luz e o foco. E prioridade de obturador no Modo Rua: trave em 1/250, 1/500 ou 1/1000 e congele o movimento, sem foto tremida.

100% SEU, 100% OFFLINE
Sem conta, sem cadastro, sem nuvem, sem anúncios. O app funciona inteiro sem internet e suas fotos nunca saem do seu iPhone.

PAGUE UMA VEZ
Compra única, sem assinatura. Baixe de graça, explore os modos e as receitas à vontade, e desbloqueie quando quiser salvar sua primeira foto.

Fotografia de rua é sobre estar pronto para o instante. O I See Life tira tudo da frente para você só fotografar.
```

### Keywords (≤100 **bytes**) — *(100/100)*
> Sem repetir palavras que já estão no Nome/Subtítulo (câmera, fotografia, rua) — a Apple já
> indexa essas dali.
```
street photography,filme,filtro,preto e branco,manual,obturador,foco,analogico,lomo,jpeg,fujifilm,GR
```

### What's New / Notas da versão (1.0)
```
Primeira versão do I See Life, o app de fotografia de rua com filtro na hora do disparo. Quatro receitas de cor, Modo Rua de um toque e Modo Pro com controle manual completo e prioridade de obturador. Sem assinatura, 100% offline.
```

---

## 3. App Privacy (questionário)

**Resposta: Data Not Collected.**

O app não tem backend, não tem conta, não usa Firebase/analytics/crash reporting e não envia
nenhum dado para servidor (spec seção 20). As preferências (`configuracao_usuario`) ficam só no
aparelho via SwiftData. As fotos capturadas vão direto para a Fototeca do sistema — o app não
mantém cópia própria nem sobe nada para lugar nenhum. A compra é processada 100% pela
StoreKit/App Store (o app não lida com dados de pagamento).

- **Data used to track you:** Nenhum.
- **Data linked to you:** Nenhum.
- **Data not linked to you:** Nenhum.
- **App Tracking Transparency (ATT):** não se aplica (sem SDK de anúncios, sem rastreamento).

---

## 4. URLs obrigatórias

- **Support URL:** `https://suportedablab.carrd.co/`  *(ativo padrão da Dab Lab, já aceito pela Apple)*
- **Privacy Policy URL:** o documento Notion compartilhado **"Política de Privacidade —
  Aplicativos da Dab Lab"** (link público). **Adicionar dentro dele a seção nova abaixo**,
  específica do I See Life (não reaproveitar o texto genérico — o genérico cita Firebase,
  Crashlytics e login, que este app **não** usa):

> ### I See Life
>
> **1. Coleta de Dados**
> O I See Life não coleta, transmite nem armazena dados pessoais em servidores. O app não tem
> conta, cadastro, login nem backend, e não usa Firebase, analytics ou ferramentas de crash
> reporting. As únicas informações guardadas são as suas preferências de uso (idioma, opções do
> visor, modo padrão), que ficam exclusivamente no seu iPhone.
>
> **2. Uso dos Dados**
> Suas preferências são usadas apenas para o funcionamento do app no seu aparelho. As fotos que
> você captura são salvas diretamente na Fototeca (app Fotos) do iOS; o I See Life não mantém
> cópia própria delas nem as envia para qualquer lugar.
>
> **3. Armazenamento e Segurança**
> Todos os dados ficam localmente no dispositivo e são removidos quando o app é desinstalado. O
> app funciona 100% offline e não depende de conexão com a internet.
>
> **4. Compartilhamento com Terceiros**
> Nenhum dado é compartilhado com terceiros. A compra do app é processada pela Apple via
> StoreKit; o I See Life não tem acesso a dados de pagamento. As permissões de Câmera (para o
> visor e a captura) e de Adição à Fototeca (para salvar as fotos) são usadas somente no seu
> aparelho, com a sua autorização.
>
> **5. Contato**
> Dúvidas sobre privacidade: alexandre@dablab.com.br.

---

## 5. Pricing and Availability

- **Preço da ficha:** Grátis (Free / Tier 0). A monetização é por In-App Purchase.
- **Disponibilidade:** All Countries or Regions.
- **In-App Purchase (não-consumível, único):**
  - **Reference Name:** Desbloqueio completo (compra única)
  - **Product ID:** `iseelife_desbloqueio_completo`
  - **Type:** Non-Consumable
  - **Display Name (pt-BR):** I See Life — completo
  - **Description (pt-BR):** Desbloqueie a captura de fotos com um pagamento único, sem assinatura.
  - **Preço:** ⚠️ **PENDENTE** — definir o tier na App Store Connect mais próximo de **R$ 49,90**
    (o valor R$ 49,90 está só no `.storekit` de teste; o preço real de listagem é decisão sua —
    ver seção 25 do spec / resumo de pendências abaixo).

---

## 6. App Review Information

- **Sign-in Required:** **No** (o app não tem conta/login).
- **Contact:** Alexandre da Silva de Siqueira · alexandre@dablab.com.br
- **Notes (colar):**
```
O I See Life é um app de câmera de fotografia de rua, iOS apenas, 100% offline, sem conta ou login.

COMO TESTAR A COMPRA (paywall):
O app é gratuito para abrir e explorar — dá para trocar de modo (Rua/Pro), trocar de lente e trocar de receita sem comprar. O paywall aparece apenas na PRIMEIRA vez em que se tenta salvar uma foto (ao tocar no botão de disparo). Ao concluir a compra única (ambiente Sandbox), o app é desbloqueado e a foto que motivou o paywall é salva automaticamente na Fototeca, sem precisar disparar de novo. Há botão "Restaurar compra" no paywall e nas Configurações.

PERMISSÕES:
- Câmera: pedida no onboarding, com descrição de uso no Info.plist (visor e captura).
- Adicionar à Fototeca: pedida no momento da primeira captura, com descrição de uso, apenas para salvar a foto.

PRIVACIDADE:
Não há coleta de dados. Sem backend, sem conta, sem analytics. As fotos vão direto para a Fototeca do sistema e nenhum dado sai do aparelho.

Support website: https://suportedablab.carrd.co/
Contato: alexandre@dablab.com.br
```

---

## 7. App Encryption Documentation

**Resposta: "None of the algorithms mentioned above."**

O app só faz uso de frameworks padrão da Apple (StoreKit para a compra; nenhuma chamada de rede
própria — é offline). Não implementa criptografia proprietária. → Exempt de documentação
adicional de export compliance.

---

## 8. Content Rights

**Resposta: "No, it does not contain, show, or access third-party content."**

As 4 receitas são aproximações estéticas próprias via Core Image (spec 11.2), não conteúdo
licenciado de terceiros. O app não embute fontes, imagens ou bancos de dados de terceiros. As
fotos exibidas são as que o próprio usuário captura.

---

## 9. Age Rating (expectativa)

**Esperado: 4+.**

Sem conteúdo gerado por usuário visível a terceiros, sem rede social, sem chat, sem IA
generativa, sem conteúdo adulto/violento/apostas. A classificação oficial sai do questionário
da Apple, mas tudo aponta para 4+.

---

## Medição dos limites (check_limits.py)

```
Nome:               10/30 caracteres   [OK]
Subtítulo:          27/30 caracteres   [OK]
Texto promocional: 160/170 caracteres  [OK]
Descrição:        1527/4000 caracteres [OK]
Keywords:          100/100 bytes       [OK]
Notas da versão:   230/4000 caracteres [OK]
```

---

## Pendências para você decidir antes de submeter

1. **Preço do IAP** — definir na App Store Connect o tier mais próximo de R$ 49,90 (o `.storekit`
   local usa 49,90 só para teste). É a decisão de preço da seção 25 do spec.
2. **Screenshots** — gerar no Claude Design com o `prompt-appstore-screenshots-claude-design.md`
   (1242×2688). A App Store exige screenshots de pelo menos um tamanho de iPhone.
3. **Categoria secundária** — sugeri Lifestyle (opcional); pode deixar em branco.
4. **Nome final na loja** — mantive "I See Life" (igual ao ícone/app). Se quiser adicionar
   descritor de busca no próprio Nome (ex.: "I See Life: Foto de Rua"), dá para trocar — só avisar.
5. **Termos de Uso** — não é obrigatório aqui (app sem conta; o "Apple's Standard License
   Agreement" padrão basta). Nenhuma ação necessária, a menos que você queira um próprio.
