# Profile (Perfil)

## O que e essa pasta?

Contem a **tela de configuracoes do usuario**. E onde ele configura a chave da OpenAI, ajusta o nivel de confrontacao do coach, escolhe os metodos terapeuticos e ve informacoes do app.

Pense assim: e o **"painel de controle"** do PocketMind.

---

## Como funciona?

```
Usuario abre a aba "Perfil"
       |
       v
  [ProfileView] -- carrega perfil do SwiftData
       |
       | Secao 1: Avatar (icone PM)
       | Secao 2: Chave OpenAI (SecureField + status verde/vermelho)
       | Secao 3: Perfil Terapeutico (slider + toggles de modo)
       | Secao 4: Botao "Salvar Perfil"
       | Secao 5: Sobre (versao do app)
       |
       | usuario ajusta e toca "Salvar"
       v
  [TherapyRepository.saveProfile()] -- salva no SwiftData
```

---

## Arquivo e o que faz

### ProfileView.swift
**O que e**: Uma unica View que mostra todas as configuracoes em cards empilhados (GlassCard).

**Pontos-chave**:
- Linha 6: `@AppStorage("openAIKey")` — a chave OpenAI e salva direto no UserDefaults via AppStorage. Qualquer mudanca reflete imediatamente em todo o app
- Linha 8-10: Estados locais para slider e toggles (nao sao salvos ate o usuario tocar "Salvar")
- Linha 62-92: **Secao API Key**:
  - Linha 73-78: Indicador verde/vermelho mostrando se a chave esta configurada
  - Linha 81: `SecureField` — campo que esconde o texto digitado
  - Linha 87-89: Aviso de que a chave fica apenas no dispositivo
- Linha 96-149: **Perfil Terapeutico**:
  - Linha 104-126: Slider de confrontacao (1 a 5) — controla quao direto/firme o coach e
  - Linha 131-146: Toggles para cada modo terapeutico (CBT, Estoicismo, Logoterapia, Combinado). Minimo 1 deve estar selecionado
- Linha 153-164: Botao "Salvar" com feedback visual temporario ("Salvo!")
- Linha 190-221: `saveProfile()` — cria um `TherapyProfile` e salva via `TherapyRepository`

**Detalhe importante sobre time windows (linha 201-217)**:
As janelas de horario (manha 7-11h, meio-dia 12-15h, noite 19-22h) estao **hardcoded** no `saveProfile()`. Isso significa que mesmo que o usuario queira rituais em horarios diferentes, nao tem como configurar pela UI.

---

## Onde mexer para melhorar

### Facil (poucas linhas)
- **Mostrar nome do usuario**: adicione um TextField para editar `UserDefaults.standard.string(forKey: "userName")`
- **Validar chave API**: ao salvar, faca um request de teste para a OpenAI e mostre sucesso/erro
- **Versao dinamica**: em vez de hardcodar "2.1" (linha 181), leia de `Bundle.main.infoDictionary`

### Medio (algumas horas)
- **Configurar time windows**: adicione 3 pares de DatePicker (inicio/fim) para manha, meio-dia e noite. Passe os valores para `TherapyProfile` no `saveProfile()`
- **Toggle de notificacoes**: adicione um switch "Lembretes de Ritual" que agenda notificacoes locais nos horarios dos slots
- **Exportar dados**: botao "Exportar" que gera JSON dos ultimos 90 dias via `ShareLink`
- **Tema escuro/claro**: toggle para forcar dark mode ou seguir sistema

### Avancado (1+ dia)
- **Foto de perfil**: imagem customizada com `PhotosPicker` do SwiftUI
- **Backup iCloud**: sincronizar perfil e entradas via CloudKit
- **Deletar conta/dados**: botao para apagar todos os dados do SwiftData + UserDefaults
- **Monetizacao**: secao de assinatura com StoreKit 2, removendo a necessidade do usuario ter chave propria
