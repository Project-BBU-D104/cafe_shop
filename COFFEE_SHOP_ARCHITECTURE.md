# Coffee Shop Management System

## Delivery scope for this assignment

This document covers the **Backend and Database** for an academic coffee-shop
management assignment. It is complete enough to demonstrate authentication,
catalog management, inventory, ordering, payments, staff operation, and basic
reporting without requiring production-scale features.

### Assumptions

- Existing backend target: Laravel 13.x, PHP 8.3+, MySQL 8.0+.
- Authentication uses Laravel Sanctum personal access tokens.
- `owner` is the highest-privilege role. `admin` may manage configuration and
  staff; `manager` operates inventory and reports; `cashier` operates POS.
- Customer records, tables, shifts, and basic settings are included because
  they demonstrate realistic coffee-shop workflows.
- Monetary values are stored as `DECIMAL(12,2)` and calculated server-side.
- Product prices are versioned only by the current product/size price; historical
  order item prices are copied into `order_items`.
- One shop is assumed for the assignment. Keep `shop_id` where it is useful for
  ownership checks, but do not implement multi-branch administration.

### Assignment boundary

Implement these features:

1. Login/logout and role-based access.
2. Categories, products, product variants, and availability.
3. Ingredients, stock movements, and low-stock alerts.
4. Tables, customers, orders, payments, and order status changes.
5. Staff profiles, cashier shifts, shop settings, and three basic sales
   reports.

Defer these features unless the assignment requirements explicitly ask for
them: customer loyalty points, audit-log browsing, refunds, delivery
integration, receipt printing, notifications, queues, scheduled jobs,
multi-branch administration, and payment-provider integration. The related
tables are documented as extension points, not work that must be completed
before the core demo works.

## 1. Backend project structure

Use Laravel's standard structure and add a class only when the feature needs
The tree below shows the **representative assignment structure**, not every
possible Laravel class. Add a model, request, resource, or migration when its
feature is implemented.

The normal request flow is:

```text
Controller -> Form Request -> Service (only for multi-step work) -> Eloquent model -> Resource
```

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

### Layer responsibilities

| Layer | Responsibility |
|---|---|
| Controller | HTTP input/output; call Eloquent directly for straightforward CRUD. |
| Form Request | Authorization and validation at the trust boundary. |
| Resource | Stable JSON representation; never expose model internals. |
| Service | A transaction or business flow spanning models, such as creating an order or updating stock. |
| Policy/Middleware | Role and record-level authorization. |
| Model | Relationships, casts, scopes, and small invariants. |

Do not add repositories: Eloquent already provides the query and persistence
layer. Keep customer, shift, settings, and report code in the existing
controllers unless a transaction or multi-model business flow needs a service.
Loyalty, receipts, commands, audit browsing, and provider integrations are
extension work, not required assignment structure.

## 2. MySQL database schema

### Common conventions

- Primary keys: `BIGINT UNSIGNED AUTO_INCREMENT`.
- Foreign keys: `BIGINT UNSIGNED`, indexed, `ON DELETE CASCADE` only for
  dependent detail rows.
- Timestamps: `created_at`, `updated_at`; use `softDeletes()` for catalog and
  staff records where history matters.
- Use `utf8mb4` and `utf8mb4_unicode_ci`.
- Add `shop_id` to shop-owned tables and index it with common filter columns.

### Identity and shop tables

#### `users`

| Column | Type | Constraints |
|---|---|---|
| id | BIGINT UNSIGNED | PK |
| shop_id | BIGINT UNSIGNED | FK shops.id, nullable for platform owner |
| name | VARCHAR(120) | required |
| email | VARCHAR(190) | unique |
| phone | VARCHAR(30) | nullable, indexed |
| password | VARCHAR(255) | required |
| role | ENUM(owner,admin,manager,cashier,customer) | indexed |
| is_active | BOOLEAN | default true |
| last_login_at | TIMESTAMP | nullable |
| remember_token | VARCHAR(100) | nullable |
| created_at/updated_at | TIMESTAMP | required |
| deleted_at | TIMESTAMP | nullable |

#### `personal_access_tokens`

Use the table generated by `php artisan install:api` / Sanctum:
`id`, `tokenable_type`, `tokenable_id`, `name`, `token`, `abilities`,
`last_used_at`, `expires_at`, `created_at`, `updated_at`, with a unique token
index and a polymorphic tokenable index.

#### `shops`

| Column | Type | Constraints |
|---|---|---|
| id | BIGINT UNSIGNED | PK |
| name | VARCHAR(150) | required |
| code | VARCHAR(50) | unique |
| phone/email/address | VARCHAR/TEXT | nullable |
| tax_rate | DECIMAL(5,2) | default 0 |
| currency | CHAR(3) | default `USD` |
| receipt_footer | VARCHAR(255) | nullable |
| timezone | VARCHAR(64) | default `UTC` |
| is_active | BOOLEAN | default true |
| created_at/updated_at | TIMESTAMP | required |

### Catalog tables

#### `categories`

`id`, `shop_id`, `name VARCHAR(100)`, `description TEXT nullable`,
`sort_order SMALLINT UNSIGNED default 0`, `is_active BOOLEAN default true`,
timestamps, soft deletes. Unique `(shop_id, name)`, index `(shop_id, is_active)`.

#### `products`

`id`, `shop_id`, `category_id`, `name VARCHAR(150)`, `sku VARCHAR(80)`,
`description TEXT nullable`, `image_url VARCHAR(500) nullable`,
`is_available BOOLEAN default true`, `sort_order SMALLINT UNSIGNED default 0`,
timestamps, soft deletes. Unique `(shop_id, sku)`, indexes on
`(shop_id, category_id, is_available)` and `name`.

#### `product_variants`

`id`, `product_id`, `name VARCHAR(80)` (for example Small/Medium/Large),
`sku VARCHAR(80)`, `price DECIMAL(12,2)`, `is_default BOOLEAN`, `is_available`,
timestamps. Unique `(product_id, sku)`, index `(product_id, is_available)`.

#### `product_ingredients`

`product_variant_id`, `ingredient_id`, `quantity DECIMAL(12,3)`,
`unit VARCHAR(20)`, composite PK/unique key
`(product_variant_id, ingredient_id)`. This is the recipe used when an order
is completed or paid.

### Inventory tables

#### `ingredients`

`id`, `shop_id`, `name VARCHAR(150)`, `sku VARCHAR(80) nullable`,
`unit VARCHAR(20)`, `current_stock DECIMAL(12,3) default 0`,
`minimum_stock DECIMAL(12,3) default 0`, `cost_per_unit DECIMAL(12,4) default 0`,
`is_active BOOLEAN default true`, timestamps, soft deletes. Unique
`(shop_id, name)`, index `(shop_id, current_stock)`.

#### `inventory_movements`

`id`, `shop_id`, `ingredient_id`, `user_id`, `type ENUM(stock_in,stock_out,
adjustment,waste,order_consumption)`, `quantity DECIMAL(12,3)`,
`unit_cost DECIMAL(12,4) nullable`, `reference_type VARCHAR(100) nullable`,
`reference_id BIGINT UNSIGNED nullable`, `notes TEXT nullable`, timestamps.
Indexes on `(ingredient_id, created_at)`, `(shop_id, type, created_at)`, and the
nullable polymorphic reference pair.

#### `stock_alerts`

`id`, `shop_id`, `ingredient_id`, `threshold DECIMAL(12,3)`,
`resolved_at TIMESTAMP nullable`, `created_at`, `updated_at`.
Unique unresolved alert per ingredient can be enforced in the service.

### POS and order tables

#### `shop_tables`

`id`, `shop_id`, `name VARCHAR(50)`, `capacity TINYINT UNSIGNED`,
`status ENUM(available,occupied,reserved,disabled)`, timestamps.
Unique `(shop_id, name)`.

#### `orders`

| Column | Type | Constraints |
|---|---|---|
| id | BIGINT UNSIGNED | PK |
| shop_id | BIGINT UNSIGNED | FK |
| order_number | VARCHAR(30) | unique per shop |
| user_id | BIGINT UNSIGNED | cashier/staff FK, nullable for customer order |
| customer_id | BIGINT UNSIGNED | nullable |
| table_id | BIGINT UNSIGNED | nullable |
| type | ENUM(dine_in,takeaway,delivery) | indexed |
| status | ENUM(pending,preparing,completed,cancelled) | indexed |
| payment_method | ENUM(cash,card,qr,mobile_wallet,other) | required |
| payment_status | ENUM(unpaid,paid,refunded,partially_refunded) | indexed |
| subtotal | DECIMAL(12,2) | required |
| discount_amount | DECIMAL(12,2) | default 0 |
| tax_amount | DECIMAL(12,2) | default 0 |
| total_amount | DECIMAL(12,2) | required |
| notes | VARCHAR(500) | nullable |
| paid_at/completed_at/cancelled_at | TIMESTAMP | nullable |
| created_at/updated_at | TIMESTAMP | required |

Indexes: unique `(shop_id, order_number)`, `(shop_id, created_at)`,
`(shop_id, status, created_at)`, `(user_id, created_at)`.

#### `order_items`

`id`, `order_id`, `product_variant_id`, `product_name VARCHAR(150)`,
`variant_name VARCHAR(80)`, `quantity UNSIGNED SMALLINT`, `unit_price`,
`discount_amount`, `line_total` as `DECIMAL(12,2)`, `notes VARCHAR(255)`,
timestamps. Keep product and variant names/prices as snapshots.

#### `payments`

`id`, `order_id`, `method`, `status`, `amount DECIMAL(12,2)`,
`transaction_reference VARCHAR(150) nullable`, `paid_at TIMESTAMP nullable`,
timestamps. Index `(order_id, status)`.

#### `order_status_histories`

`id`, `order_id`, `user_id nullable`, `from_status`, `to_status`,
`note VARCHAR(255) nullable`, `created_at`. Index `(order_id, created_at)`.

### Customers, staff, shifts, and loyalty

Customers, staff, and shifts are in scope for the assignment. Loyalty
transactions are a documented extension and can remain unimplemented.

#### `customers`

`id`, `shop_id`, `user_id nullable`, `name`, `phone nullable`, `email nullable`,
`loyalty_points UNSIGNED INT default 0`, `is_active`, timestamps, soft deletes.
Indexes on `(shop_id, phone)` and `(shop_id, email)`.

#### `loyalty_transactions`

`id`, `customer_id`, `order_id nullable`, `user_id nullable`,
`points INT` (positive earn, negative redeem), `balance_after INT`,
`reason VARCHAR(150)`, timestamps. Index `(customer_id, created_at)`.

#### `staff_profiles`

`id`, `user_id` unique, `employee_code VARCHAR(50)` unique,
`hire_date DATE nullable`, `hourly_rate DECIMAL(10,2) nullable`,
`emergency_contact VARCHAR(150) nullable`, timestamps.

#### `shifts`

`id`, `shop_id`, `user_id`, `started_at TIMESTAMP`, `ended_at nullable`,
`opening_cash DECIMAL(12,2) default 0`, `closing_cash DECIMAL(12,2) nullable`,
`notes TEXT nullable`, timestamps. Index `(user_id, started_at)` and
`(shop_id, started_at)`.

### Configuration and audit

Settings are in scope for a small shop configuration screen. Audit logs are
optional extension work for this assignment.

#### `settings`

`id`, `shop_id`, `key VARCHAR(100)`, `value TEXT nullable`,
`type ENUM(string,integer,decimal,boolean,json)`, timestamps. Unique
`(shop_id, key)`.

#### `audit_logs`

`id`, `shop_id nullable`, `user_id nullable`, `action VARCHAR(100)`,
`auditable_type`, `auditable_id`, `old_values JSON nullable`,
`new_values JSON nullable`, `ip_address VARCHAR(45) nullable`,
`user_agent VARCHAR(500) nullable`, `created_at`. Index the polymorphic
auditable pair and `(shop_id, created_at)`.

## 3. ER relationship summary

```text
Shop 1──* Users
Shop 1──* Categories 1──* Products 1──* ProductVariants
ProductVariants *──* Ingredients (through ProductIngredients)
Ingredients 1──* InventoryMovements
Ingredients 1──* StockAlerts
Shop 1──* Orders
User 1──* Orders
Customer 1──* Orders
ShopTable 1──* Orders
Order 1──* OrderItems
ProductVariant 1──* OrderItems
Order 1──* Payments
Order 1──* OrderStatusHistories
User 1──* Shifts
Customer 1──* LoyaltyTransactions
Order 1──* LoyaltyTransactions (optional)
```

## 4. Migration and seeder plan

### Migration order

1. `shops`
2. `users`, Sanctum `personal_access_tokens`
3. `categories`, `products`, `product_variants`
4. `ingredients`, `product_ingredients`
5. `shop_tables`
6. `customers`, `staff_profiles`, `shifts`
7. `orders`, `order_items`, `payments`, `order_status_histories`
8. `inventory_movements`, `stock_alerts`
9. `loyalty_transactions`, `settings`, `audit_logs`

Run `php artisan migrate` against MySQL; use `php artisan migrate:fresh
--seed` only for local development.

### Seeder order and example data

```text
DatabaseSeeder
├── RoleSeeder
├── ShopSeeder
├── UserSeeder
├── CategorySeeder
├── ProductSeeder
├── IngredientSeeder
├── RecipeSeeder
├── TableSeeder
├── CustomerSeeder
└── DemoDataSeeder
```

Example deterministic records:

```php
Shop::create([
    'name' => 'Bean & Brew',
    'code' => 'BEAN-BREW',
    'tax_rate' => 10.00,
    'currency' => 'USD',
    'timezone' => 'Asia/Phnom_Penh',
]);

User::factory()->create([
    'name' => 'Shop Owner',
    'email' => 'owner@example.test',
    'role' => UserRole::Owner,
    'shop_id' => $shop->id,
]);

Category::create(['shop_id' => $shop->id, 'name' => 'Coffee']);
Product::create([
    'shop_id' => $shop->id,
    'category_id' => $coffee->id,
    'name' => 'Cappuccino',
    'sku' => 'CAP',
    'is_available' => true,
]);
```

Do not seed production passwords from committed plaintext. Use environment
variables for a local demo password or generate a random password and print it
once during setup.

## 5. REST API v1

Base URL: `/api/v1`. All protected routes use
`Authorization: Bearer <sanctum-token>` and return JSON.

### Authentication

| Method | URL | Purpose | Auth |
|---|---|---|---|
| POST | `/auth/login` | Issue token | Public |
| POST | `/auth/logout` | Revoke current token | Authenticated |


### Category and inventory

| Method | URL | Purpose | Roles |
|---|---|---|---|
| GET | `/categories` | List active categories | Auth |
| POST | `/categories` | Create category | owner, admin, manager |
| PATCH/DELETE | `/categories/{id}` | Edit/archive category | owner, admin, manager |
| GET | `/products` | Filtered product list | Auth |
| POST | `/products` | Create product and variants | owner, admin, manager |
| GET | `/products/{id}` | Product detail | Auth |
| PATCH/DELETE | `/products/{id}` | Edit/archive product | owner, admin, manager |
| GET | `/ingredients` | Inventory list and low-stock state | owner, admin, manager |
| POST | `/ingredients` | Create ingredient | owner, admin, manager |
| POST | `/ingredients/{id}/movements` | Stock in/out/adjustment | owner, admin, manager |
| GET | `/inventory/movements` | Movement history | owner, admin, manager |
| GET | `/inventory/alerts` | Low-stock alerts | owner, admin, manager |

### POS, tables, and customers

| Method | URL | Purpose | Roles |
|---|---|---|---|
| GET | `/tables` | Table availability | Auth |
| PATCH | `/tables/{id}/status` | Occupy/release table | owner, admin, manager, cashier |
| GET | `/orders` | Paginated order history | Auth, scoped by role |
| POST | `/orders` | Create POS order | owner, admin, manager, cashier |
| GET | `/orders/{id}` | Order detail | Auth, scoped by role |
| PATCH | `/orders/{id}/status` | Transition status | owner, admin, manager, cashier |
| POST | `/orders/{id}/pay` | Record payment | owner, admin, manager, cashier |
| POST | `/orders/{id}/cancel` | Cancel order | owner, admin, manager |
| GET | `/customers` | Search customers | owner, admin, manager, cashier |
| POST | `/customers` | Register customer | owner, admin, manager, cashier |
| GET | `/customers/{id}/loyalty` | Loyalty history | owner, admin, manager, cashier |

### Staff, reports, and settings

| Method | URL | Purpose | Roles |
|---|---|---|---|
| GET/POST | `/staff` | List/create staff | owner, admin |
| PATCH/DELETE | `/staff/{id}` | Update/deactivate staff | owner, admin |
| POST | `/shifts/start` | Start cashier shift | cashier, manager |
| POST | `/shifts/{id}/close` | Close shift | cashier, manager |
| GET | `/shifts` | Shift history | owner, admin, manager |
| GET | `/reports/sales` | Daily/weekly/monthly sales | owner, admin, manager |
| GET | `/reports/best-sellers` | Best-selling products | owner, admin, manager |
| GET | `/reports/staff-revenue` | Revenue by staff | owner, admin, manager |
| GET/PATCH | `/settings` | Read/update shop settings | owner, admin |

### Request and response examples

`POST /api/v1/auth/login`

```json
{
  "email": "cashier@example.test",
  "password": "secret"
}
```

```json
{
  "data": {
    "token": "1|sanctum-token",
    "user": {
      "id": 4,
      "name": "Front Counter",
      "role": "cashier",
      "shop_id": 1
    }
  },
  "meta": {}
}
```

`POST /api/v1/orders`

```json
{
  "type": "dine_in",
  "table_id": 3,
  "payment_method": "cash",
  "discount_amount": 1.50,
  "notes": "Less ice",
  "items": [
    { "product_variant_id": 12, "quantity": 2, "notes": "Less ice" },
    { "product_variant_id": 18, "quantity": 1 }
  ]
}
```

```json
{
  "data": {
    "id": 1001,
    "order_number": "BB-20260930-001",
    "type": "dine_in",
    "status": "pending",
    "payment_status": "unpaid",
    "subtotal": "8.50",
    "discount_amount": "1.50",
    "tax_amount": "0.70",
    "total_amount": "7.70",
    "items": []
  },
  "meta": {}
}
```

## 6. API standards

### Success format

```json
{
  "data": {},
  "meta": { "current_page": 1, "per_page": 20, "total": 100 }
}
```

### Error format

```json
{
  "message": "The given data was invalid.",
  "errors": {
    "items.0.quantity": ["The quantity must be at least 1."]
  },
  "code": "VALIDATION_ERROR",
  "request_id": "01J..."
}
```

Use HTTP 401 for unauthenticated, 403 for forbidden, 404 for missing records,
409 for invalid state transitions/conflicts, 422 for validation, 429 for rate
limits, and 500 only for unexpected failures. Never return stack traces in
production.

### Validation and transactions

- Validate every request with a Form Request.
- Use enum rules for role, order type, status, and payment method.
- Verify product variants are active and belong to the current shop.
- Recalculate all prices, tax, discount, and totals on the server.
- Wrap order creation, payment, status changes, and stock deduction in
  `DB::transaction()`.
- Lock inventory rows with `lockForUpdate()` before deducting stock.
- Allow only explicit status transitions:
  `pending -> preparing -> completed`, and `pending|preparing -> cancelled`.

## 7. Complete Orders module example

### Migration: `database/migrations/xxxx_xx_xx_create_orders_table.php`

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->foreignId('shop_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('customer_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('table_id')->nullable()->constrained('shop_tables')->nullOnDelete();
            $table->string('order_number', 30);
            $table->enum('type', ['dine_in', 'takeaway', 'delivery']);
            $table->enum('status', ['pending', 'preparing', 'completed', 'cancelled'])
                ->default('pending');
            $table->enum('payment_method', ['cash', 'card', 'qr', 'mobile_wallet', 'other']);
            $table->enum('payment_status', ['unpaid', 'paid', 'refunded', 'partially_refunded'])
                ->default('unpaid');
            $table->decimal('subtotal', 12, 2);
            $table->decimal('discount_amount', 12, 2)->default(0);
            $table->decimal('tax_amount', 12, 2)->default(0);
            $table->decimal('total_amount', 12, 2);
            $table->string('notes', 500)->nullable();
            $table->timestamp('paid_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamp('cancelled_at')->nullable();
            $table->timestamps();

            $table->unique(['shop_id', 'order_number']);
            $table->index(['shop_id', 'status', 'created_at']);
            $table->index(['user_id', 'created_at']);
        });

        Schema::create('order_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained()->cascadeOnDelete();
            $table->foreignId('product_variant_id')->constrained()->restrictOnDelete();
            $table->string('product_name', 150);
            $table->string('variant_name', 80);
            $table->unsignedSmallInteger('quantity');
            $table->decimal('unit_price', 12, 2);
            $table->decimal('discount_amount', 12, 2)->default(0);
            $table->decimal('line_total', 12, 2);
            $table->string('notes', 255)->nullable();
            $table->timestamps();

            $table->index(['order_id', 'product_variant_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('order_items');
        Schema::dropIfExists('orders');
    }
};
```

### Enums

```php
<?php

namespace App\Enums;

enum OrderStatus: string
{
    case Pending = 'pending';
    case Preparing = 'preparing';
    case Completed = 'completed';
    case Cancelled = 'cancelled';
}
```

### Model: `app/Models/Order.php`

```php
<?php

namespace App\Models;

use App\Enums\OrderStatus;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Model;

class Order extends Model
{
    protected $fillable = [
        'shop_id', 'user_id', 'customer_id', 'table_id', 'order_number',
        'type', 'status', 'payment_method', 'payment_status', 'subtotal',
        'discount_amount', 'tax_amount', 'total_amount', 'notes',
        'paid_at', 'completed_at', 'cancelled_at',
    ];

    protected function casts(): array
    {
        return [
            'status' => OrderStatus::class,
            'subtotal' => 'decimal:2',
            'discount_amount' => 'decimal:2',
            'tax_amount' => 'decimal:2',
            'total_amount' => 'decimal:2',
            'paid_at' => 'datetime',
            'completed_at' => 'datetime',
            'cancelled_at' => 'datetime',
        ];
    }

    public function items(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }

    public function shop(): BelongsTo
    {
        return $this->belongsTo(Shop::class);
    }

    public function cashier(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
```

### Request: `app/Http/Requests/Orders/StoreOrderRequest.php`

```php
<?php

namespace App\Http\Requests\Orders;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreOrderRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->can('create', \App\Models\Order::class) ?? false;
    }

    protected function prepareForValidation(): void
    {
        $this->merge(['shop_id' => $this->user()->shop_id]);
    }

    public function rules(): array
    {
        return [
            'shop_id' => ['required', 'integer', 'exists:shops,id'],
            'type' => ['required', Rule::in(['dine_in', 'takeaway', 'delivery'])],
            'table_id' => [
                'nullable', 'integer',
                Rule::exists('shop_tables', 'id')->where('shop_id', $this->user()->shop_id),
                'required_if:type,dine_in',
            ],
            'customer_id' => ['nullable', 'integer', 'exists:customers,id'],
            'payment_method' => [
                'required', Rule::in(['cash', 'card', 'qr', 'mobile_wallet', 'other']),
            ],
            'discount_amount' => ['nullable', 'numeric', 'min:0'],
            'notes' => ['nullable', 'string', 'max:500'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.product_variant_id' => ['required', 'integer', 'exists:product_variants,id'],
            'items.*.quantity' => ['required', 'integer', 'min:1', 'max:99'],
            'items.*.notes' => ['nullable', 'string', 'max:255'],
        ];
    }
}
```

### Resource: `app/Http/Resources/OrderResource.php`

```php
<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class OrderResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'order_number' => $this->order_number,
            'type' => $this->type,
            'status' => $this->status->value,
            'payment_method' => $this->payment_method,
            'payment_status' => $this->payment_status,
            'subtotal' => $this->subtotal,
            'discount_amount' => $this->discount_amount,
            'tax_amount' => $this->tax_amount,
            'total_amount' => $this->total_amount,
            'notes' => $this->notes,
            'items' => OrderItemResource::collection($this->whenLoaded('items')),
            'created_at' => $this->created_at?->toISOString(),
        ];
    }
}
```

### Service: `app/Services/OrderService.php`

```php
<?php

namespace App\Services;

use App\Models\Order;
use App\Models\ProductVariant;
use Illuminate\Support\Facades\DB;

class OrderService
{
    public function create(array $data, int $userId): Order
    {
        return DB::transaction(function () use ($data, $userId): Order {
            $variants = ProductVariant::query()
                ->with('product')
                ->whereIn('id', collect($data['items'])->pluck('product_variant_id'))
                ->where('is_available', true)
                ->lockForUpdate()
                ->get()
                ->keyBy('id');

            if ($variants->count() !== count($data['items'])) {
                abort(422, 'One or more product variants are unavailable.');
            }

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
                    'notes' => $input['notes'] ?? null,
                ];
            }

            $discount = min((float) ($data['discount_amount'] ?? 0), $subtotal);
            $tax = round(($subtotal - $discount) * 0.10, 2);
            $total = $subtotal - $discount + $tax;

            $order = Order::create([
                ...collect($data)->except('items', 'discount_amount')->all(),
                'user_id' => $userId,
                'order_number' => $this->nextNumber($data['shop_id']),
                'status' => 'pending',
                'payment_status' => 'unpaid',
                'subtotal' => $subtotal,
                'discount_amount' => $discount,
                'tax_amount' => $tax,
                'total_amount' => $total,
            ]);

            $order->items()->createMany($items);

            return $order->load('items');
        });
    }

    private function nextNumber(int $shopId): string
    {
        $date = now()->format('Ymd');
        $count = Order::where('shop_id', $shopId)
            ->whereDate('created_at', today())
            ->lockForUpdate()
            ->count() + 1;

        return sprintf('BB-%s-%03d', $date, $count);
    }
}
```

### Controller: `app/Http/Controllers/Api/V1/OrderController.php`

```php
<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Orders\StoreOrderRequest;
use App\Http\Resources\OrderResource;
use App\Models\Order;
use App\Services\OrderService;
use Illuminate\Http\JsonResponse;

class OrderController extends Controller
{
    public function __construct(private readonly OrderService $orders) {}

    public function index(): JsonResponse
    {
        $orders = Order::query()
            ->where('shop_id', auth()->user()->shop_id)
            ->with('items')
            ->latest()
            ->paginate(20);

        return response()->json([
            'data' => OrderResource::collection($orders),
            'meta' => [
                'current_page' => $orders->currentPage(),
                'per_page' => $orders->perPage(),
                'total' => $orders->total(),
            ],
        ]);
    }

    public function store(StoreOrderRequest $request): OrderResource
    {
        $order = $this->orders->create($request->validated(), $request->user()->id);

        return new OrderResource($order);
    }

    public function show(Order $order): OrderResource
    {
        $this->authorize('view', $order);

        return new OrderResource($order->load('items'));
    }
}
```

### Routes: `routes/api.php`

```php
<?php

use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\OrderController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::post('auth/login', [AuthController::class, 'login'])
        ->middleware('throttle:auth');

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('auth/logout', [AuthController::class, 'logout']);
        Route::get('auth/me', [AuthController::class, 'me']);

        Route::apiResource('orders', OrderController::class)
            ->only(['index', 'store', 'show']);
    });
});
```

For production, add explicit route-model shop scoping in policies or a
`BelongsToCurrentShop` scope; never rely only on an ID in the URL.

## 8. Security and reliability

- Install Sanctum with `php artisan install:api`; use token abilities if API
  clients need narrower permissions.
- Hash passwords with Laravel's `Hash` facade; never log tokens or passwords.
- Apply `throttle:auth` to login and a general per-user/IP throttle to API
  routes.
- Validate and authorize every write; use policies for row ownership and roles
  for capability checks.
- Configure CORS to the deployed Flutter/web origins only; do not use `*` with
  credentials.
- Store uploads outside the public filesystem where possible, validate MIME,
  extension, and size, then serve through controlled URLs.
- Use HTTPS, secure environment variables, MySQL least-privilege credentials,
  encrypted backups, and rotated Sanctum tokens.
- Escape receipt/user text at rendering boundaries and use parameterized
  Eloquent/query-builder statements.
- Add audit logs for staff, settings, price, inventory, refund, and order
  status changes.

## 9. Testing strategy

### Laravel

- Feature tests: login/logout, role denial, product CRUD, order creation,
  totals, invalid status transitions, payment recording, stock deduction,
  low-stock alerts, and report date filters.
- Unit tests: `OrderService`, tax/discount calculations, order-number
  generation, and inventory rules.
- Use `RefreshDatabase` and model factories. A MySQL-compatible test database
  is useful for locking-sensitive tests but is not required for the basic demo.
- Test every endpoint's success, validation, unauthenticated, unauthorized,
  not-found, and conflict responses.

### Deployment checks

```text
php artisan test
php artisan pint --test
php artisan migrate --force
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

## 10. Assignment implementation roadmap

1. Install Sanctum, configure MySQL, and create the shop, user, and role
   migrations.
2. Implement categories, products, variants, and catalog authorization.
3. Implement ingredients, recipes, stock movements, and low-stock alerts.
4. Implement tables, customers, orders, payments, status history, and stock
   consumption.
5. Add staff profiles, shifts, settings, seeders, and the three required
   reports.
6. Add feature tests for authentication, role denial, catalog CRUD, order
   totals, stock deduction, and report filters, then connect Flutter.

Only add queues, schedulers, audit logging, CI, backups, and production
deployment hardening if the assignment explicitly evaluates them.

## 11. Naming and coding standards

- PHP classes: `PascalCase`; methods/variables: `camelCase`; database columns:
  `snake_case`.
- Controllers end in `Controller`, requests in `Request`, resources in
  `Resource`, services in `Service`, policies in `Policy`.
- Use singular model names and plural table names.
- Use enums for finite states; do not compare duplicated magic strings across
  controllers.
- Keep controllers thin and services transaction-aware.
- Return resources, not raw Eloquent models, from public API endpoints.
- Use strict types where the existing project standard permits:
  `declare(strict_types=1);`.

## 12. Deployment notes

For the assignment, local Laravel/MySQL setup and a working Flutter-to-API
connection are sufficient. The following notes are production guidance, not
additional assignment features.

### VPS

- Nginx/Apache document root must be `laravel_api/public`, never the project
  root.
- Run PHP-FPM with PHP 8.3+, MySQL 8+, and Redis if queues/cache are enabled.
- Configure a queue worker with Supervisor and a scheduler cron:
  `* * * * * php /path/artisan schedule:run`.
- Run migrations during a controlled release, cache config/routes, and restart
  workers after deployment.

### Shared hosting

- Point the domain/subdomain to `laravel_api/public`; if unavailable, keep the
  application outside `public_html` and expose only the public contents.
- Configure `.env`, writable `storage` and `bootstrap/cache`, and a cron for
  scheduled tasks. Prefer a VPS when queue workers, reports, or file uploads
  become operationally important.

### Flutter release handoff

The mobile client should use the versioned API base URL from environment
configuration, never a hardcoded local IP. The Flutter structure, package
versions, navigation flow, and product-list sample will be supplied in the
next step.
