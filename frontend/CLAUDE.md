# Cafe Shop — Flutter Frontend

Consumes the Laravel API in `../laravel_api` (docs: `../API_V1.md`).

## Setup & Commands (from `frontend/`)

- Requires a `.env` file with `API_URL` (flutter_dotenv; loaded by `lib/services/api_service.dart`).
  Android emulator reaches the local API at `http://10.0.2.2:8000`.
- `flutter pub get` · `flutter run` · `flutter analyze` · `flutter test`

## Architecture

- GetX for state/routing (`lib/routes`, `lib/controllers`), get_it DI via `lib/locator.dart`
  — register new services there or they won't resolve.
- `lib/services/` = API/auth/storage clients (get_storage). `lib/screen/` = pages,
  `lib/widget/` = shared widgets, `lib/themes/` = styling.
- `lib/global.dart` + `lib/constants/` for app-wide values/enums.
- Auth tokens handled in `lib/services/auth_service.dart`; API base URL is trimmed
  of trailing slashes before use — pass paths without leading `/`.
