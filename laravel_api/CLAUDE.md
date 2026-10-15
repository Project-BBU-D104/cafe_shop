# Cafe Shop

Cafe shop management app: Flutter frontend + Laravel 13 API backend (PHP 8.3, Sanctum auth).

## Repository Layout

- `laravel_api/` — this directory. Laravel API backend.
- `../frontend/` — Flutter app consuming the API.
- `../API_V1.md` — hand-maintained API docs. Keep in sync when adding/changing v1 endpoints.
- `../COFFEE_SHOP_ARCHITECTURE.md`, `../FLUTTER_ARCHITECTURE.md` — design docs.
- @AGENTS.md — authoritative Laravel/Boost guidelines; read it too.

## Commands (from `laravel_api/`)

- `composer run dev` — server + queue + logs + vite
- `php artisan test --compact` (add a path or `--filter=` to run narrowly)
- `vendor/bin/pint --dirty --format agent` — run after editing PHP

## API Conventions

- Endpoints versioned under `routes/api.php` → `App\Http\Controllers\Api\V1\` group.
- Custom `role:` middleware gates writes (`role:owner,admin,manager`); menu reads
  (`categories`, `products` index/show) stay open to any authenticated staff.
- Domain: Shop, User(roles), Category, Product, ProductVariant, Ingredient,
  ProductIngredient, StaffProfile, Shift.
