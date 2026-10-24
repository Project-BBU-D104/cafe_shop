# Coffee Shop Management API

This document defines the Laravel API and database for the coffee-shop
assignment. It supports the Flutter demo in `FLUTTER_ARCHITECTURE.md`.

## Scope

Required:

1. Login, logout, and role-based access.
2. Categories, products, variants, and availability.
3. Ingredients, recipes, stock movements, and low-stock state.
4. Tables, orders, payments, and order-status changes.
5. Staff, shifts, shop settings, and three basic sales reports.

The application has one shop. Keep `shop_id` for ownership checks, but do not
build branch switching or multi-branch administration.

Defer unless explicitly required: loyalty points, refunds, delivery
integration, receipt printing, notifications, queues, scheduled jobs, audit
log browsing, payment-provider integration, and production deployment
automation.

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
│   │   │   ├── CategoryController.php
│   │   │   ├── ProductController.php
│   │   │   ├── ProductVariantController.php
│   │   │   ├── ProductIngredientController.php
│   │   │   ├── IngredientController.php
│   │   │   ├── InventoryMovementController.php
│   │   │   ├── ShopTableController.php
│   │   │   ├── OrderController.php
│   │   │   ├── PaymentController.php
│   │   │   ├── StaffController.php
│   │   │   ├── ShiftController.php
│   │   │   ├── SettingController.php
│   │   │   └── ReportController.php
│   │   ├── Middleware/EnsureUserHasRole.php
│   │   ├── Requests/
│   │   │   ├── LoginRequest.php
│   │   │   ├── StoreCategoryRequest.php
│   │   │   ├── StoreProductRequest.php
│   │   │   ├── StoreProductIngredientRequest.php
│   │   │   ├── StoreProductVariantRequest.php
│   │   │   ├── StoreIngredientRequest.php
│   │   │   ├── StoreInventoryMovementRequest.php
│   │   │   ├── StoreOrderRequest.php
│   │   │   ├── StorePaymentRequest.php
│   │   │   ├── StoreStaffRequest.php
│   │   │   ├── UpdateStaffRequest.php
│   │   │   ├── UpdateCategoryRequest.php
│   │   │   ├── UpdateProductRequest.php
│   │   │   ├── UpdateProductVariantRequest.php
│   │   │   ├── UpdateOrderStatusRequest.php
│   │   │   └── UpdateSettingsRequest.php
│   │   └── Resources/
│   │       ├── OrderResource.php
│   │       ├── CategoryResource.php
│   │       ├── ProductResource.php
│   │       ├── ProductVariantResource.php
│   │       ├── IngredientResource.php
│   │       ├── InventoryMovementResource.php
│   │       ├── ShopTableResource.php
│   │       ├── PaymentResource.php
│   │       ├── StaffResource.php
│   │       ├── StaffProfileResource.php
│   │       ├── ShiftResource.php
│   │       ├── SettingResource.php
│   │       ├── ReportResource.php
│   │       └── UserResource.php
│   ├── Models/
│   │   ├── Category.php
│   │   ├── Ingredient.php
│   │   ├── InventoryMovement.php
│   │   ├── Order.php
│   │   ├── OrderItem.php
│   │   ├── OrderStatusHistory.php
│   │   ├── Payment.php
│   │   ├── Product.php
│   │   ├── ProductIngredient.php
│   │   ├── ProductVariant.php
│   │   ├── Setting.php
│   │   ├── Shift.php
│   │   ├── Shop.php
│   │   ├── ShopTable.php
│   │   ├── StaffProfile.php
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

Keep the stack simple:

- Controller: HTTP in/out and basic CRUD.
- Form Request: validation and auth boundary.
- Resource: stable JSON response shape.
- Service: only for multi-model transactions such as order creation or stock updates.
- Policy/middleware: role and ownership checks.
- Model: relationships, casts, scopes, and local invariants.

Use one controller per resource, no repositories or use-case classes. Eloquent is the persistence layer and services are justified only for transactions or multi-model business flows.

## Database conventions

- `BIGINT UNSIGNED AUTO_INCREMENT` primary keys.
- `utf8mb4` and normal Laravel timestamps.
- Foreign keys indexed; cascade only dependent detail rows.
- Soft-delete catalog and staff records when historical references matter.
- Add `shop_id` to shop-owned tables and index common shop filters.
- Use enums or constrained strings for finite states.

## Tables

Progress: tick a table once its migration, model, and API endpoints exist.

- [x] `shops`
- [x] `users`
- [x] `categories`
- [x] `products` 
- [x] `product_variants`
- [x] `product_ingredients`
- [x] `ingredients`
- [x] `inventory_movements`
- [x] `orders`
- [x] `order_items`
- [x] `payments`
- [x] `order_status_histories`
- [x] `staff_profiles`
- [x] `shifts`
- [ ] `settings`
- [ ] `shop_tables` (optional)

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
`is_active`, timestamps. Unique `(shop_id, name)`. No soft deletes: a trashed
row would keep reserving the name and block re-creating it. Since
`products.category_id` references this table, DELETE on a category that still
has products returns 409 rather than cascading.

`products`: `id`, `shop_id`, `category_id`, `name`, nullable
`description` and `image_path`, `is_available`, `sort_order`, timestamps, soft
deletes. Unique `(shop_id, name)`.

`product_variants`: `id`, `product_id`, `name`, `price DECIMAL(12,2)`,
`is_default`, `is_available`, timestamps. Unique `(product_id, name)`.

`product_ingredients`: `product_variant_id`, `ingredient_id`,
`quantity DECIMAL(12,3)`, `unit`. Unique `(product_variant_id, ingredient_id)`.

### Inventory

`ingredients`: `id`, `shop_id`, `name`, `unit`,
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

`shop_tables`: `id`, `shop_id`, `name`, `capacity`, `status ENUM(available, occupied, reserved, disabled)`, timestamps. Unique `(shop_id, name)`. (Optional)

`orders`:

```text
id
shop_id FK
order_number
user_id nullable FK users
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
`line_total`, nullable notes, timestamps.

`payments`: `id`, `order_id`, `method`, `status`, `amount DECIMAL(12,2)`,
nullable transaction reference and paid time, timestamps.

`payments` is the ledger; `orders.payment_status`, `payment_method`, and
`paid_at` are cached summaries updated in the same transaction. Never set them
independently.

`order_status_histories`: `id`, `order_id`, nullable `user_id`, `from_status`,
`to_status`, nullable note, `created_at`.
This table and `inventory_movements` are insert-only; set `UPDATED_AT = null` on
their models.

### Staff, shifts, settings

`staff_profiles`: `id`, unique `user_id`, unique `employee_code`, nullable
hire date, hourly rate, emergency contact, timestamps.

`shifts`: `id`, `shop_id`, `user_id`, `started_at`, nullable `ended_at`,
`opening_cash`, nullable `closing_cash`, nullable notes, timestamps.
A user may have at most one open shift (`ended_at IS NULL`); a second start
returns `409`.

`settings`: `id`, `shop_id`, `key`, nullable `value`, `type ENUM(string,
integer, decimal, boolean, json)`, timestamps. Unique `(shop_id, key)`.

## Relationships

```text
Shop 1──* Users, Categories, Ingredients, Tables, Orders, Shifts
Category 1──* Products 1──* ProductVariants
ProductVariant *──* Ingredient (through ProductIngredients)
Ingredient 1──* InventoryMovements
Order 1──* OrderItems, Payments, StatusHistories
User 1──* Orders and Shifts
```

## API documentation

Current test endpoints and full local URLs are documented in
[`API_V1.md`](API_V1.md). That file lists routes registered in Laravel today;
it also labels planned routes that are not available to test yet. Data model
and implementation guidance remain in this architecture document.

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
5. Deduct recipe ingredients when the order reaches `completed`; `cancelled`
   orders never deduct stock.

## Minimal implementation example

Order creation is the only flow that needs a service:

```php
final class OrderService
{
    public function create(array $data, User $user): Order
    {
        return DB::transaction(function () use ($data, $user): Order {
            $requestedItems = collect($data['items'])
                ->groupBy('product_variant_id')
                ->map(fn ($lines, $variantId) => [
                    'product_variant_id' => (int) $variantId,
                    'quantity' => $lines->sum('quantity'),
                ])
                ->values();
            $variants = ProductVariant::query()
                ->with('product')
                ->whereIn('id', $requestedItems->pluck('product_variant_id'))
                ->where('is_available', true)
                ->whereHas('product', fn ($query) => $query
                    ->where('shop_id', $user->shop_id)
                    ->where('is_available', true))
                ->lockForUpdate()
                ->get()
                ->keyBy('id');

            abort_if($variants->count() !== $requestedItems->count(), 422,
                'One or more product variants are unavailable.');

            $subtotal = 0;
            $items = [];
            foreach ($requestedItems as $input) {
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
4. Tables, orders, payments, status history, and stock use.
5. Staff, shifts, settings, and reports.
6. Feature tests, then connect Flutter.

For the assignment, local setup only requires:

```text
php artisan migrate:fresh --seed
php artisan test
```

Add deployment hardening, queues, schedulers, audit logs, backups, and CI
only if they become evaluated requirements.
