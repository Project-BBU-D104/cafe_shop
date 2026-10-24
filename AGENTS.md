# Repository Guidelines

## Project Structure

This repository pairs a Flutter/Dart client in `frontend/` with a Laravel/PHP API in `laravel_api/`. Flutter screens, controllers, services, routes, and shared widgets live under `frontend/lib/`; image, icon, and font files are in `frontend/assets/`, with Dart tests in `frontend/test/`. Laravel endpoints are in `laravel_api/routes/`; application code is grouped under `app/`, migrations and seed data under `database/`, and PHPUnit tests under `tests/`. Root architecture and API documents describe the broader design. Follow `laravel_api/AGENTS.md` for backend-specific rules.

## Build, Test, and Development

Run package commands from the matching directory:

- `cd frontend; flutter pub get` installs Dart dependencies; `flutter run -d chrome` launches the app in Chrome (the project’s web test target).
- `cd frontend; flutter analyze` runs configured Flutter lints; `flutter test` runs Dart tests.
- `cd laravel_api; composer install` installs PHP dependencies; copy `.env.example` to `.env`, configure the database, then run `php artisan key:generate` and `php artisan migrate --seed` for local setup.
- `cd laravel_api; php artisan serve` starts the API; `php artisan test` runs the PHPUnit suite; `vendor/bin/pint` formats PHP.

## Style and Naming

Match nearby code and keep changes within the existing feature structure. Use Dart's standard formatting (`dart format`) and configured `flutter_lints`; name Dart files in `snake_case.dart`, types in `UpperCamelCase`, and members in `lowerCamelCase`. Use Laravel conventions: `StudlyCase` classes, `snake_case` database fields, and descriptive request, resource, and test names. Run Pint for PHP formatting. Avoid adding dependencies unless the existing packages cannot meet the need.

## Tests

Add focused regression coverage for behavior changes. Flutter tests belong in `frontend/test/` and use `*_test.dart`; run them with `flutter test`. API tests use PHPUnit in `laravel_api/tests/Feature/` or `Unit/`; name files `*Test.php` and run the relevant file with `php artisan test tests/Feature/...` or the full suite with `php artisan test`. No repository-wide coverage threshold is configured.

## Commits and Pull Requests

Recent commits use short imperative summaries, sometimes with Conventional Commit prefixes such as `feat:`. Prefer `type: concise action` (for example, `fix: validate order payment status`). PRs should explain user-visible and API changes, list verification commands and results, link related work, and include screenshots for UI changes. Call out database or environment configuration changes explicitly; never include secrets.

## Configuration

Keep credentials in local environment files and out of commits. Use `laravel_api/.env.example` as the backend template; configure frontend environment values in its existing asset/config setup. Coordinate API changes with the Flutter client and update `API_V1.md` when endpoint behavior changes.
