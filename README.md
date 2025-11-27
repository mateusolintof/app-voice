# PocketMind - Sua Assistente Pessoal de Bolso

PocketMind é um aplicativo iOS nativo desenvolvido para ser sua assistente pessoal inteligente. Utilizando o poder da Inteligência Artificial de ponta, ele transforma sua voz em ações, permitindo capturar ideias, organizar sua agenda e gerenciar projetos com facilidade.

## 🚀 Funcionalidades Principais

### 🎙️ Gravação e Transcrição Perfeita
- **Gravação de Alta Qualidade**: Capture áudios cristalinos diretamente no app.
- **Transcrição Automática (Whisper)**: Utiliza o modelo OpenAI Whisper para transcrever seus áudios com precisão humana, suportando múltiplos idiomas e sotaques.

### 🧠 Inteligência Artificial Avançada (GPT-4o)
- **Chat Interativo**: Converse com sua assistente sobre seus áudios ou qualquer outro assunto.
- **Memória de Contexto**: A IA lembra do que foi conversado anteriormente para oferecer respostas mais relevantes.
- **Ações de Texto**:
  - **Resumir**: Obtenha os pontos chave de áudios longos.
  - **Melhorar**: Reescreva textos para torná-los mais profissionais ou concisos.
  - **Gerar Contexto**: Extraia informações estruturadas para usar como prompts.

### 🔗 Integrações Poderosas
- **Google Calendar**: Crie eventos e reuniões na sua agenda apenas com comandos de voz (ex: "Marcar reunião com time amanhã às 14h").
- **Linear**: Gerencie seus projetos criando tarefas e issues diretamente pelo app (ex: "Criar tarefa para corrigir bug na tela de login").

## 🛠️ Tecnologias Utilizadas

- **Linguagem**: Swift 5.9+
- **Interface**: SwiftUI (Design System Premium & Dark Mode)
- **Arquitetura**: MVVM (Model-View-ViewModel)
- **IA Core**: OpenAI API (Whisper-1, GPT-4o)
- **Gerenciamento de Projeto**: XcodeGen (Geração dinâmica de `.xcodeproj`)
- **Networking**: URLSession com Concorrência Swift (Async/Await)

## 📋 Pré-requisitos

Para rodar este projeto, você precisará de:
- Mac com macOS Sonoma ou superior.
- Xcode 15 ou superior.
- [Homebrew](https://brew.sh/) instalado.
- **XcodeGen** (para gerar o projeto):
  ```bash
  brew install xcodegen
  ```
- Chaves de API (API Keys) para:
  - OpenAI (Obrigatório)
  - Google Cloud (Opcional - para Calendar)
  - Linear (Opcional - para Gestão de Projetos)

## 🚀 Como Rodar o Projeto

1. **Clone ou Baixe o Repositório**
   Navegue até a pasta do projeto no seu terminal.

2. **Gere o Arquivo do Projeto**
   O projeto não inclui o arquivo `.xcodeproj` no repositório para evitar conflitos. Gere-o com o comando:
   ```bash
   xcodegen generate
   ```
   Isso criará o arquivo `PocketMind.xcodeproj`.

3. **Abra no Xcode**
   Abra o arquivo `PocketMind.xcodeproj` gerado.

4. **Configure as Assinaturas (Signing)**
   No Xcode, vá em `PocketMind` (Target) -> `Signing & Capabilities` e selecione seu Time de Desenvolvimento.

6. **Execute**
   Selecione um simulador (recomendado: iPhone 15 Pro) ou seu dispositivo físico e pressione `Cmd + R`.

## 📱 Testando no iPhone Físico (iOS 16+)

Para rodar o app no seu iPhone (ex: iPhone 13 Pro com iOS 18), siga estes passos extras de segurança da Apple:

1. **Ative o Modo Desenvolvedor**:
   - No iPhone, vá em **Ajustes** > **Privacidade e Segurança**.
   - Role até o fim e ative **Modo Desenvolvedor**.
   - Reinicie o iPhone quando solicitado.

2. **Confie no Desenvolvedor**:
   - Ao tentar abrir o app pela primeira vez, você verá um erro de "Desenvolvedor Não Confiável".
   - Vá em **Ajustes** > **Geral** > **VPN e Gerenciamento de Dispositivo**.
   - Toque no seu e-mail de desenvolvedor e selecione **Confiar**.

## 🍎 Publicando na App Store

Para levar seu app ao público, o processo envolve:

1. **Apple Developer Program**:
   - É necessário se inscrever no programa (custo anual de ~$99 USD).
   - Site: [developer.apple.com/enroll](https://developer.apple.com/enroll/)

2. **App Store Connect**:
   - Crie a ficha do app (Nome, Descrição, Screenshots, Política de Privacidade).

3. **Gerar Versão Final (Archive)**:
   - No Xcode, selecione o destino **Any iOS Device (arm64)**.
   - Vá no menu **Product** > **Archive**.
   - Após a compilação, clique em **Distribute App** > **App Store Connect** > **Upload**.

4. **TestFlight & Review**:
   - Use o TestFlight para testes beta com usuários externos.
   - Envie para revisão da Apple (leva de 24h a 48h).


## ⚙️ Configuração Inicial

Ao abrir o app pela primeira vez:
1. Navegue até a aba **Settings** (Configurações).
2. Insira sua **OpenAI API Key**.
3. (Opcional) Insira as chaves para Google Calendar e Linear.
4. Volte para a aba **Assistant** e comece a usar!

---
Desenvolvido com ❤️ e IA.
