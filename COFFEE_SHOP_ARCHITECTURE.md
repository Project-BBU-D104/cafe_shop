# Coffee Shop Management API

This document defines the Laravel API and database for the coffee-shop
assignment. It supports the Flutter demo in `FLUTTER_ARCHITECTURE.md`.

## Scope

Required:

1. Login, logout, and role-based access.
2. Categories, products, variants, and availability.
3. Ingredients, recipes, stock movements, and low-stock state.
4. Tables, customers, orders, payments, and order-status changes.
5. Staff, shifts, shop settings, and three basic sales reports.

The application has one shop. Keep `shop_id` for ownership checks, but do not
build branch switching or multi-branch administration.

Defer unless explicitly required: loyalty points, refunds, delivery
integration, receipt printing, notifications, queues, scheduled jobs, audit
log browsing, payment-provider integration, and production deployment
automation.

Assumptions: Laravel 13, PHP 8.3+, MySQL 8, and Sanctum personal access
tokens. Store money as `DECIMAL(12,2)` and calculate totals on the server.
Copy product names and prices into order items so historical orders remain
stable.

## Architecture

Use Laravel's normal structure. Add files when their feature is implemented;
do not scaffold unused layers.

```text
laravel_api/
├── app/
│   ├── Enums/
│   │   ├── OrderStatus.php
│   │   ├── OrderType.php
│   │   ├── PaymentMethod.php
│   │   ├── PaymentStatus.php
│   │   ├── StockMovementType.php
│   │   └── UserRole.php
│   ├── Http/
│   │   ├── Controllers/Api/V1/
│   │   │   ├── AuthController.php
│   │   │   ├── CatalogController.php
│   │   │   ├── InventoryController.php
│   │   │   ├── OrderController.php
│   │   │   ├── StaffController.php
│   │   │   └── ReportController.php
│   │   ├── Middleware/EnsureUserHasRole.php
│   │   ├── Requests/
│   │   │   ├── LoginRequest.php
│   │   │   ├── StoreOrderRequest.php
│   │   │   ├── UpdateOrderStatusRequest.php
│   │   │   └── StoreProductRequest.php
│   │   └── Resources/
│   │       ├── OrderResource.php
│   │       ├── ProductResource.php
│   │       └── UserResource.php
│   ├── Models/
│   │   ├── Category.php
│   │   ├── Ingredient.php
│   │   ├── InventoryMovement.php
│   │   ├── Order.php
│   │   ├── OrderItem.php
│   │   ├── Product.php
│   │   ├── ProductIngredient.php
│   │   ├── ProductVariant.php
│   │   ├── Shop.php
│   │   ├── ShopTable.php
│   │   └── User.php
│   ├── Policies/
│   │   ├── OrderPolicy.php
│   │   └── ProductPolicy.php
│   └── Services/
│       ├── InventoryService.php
│       └── OrderService.php
├── database/
│   ├── factories/
│   ├── migrations/
│   └── seeders/DatabaseSeeder.php
├── routes/api.php
└── tests/Feature/Api/V1/
```

Request flow:

```text
Controller → Form Request → optional service → Eloquent → Resource
```

| Layer | Responsibility |
|---|---|
| Controller | HTTP input/output and straightforward CRUD. |
| Form Request | Boundary validation and authorization. |
| Resource | Stable JSON; do not expose model internals. |
| Service | Transactions spanning models, such as order creation or stock changes. |
| Policy/middleware | Role and record-level authorization. |
| Model | Relationships, casts, scopes, and small invariants. |

Do not add repositories or use-case classes. Eloquent is already the
persistence layer. A service is justified only for a transaction or
multi-model business flow.

## Database conventions

- `BIGINT UNSIGNED AUTO_INCREMENT` primary keys.
- `utf8mb4` and normal Laravel timestamps.
- Foreign keys indexed; cascade only dependent detail rows.
- Soft-delete catalog and staff records when historical references matter.
- Add `shop_id` to shop-owned tables and index common shop filters.
- Use enums or constrained strings for finite states.

## Tables

### Identity and shop

`shops`

```text
id
name VARCHAR(150)
code VARCHAR(50) UNIQUE
phone, email, address nullable
tax_rate DECIMAL(5,2) default 0
currency CHAR(3) default USD
receipt_footer VARCHAR(255) nullable
timezone VARCHAR(64) default UTC
is_active BOOLEAN default true
timestamps
```

`users`

```text
id
shop_id nullable FK shops
name VARCHAR(120)
email VARCHAR(190) UNIQUE
phone VARCHAR(30) nullable
password VARCHAR(255)
role ENUM(owner, admin, manager, cashier)
is_active BOOLEAN default true
last_login_at nullable
timestamps and soft deletes
```

Install Sanctum with `php artisan install:api`; use its generated
`personal_access_tokens` migration.

### Catalog

`categories`: `id`, `shop_id`, `name`, nullable `description`, `sort_order`,
`is_active`, timestamps, soft deletes. Unique `(shop_id, name)`.

`products`: `id`, `shop_id`, `category_id`, `name`, `sku`, nullable
`description` and `image_url`, `is_available`, `sort_order`, timestamps, soft
deletes. Unique `(shop_id, sku)`.

`product_variants`: `id`, `product_id`, `name`, `sku`, `price DECIMAL(12,2)`,
`is_default`, `is_available`, timestamps. Unique `(product_id, sku)`.

`product_ingredients`: `product_variant_id`, `ingredient_id`,
`quantity DECIMAL(12,3)`, `unit`. Unique `(product_variant_id, ingredient_id)`.

### Inventory

`ingredients`: `id`, `shop_id`, `name`, nullable `sku`, `unit`,
`current_stock DECIMAL(12,3)`, `minimum_stock DECIMAL(12,3)`,
`cost_per_unit DECIMAL(12,4)`, `is_active`, timestamps, soft deletes. Unique
`(shop_id, name)`.

`inventory_movements`: `id`, `shop_id`, `ingredient_id`, `user_id`,
`type ENUM(stock_in, stock_out, adjustment, waste, order_consumption)`,
`quantity DECIMAL(12,3)`, nullable `unit_cost`, nullable reference type/id,
nullable notes, timestamps.

Low-stock state can be queried with `current_stock <= minimum_stock`; do not
create a `stock_alerts` table until the UI needs persistent acknowledgement.

### POS and orders

`shop_tables`: `id`, `shop_id`, `name`, `capacity`, `status ENUM(available,
occupied, reserved, disabled)`, timestamps. Unique `(shop_id, name)`.

`orders`:

```text
id
shop_id FK
order_number
user_id nullable FK users
customer_id nullable FK customers
table_id nullable FK shop_tables
type ENUM(dine_in, takeaway, delivery)
status ENUM(pending, preparing, completed, cancelled)
payment_method ENUM(cash, card, qr, mobile_wallet, other)
payment_status ENUM(unpaid, paid)
subtotal, discount_amount, tax_amount, total_amount DECIMAL(12,2)
nullable notes, paid_at, completed_at, cancelled_at
timestamps
```

Use unique `(shop_id, order_number)` and indexes for shop/status/date.
`delivery` may remain unused unless the assignment requires it.

`order_items`: `id`, `order_id`, `product_variant_id`, copied
`product_name`, `variant_name`, `quantity`, `unit_price`,
`discount_amount`, `line_total`, nullable notes, timestamps.

`payments`: `id`, `order_id`, `method`, `status`, `amount DECIMAL(12,2)`,
nullable transaction reference and paid time, timestamps.

`order_status_histories`: `id`, `order_id`, nullable `user_id`, `from_status`,
`to_status`, nullable note, `created_at`.

### Customers, staff, shifts, settings

`customers`: `id`, `shop_id`, nullable `user_id`, `name`, nullable phone/email,
`is_active`, timestamps, soft deletes. Index shop plus phone/email.

`staff_profiles`: `id`, unique `user_id`, unique `employee_code`, nullable
hire date, hourly rate, emergency contact, timestamps.

`shifts`: `id`, `shop_id`, `user_id`, `started_at`, nullable `ended_at`,
`opening_cash`, nullable `closing_cash`, nullable notes, timestamps.

`settings`: `id`, `shop_id`, `key`, nullable `value`, `type ENUM(string,
integer, decimal, boolean, json)`, timestamps. Unique `(shop_id, key)`.

## Relationships

```text
Shop 1──* Users, Categories, Ingredients, Tables, Customers, Orders, Shifts
Category 1──* Products 1──* ProductVariants
ProductVariant *──* Ingredient (through ProductIngredients)
Ingredient 1──* InventoryMovements
Order 1──* OrderItems, Payments, StatusHistories
Customer 1──* Orders
User 1──* Orders and Shifts
```

## Migration and seed order

1. `shops`
2. `users` and Sanctum tokens
3. `categories`, `products`, `product_variants`
4. `ingredients`, `product_ingredients`
5. `shop_tables`, `customers`, `staff_profiles`, `shifts`
6. `orders`, `order_items`, `payments`, `order_status_histories`
7. `inventory_movements`, `settings`

Seed one shop, owner, manager, cashier, categories, products with variants,
ingredients with recipes, tables, and one customer. Keep demo passwords out
of committed source; use an environment variable or generate one during
setup.

## API v1

Base URL: `/api/v1`. Protected routes use Sanctum bearer authentication.

### Authentication

| Method | URL | Purpose | Access |
|---|---|---|---|
| POST | `/auth/login` | Issue token | Public |
| POST | `/auth/logout` | Revoke current token | Authenticated |
| GET | `/auth/me` | Current user | Authenticated |

### Catalog and inventory

| Method | URL | Purpose | Roles |
|---|---|---|---|
| GET | `/categories` | Active categories | Auth |
| POST/PATCH/DELETE | `/categories[/{id}]` | Manage categories | owner, admin, manager |
| GET | `/products` | Filtered available products | Auth |
| POST/PATCH/DELETE | `/products[/{id}]` | Manage products | owner, admin, manager |
| GET | `/products/{id}` | Product detail | Auth |
| GET | `/ingredients` | Stock and low-stock state | owner, admin, manager |
| POST | `/ingredients` | Create ingredient | owner, admin, manager |
| POST | `/ingredients/{id}/movements` | Record stock movement | owner, admin, manager |
| GET | `/inventory/movements` | Movement history | owner, admin, manager |

### POS

| Method | URL | Purpose | Roles |
|---|---|---|---|
| GET | `/tables` | Table availability | Auth |
| PATCH | `/tables/{id}/status` | Update table status | owner, admin, manager, cashier |
| GET | `/orders` | Paginated orders scoped to shop/role | Auth |
| POST | `/orders` | Create order | owner, admin, manager, cashier |
| GET | `/orders/{id}` | Order detail | Auth |
| PATCH | `/orders/{id}/status` | Valid status transition | owner, admin, manager, cashier |
| POST | `/orders/{id}/pay` | Record payment | owner, admin, manager, cashier |
| POST | `/orders/{id}/cancel` | Cancel order | owner, admin, manager |
| GET/POST | `/customers[/{id}]` | Search/register customers | owner, admin, manager, cashier |

### Staff and reports

| Method | URL | Purpose | Roles |
|---|---|---|---|
| GET/POST | `/staff` | List/create staff | owner, admin |
| PATCH/DELETE | `/staff/{id}` | Update/deactivate staff | owner, admin |
| POST | `/shifts/start` | Start shift | cashier, manager |
| POST | `/shifts/{id}/close` | Close shift | cashier, manager |
| GET | `/shifts` | Shift history | owner, admin, manager |
| GET | `/reports/sales` | Sales by date range | owner, admin, manager |
| GET | `/reports/best-sellers` | Best sellers | owner, admin, manager |
| GET | `/reports/staff-revenue` | Revenue by staff | owner, admin, manager |
| GET/PATCH | `/settings` | Read/update settings | owner, admin |

## Request and response contract

Login:

```json
{
  "email": "cashier@example.test",
  "password": "secret"
}
```

```json
{
  "data": {
    "token": "sanctum-token",
    "user": { "id": 4, "name": "Front Counter", "role": "cashier", "shop_id": 1 }
  }
}
```

Create order:

```json
{
  "type": "dine_in",
  "table_id": 3,
  "payment_method": "cash",
  "items": [
    { "product_variant_id": 12, "quantity": 2 },
    { "product_variant_id": 18, "quantity": 1 }
  ]
}
```

The server verifies that variants belong to the current shop and are
available, then recalculates prices, tax, discounts, and totals. The client
never supplies the final total as truth.

Successful responses use:

```json
{ "data": {}, "meta": {} }
```

Paginated responses add `current_page`, `per_page`, and `total` to `meta`.

Errors use:

```json
{
  "message": "The given data was invalid.",
  "errors": { "items.0.quantity": ["The quantity must be at least 1."] },
  "code": "VALIDATION_ERROR"
}
```

Use `401` unauthenticated, `403` forbidden, `404` missing, `409` state
conflict, `422` validation, `429` throttled, and `500` only for unexpected
failures. Never return stack traces, passwords, or tokens in errors.

## Validation, authorization, and transactions

- Validate every write with a Form Request.
- Use enum rules for finite states.
- Scope every query and route-model lookup to the current shop.
- Use policies for record ownership and middleware for role capability.
- Wrap order creation, payment, status changes, and stock deduction in
  `DB::transaction()`.
- Lock stock rows with `lockForUpdate()` before changing quantities.
- Permit only:

```text
pending → preparing → completed
pending/preparing → cancelled
```

When creating an order:

1. Load available variants for the current shop.
2. Calculate each line and the subtotal server-side.
3. Apply the shop tax rate and bounded discount.
4. Create the order and snapshot items in one transaction.
5. Deduct recipe ingredients only at the chosen business event (normally
   completion or payment), consistently across the API.

## Minimal implementation example

Order creation is the only flow that needs a service:

```php
final class OrderService
{
    public function create(array $data, User $user): Order
    {
        return DB::transaction(function () use ($data, $user): Order {
            $variants = ProductVariant::query()
                ->with('product')
                ->whereIn('id', collect($data['items'])->pluck('product_variant_id'))
                ->where('is_available', true)
                ->whereHas('product', fn ($query) => $query
                    ->where('shop_id', $user->shop_id)
                    ->where('is_available', true))
                ->lockForUpdate()
                ->get()
                ->keyBy('id');

            abort_if($variants->count() !== count($data['items']), 422,
                'One or more product variants are unavailable.');

            $subtotal = 0;
            $items = [];
            foreach ($data['items'] as $input) {
                $variant = $variants[$input['product_variant_id']];
                $lineTotal = $variant->price * $input['quantity'];
                $subtotal += $lineTotal;
                $items[] = [
                    'product_variant_id' => $variant->id,
                    'product_name' => $variant->product->name,
                    'variant_name' => $variant->name,
                    'quantity' => $input['quantity'],
                    'unit_price' => $variant->price,
                    'line_total' => $lineTotal,
                ];
            }

            $discount = min((float) ($data['discount_amount'] ?? 0), $subtotal);
            $tax = round(($subtotal - $discount) * ($user->shop->tax_rate / 100), 2);
            $order = $user->shop->orders()->create([
                ...collect($data)->except('items', 'discount_amount')->all(),
                'user_id' => $user->id,
                'order_number' => 'BB-' . now()->format('YmdHisv'),
                'status' => 'pending',
                'payment_status' => 'unpaid',
                'subtotal' => $subtotal,
                'discount_amount' => $discount,
                'tax_amount' => $tax,
                'total_amount' => $subtotal - $discount + $tax,
            ]);
            $order->items()->createMany($items);
            return $order->load('items');
        });
    }
}
```

The production implementation must still guarantee a unique order number
with a database constraint and retry strategy; the timestamp above is only a
compact example.

## Testing and implementation order

Test the behavior that protects the assignment:

- Login/logout and role denial.
- Catalog CRUD and shop scoping.
- Order totals, unavailable variants, and duplicate-safe creation.
- Payment and valid/invalid status transitions.
- Stock deduction and low-stock queries.
- Report date filters.

Use `RefreshDatabase`, factories, and feature tests for endpoints. A small
unit test for order calculation is enough; do not test every accessor or
static layout.

Implement in this order:

1. Sanctum, MySQL, shop/users/roles, and seeded login.
2. Catalog and authorization.
3. Ingredients, recipes, movements, and low-stock queries.
4. Tables, customers, orders, payments, status history, and stock use.
5. Staff, shifts, settings, and reports.
6. Feature tests, then connect Flutter.

For the assignment, local setup only requires:

```text
php artisan migrate:fresh --seed
php artisan test
```

Add deployment hardening, queues, schedulers, audit logs, backups, and CI
only if they become evaluated requirements.
