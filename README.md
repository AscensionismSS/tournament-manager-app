# Tournament Creator - Frontend Web & Desktop

Plataforma profissional de gestão de campeonatos de esports, torneios de Dota 2, draft de jogadores em tempo real (via SignalR) e acompanhamento de fases de grupos e playoffs.

---

## 🚀 Tecnologias

- **Framework:** [Flutter](https://flutter.dev) (Web & Desktop)
- **Roteamento:** [GoRouter](https://pub.dev/packages/go_router) com Path URL Strategy (URLs limpas sem `#`)
- **Comunicação em Tempo Real:** [SignalR Core](https://pub.dev/packages/signalr_core)
- **Tema & Design System:** Dark Theme Arena & Aegis Gold (`AppColors`, `AppText`, `AppTheme`)
- **Arquitetura:** Feature-First, UI Passiva (Dumb UI / Server-Driven State) e separação rígida de camadas (View / Controller / DTO)

---

## 📦 Estrutura de Pastas

```
lib/
├── core/
│   ├── constants/       # Constantes globais e chaves de storage
│   ├── feedback/        # Sistema de notificações flutuantes (AppFeedback)
│   ├── network/         # Http client, interceptors de token e ApiEndpoints
│   ├── shared_widgets/  # Componentes globais reutilizáveis do Design System
│   ├── theme/           # Tokens de cores (AppColors), tipografia e tema
│   └── utils/           # Formatadores e validadores puros
├── features/
│   ├── admin/           # Telas e gestão administrativa (convites, logs, segurança)
│   ├── auth/            # Autenticação, login e registro com convite
│   ├── draft/           # Sala de Draft de Jogadores em tempo real (SignalR)
│   ├── profile/         # Perfil do jogador, ranks e vínculo com Steam
│   └── tournaments/     # Listagem, detalhes, grupos, chaveamento e partidas
└── main.dart            # Ponto de entrada com usePathUrlStrategy()
```

---

## 🛠️ Como Executar Localmente

### Pré-requisitos
- Flutter SDK (versão 3.24 ou superior)
- Google Chrome instalado

### Instalação de dependências
```bash
flutter pub get
```

### Executar em modo desenvolvimento
```bash
flutter run -d chrome
```

---

## 🌐 Configuração de Ambiente

Por padrão, a aplicação se conecta à API local em `http://localhost:5000/api/v1` e ao Hub do SignalR em `http://localhost:5000/hubs/tournament-draft`.

Para apontar para o servidor de produção, defina a URL base via `--dart-define` ou crie seu arquivo `.env`:

```bash
flutter run -d chrome --dart-define=API_URL=https://api.seutorneio.com.br
```

---

## 🧪 Testes e Qualidade de Código

Para executar a suite de testes unitários e de widgets:
```bash
flutter test
```

Para validar a integridade e análise estática:
```bash
flutter analyze --fatal-infos
```

---

## 🚢 Build para Produção

Para gerar o bundle otimizado para deploy web:
```bash
flutter build web --release
```

Os arquivos estáticos prontos para publicação estarão localizados em `build/web/`.
