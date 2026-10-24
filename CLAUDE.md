# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Full-stack coffee shop management system: Flutter app (`frontend/`) + Laravel 13 API (`laravel_api/`, PHP 8.3, Sanctum tokens). Each subproject has its own CLAUDE.md with details — read the one for the directory you're working in. `laravel_api/AGENTS.md` holds authoritative Laravel/Boost guidelines.

- `API_V1.md` — hand-maintained API docs; keep in sync when adding/changing v1 endpoints.
- `COFFEE_SHOP_ARCHITECTURE.md`, `FLUTTER_ARCHITECTURE.md` — design specs.

## Commands

Backend (from `laravel_api/`):
- `composer run dev` — server + queue + logs + vite
- `php artisan test --compact` — add a path or `--filter=` to run narrowly (tests live in `tests/Feature/Api/`)
- `vendor/bin/pint --dirty --format agent` — run after editing PHP
- First-time setup: `cp .env.example .env && composer install && php artisan key:generate && php artisan migrate --seed`

Frontend (from `frontend/`):
- `flutter pub get` · `flutter run -d chrome` · `flutter analyze` — run on web/Chrome (no physical device)
- `flutter test` — all tests; `flutter test test/category_controller_test.dart` — single file
- Requires `frontend/.env` with `API_URL`; use `http://localhost:8000` for Chrome (`http://10.0.2.2:8000` is only for the Android emulator)

## Cross-cutting architecture

Request flow: Flutter screen → GetX controller (`frontend/lib/controllers/`) → service (`lib/services/main_service/`, thin HTTP wrappers over `api_service.dart`) → Laravel route (`laravel_api/routes/api.php`) → `Api\V1` controller → FormRequest validation → model or domain service (`App\Services\OrderService`, `InventoryService`) → API Resource JSON.

Authorization is role-based and enforced in `routes/api.php` via the custom `role:` middleware (`EnsureUserHasRole`):
- `role:owner,admin,manager` gates catalog/inventory writes; menu reads (categories, products, variants index/show) stay open to any authenticated staff so cashiers can take orders.
- Orders/pay/cancel are open to all authenticated staff; `staff` CRUD is `role:owner,admin`; shifts are `role:cashier,manager`.
- Because index/show are registered open first, the role-gated `apiResource` calls must use `->except(['index','show'])` — re-registering them would replace the open routes and lock cashiers out.

Flutter side: GetX handles state and routing (`lib/routes/app_pages.dart`), get_it DI is wired in `lib/locator.dart` (register new services there or they won't resolve). API base URL is trimmed of trailing slashes — pass paths without leading `/`.

Domain: Shop, User (roles), StaffProfile, Category, Product, ProductVariant, Ingredient, ProductIngredient (recipe), InventoryMovement, Order/OrderItem/Payment/OrderStatusHistory, Shift.
