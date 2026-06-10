# Caça ao Tesouro 🏴‍☠️

**Progressive Web App (PWA) Flutter** para o jogo de Caça ao Tesouro com QR Code, voltado para crianças.

---

## Stack

| Camada | Tecnologia |
|--------|-----------|
| Frontend | Flutter (PWA) |
| Banco de dados | Firebase Firestore (tempo real) |
| Armazenamento | Firebase Storage (selfies + imagens de tesouros) |
| Câmera / QR | `image_picker` + `mobile_scanner` |

---

## Funcionalidades

### Módulo do Administrador
- **Configuração da Caçada** – define nome, imagem de capa e modo de jogo.
- **Cadastro de Tesouros** – nome + imagem; gera QR Code automaticamente.  
  O sistema exige um número **ímpar** de tesouros para facilitar o desempate.
- **Sala de Espera (Lobby)** – visualiza caçadores entrando em tempo real.  
  Botão **Iniciar Caçada** (disponível com ≥ 2 jogadores) e botão **Limpar Dados** (apaga Firestore + Storage).

### Módulo do Caçador
- **Cadastro** – nome único (sugestão automática de codinome) + selfie obrigatória.
- **Sala de Espera** – redireciona automaticamente quando o admin inicia.
- **Tela Principal** – grade visual dos tesouros coletados + botão de leitura de QR Code.
- **Scanner QR** – feedback imediato: ✅ coletado / ❌ já coletado.

### Telas Compartilhadas
- **Placar em Tempo Real** – lista ordenada por pontuação + desempate por timestamp.
- **Pódio** – exibido automaticamente ao término do jogo (1º, 2º e 3º com selfie).

---

## Modos de Jogo

| Modo | Comportamento |
|------|--------------|
| **Cumulativo** | Todos os caçadores podem coletar o mesmo tesouro. |
| **Diferencial** | Cada tesouro só pode ser coletado por um caçador. |

---

## Critério de Desempate

Em caso de empate na quantidade de tesouros coletados, o sistema usa o **timestamp da última coleta** — quem coletou seu último tesouro *primeiro* fica em posição superior no placar.

---

## Configuração Firebase

1. Crie um projeto no [Firebase Console](https://console.firebase.google.com/).
2. Ative **Firestore Database** e **Firebase Storage**.
3. Registre um app **Web** no projeto Firebase.
4. Copie as credenciais e substitua os valores em `lib/firebase_options.dart`.

> **Recomendado (automático):** use a CLI do FlutterFire:
> ```bash
> dart pub global activate flutterfire_cli
> flutterfire configure
> ```
> Isso regenera `lib/firebase_options.dart` automaticamente.

5. Faça deploy das regras de segurança:
   ```bash
   firebase deploy --only firestore:rules,storage
   ```

---

## Como Executar

```bash
# Instalar dependências
flutter pub get

# Rodar em modo web (dev)
flutter run -d chrome

# Build para produção (PWA)
flutter build web --release

# Deploy no Firebase Hosting
firebase deploy --only hosting
```

---

## Estrutura do Projeto

```
lib/
├── main.dart               # Ponto de entrada + inicialização Firebase
├── firebase_options.dart   # Credenciais Firebase (substitua pelos seus)
├── app_router.dart         # Rotas GoRouter
├── app_theme.dart          # Tema Material 3
├── models/
│   ├── hunt.dart           # Modelo da caçada
│   ├── treasure.dart       # Modelo do tesouro
│   └── hunter.dart         # Modelo do caçador
├── services/
│   ├── hunt_service.dart   # CRUD Firestore + Storage + lógica de jogo
│   └── hunt_provider.dart  # Provider reativo da caçada ativa
└── screens/
    ├── home_screen.dart
    ├── admin/
    │   ├── admin_setup_screen.dart      # Configuração da caçada
    │   ├── admin_treasures_screen.dart  # Gestão de tesouros
    │   └── admin_lobby_screen.dart      # Sala de espera + controles
    ├── hunter/
    │   ├── hunter_register_screen.dart  # Cadastro + selfie
    │   ├── hunter_waiting_screen.dart   # Sala de espera
    │   └── hunter_main_screen.dart      # Inventário + scanner QR
    └── common/
        ├── leaderboard_screen.dart      # Placar em tempo real
        └── podium_screen.dart           # Pódio final
```

---

## Modelo de Dados Firestore

```
hunts/{huntId}
  name            String
  mode            "cumulative" | "differential"
  status          "waiting" | "active" | "finished"
  totalTreasures  Int (ímpar)
  coverImageUrl   String?

  treasures/{treasureId}
    name        String
    imageUrl    String?
    isAvailable Bool

  hunters/{hunterId}
    name                  String (único)
    selfieUrl             String
    collectedCount        Int
    lastCaptureTimestamp  Timestamp
    collectedTreasures    Array<String>
```
