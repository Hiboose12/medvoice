# MedVoice Flutter

Flutter client for the [MedVoice](../medVoice) Django backend.

## Phase 3 — Patient Portal (mock data)

- Patient Dashboard with stats, recent activity, notifications
- Bottom navigation (Dashboard, Feed, Post, Profile)
- Community Feed with search, composer, and post cards
- Create Community Post (modal + dedicated tab)
- All patient data is mock — no API calls yet

**Demo login:** `patient@demo.com` / `demo123`

Seed or repair the Django demo accounts from the backend directory:

```bash
cd ../medVoice
python manage.py seed_demo_accounts
```

## Phase 1 — Foundation

This project contains the core architecture scaffold:

- Material 3 theme system (colors, typography, light/dark)
- GoRouter navigation with role-based route paths
- Provider service registration (Dio, secure storage, theme mode)
- Reusable widget library
- Network layer stubs (`DioClient`, `Endpoints`, `ApiException`)

Feature screens are **not** implemented yet — routes use `RoutePlaceholder` stubs.

## Getting started

```bash
cd medvoice_flutter
flutter pub get
flutter run
```

### Backend URL

Default: `http://10.0.2.2:8000` (Android emulator → host machine).

Override at build time:

```bash
flutter run --dart-define=BASE_URL=http://192.168.1.10:8000
```

## Project structure

```
lib/
├── main.dart
├── app/                  # App shell, router, providers
├── core/
│   ├── config/           # EnvConfig
│   ├── network/          # Dio, endpoints, exceptions
│   ├── storage/          # Secure storage
│   └── theme/            # Colors, typography, Material 3 theme
└── shared/
    └── widgets/          # Reusable UI components
```

## Dependencies

| Package | Purpose |
|---------|---------|
| `provider` | App-wide dependency injection & theme state |
| `go_router` | Declarative routing with role shells |
| `dio` | HTTP client for Django backend |
| `flutter_secure_storage` | Encrypted session/token storage |
