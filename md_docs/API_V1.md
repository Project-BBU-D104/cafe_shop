# API v1

This is the local API test reference for the Laravel app. Start the server from
`laravel_api` with `php artisan serve`; the full base URL is
`http://127.0.0.1:8000/api/v1`.

## Request setup

Send `Accept: application/json` on every request and
`Content-Type: application/json` on requests with a JSON body. Login to get a
Sanctum token, then send `Authorization: Bearer <token>` on protected requests.

Seeded test accounts (both use password `password123`):

| Role | Email |
|---|---|
| owner | `owner@example.com` |
| cashier | `cashier@example.com` |

### Login

`POST http://127.0.0.1:8000/api/v1/auth/login`

```json
{
  "email": "owner@example.com",
  "password": "password123"
}
```

The response contains `data.token` and `data.user`. Use the token as a bearer
token for the protected endpoints below.

## Endpoints

All routes below are registered in `laravel_api/routes/api.php`.

### Authentication

| Method | Full URL | Access |
|---|---|---|
| POST | `http://127.0.0.1:8000/api/v1/auth/login` | Public |
| POST | `http://127.0.0.1:8000/api/v1/auth/logout` | Authenticated |
| GET | `http://127.0.0.1:8000/api/v1/auth/me` | Authenticated |

### Categories and products

| Method | Full URL | Access |
|---|---|---|
| GET | `http://127.0.0.1:8000/api/v1/categories` | Authenticated |
| POST | `http://127.0.0.1:8000/api/v1/categories` | owner, admin, manager |
| GET | `http://127.0.0.1:8000/api/v1/categories/{category}` | Authenticated |
| PUT/PATCH | `http://127.0.0.1:8000/api/v1/categories/{category}` | owner, admin, manager |
| DELETE | `http://127.0.0.1:8000/api/v1/categories/{category}` | owner, admin, manager |
| GET | `http://127.0.0.1:8000/api/v1/products` | Authenticated |
| POST | `http://127.0.0.1:8000/api/v1/products` | owner, admin, manager |
| GET | `http://127.0.0.1:8000/api/v1/products/{product}` | Authenticated |
| PUT/PATCH | `http://127.0.0.1:8000/api/v1/products/{product}` | owner, admin, manager |
| DELETE | `http://127.0.0.1:8000/api/v1/products/{product}` | owner, admin, manager |

### Product variants and recipe ingredients

| Method | Full URL | Access |
|---|---|---|
| GET/POST | `http://127.0.0.1:8000/api/v1/products/{product}/variants` | owner, admin, manager |
| GET | `http://127.0.0.1:8000/api/v1/products/{product}/variants/{variant}` | owner, admin, manager |
| PUT/PATCH | `http://127.0.0.1:8000/api/v1/products/{product}/variants/{variant}` | owner, admin, manager |
| DELETE | `http://127.0.0.1:8000/api/v1/products/{product}/variants/{variant}` | owner, admin, manager |
| GET/POST | `http://127.0.0.1:8000/api/v1/variants/{variant}/ingredients` | owner, admin, manager |
| PATCH/DELETE | `http://127.0.0.1:8000/api/v1/variants/{variant}/ingredients/{ingredient}` | owner, admin, manager |

### Ingredients

| Method | Full URL | Access |
|---|---|---|
| GET/POST | `http://127.0.0.1:8000/api/v1/ingredients` | owner, admin, manager |
| GET | `http://127.0.0.1:8000/api/v1/ingredients/{ingredient}` | owner, admin, manager |
| PUT/PATCH | `http://127.0.0.1:8000/api/v1/ingredients/{ingredient}` | owner, admin, manager |
| DELETE | `http://127.0.0.1:8000/api/v1/ingredients/{ingredient}` | owner, admin, manager |

### Inventory movements

| Method | Full URL | Access |
|---|---|---|
| POST | `http://127.0.0.1:8000/api/v1/ingredients/{ingredient}/movements` | owner, admin, manager |
| GET | `http://127.0.0.1:8000/api/v1/inventory/movements` | owner, admin, manager |

`POST` body: `type` (`stock_in`, `stock_out`, `adjustment`, `waste`,
`order_consumption`), `quantity` (decimal, 3 places; positive except for
`adjustment`, which takes a signed delta), and optional `unit_cost` (defaults
to the ingredient's current cost), `reference_type`, `reference_id`, `notes`.
`GET` returns the shop's movement history newest first, 50 per page, and
accepts `?ingredient_id=`.

### Staff and users

| Method | Full URL | Access |
|---|---|---|
| GET | `http://127.0.0.1:8000/api/v1/staff/me` | Authenticated; own profile |
| GET/POST | `http://127.0.0.1:8000/api/v1/staff` | owner, admin |
| PUT/PATCH | `http://127.0.0.1:8000/api/v1/staff/{staff}` | owner, admin |
| DELETE | `http://127.0.0.1:8000/api/v1/staff/{staff}` | owner, admin; deactivates staff and revokes their tokens; 422 on your own account |
| POST | `http://127.0.0.1:8000/api/v1/users` | owner, admin |

### Shifts

| Method | Full URL | Access |
|---|---|---|
| POST | `http://127.0.0.1:8000/api/v1/shifts/start` | cashier, manager |
| POST | `http://127.0.0.1:8000/api/v1/shifts/{shift}/close` | cashier, manager |
| GET | `http://127.0.0.1:8000/api/v1/shifts` | owner, admin, manager |

### Orders

| Method | Full URL | Access |
|---|---|---|
| GET/POST | `http://127.0.0.1:8000/api/v1/orders` | Authenticated |
| GET | `http://127.0.0.1:8000/api/v1/orders/{order}` | Authenticated |
| PATCH | `http://127.0.0.1:8000/api/v1/orders/{order}/status` | Authenticated |
| POST | `http://127.0.0.1:8000/api/v1/orders/{order}/pay` | Authenticated |
| POST | `http://127.0.0.1:8000/api/v1/orders/{order}/cancel` | Authenticated |

Every authenticated staff member can take and progress orders (cashiers
included). Orders are scoped to the acting user's shop.

Send `Content-Type: application/json`, `Accept: application/json`, and the
bearer token on every order request below.

#### Create order

`POST http://127.0.0.1:8000/api/v1/orders`

```json
{
  "type": "takeaway",
  "items": [
    { "product_variant_id": 1, "quantity": 2 },
    { "product_variant_id": 2, "quantity": 1 }
  ],
  "discount_amount": "1.00",
  "payment_method": "cash",
  "notes": "No sugar"
}
```

`type` is `dine_in`, `takeaway`, or `delivery`. `items` is required and
non-empty; duplicate variant lines are merged. `discount_amount`,
`payment_method`, and `notes` are optional; the discount is clamped to the
subtotal. Totals are always computed server-side from current variant prices
and the shop's `tax_rate`; client-sent totals are ignored. An unavailable
variant or one from another shop returns `422`. The response's `data.id` is
`{order}` in the URLs below.

#### Read order

`GET http://127.0.0.1:8000/api/v1/orders/{order}` — no body. Returns items,
payments, and status history.

#### Change status

`PATCH http://127.0.0.1:8000/api/v1/orders/{order}/status`

```json
{
  "status": "preparing"
}
```

Then, when the order is ready:

```json
{
  "status": "completed"
}
```

Allowed transitions are `pending → preparing → completed` and
`pending/preparing → cancelled`; any other transition returns `409`.
Completing an order deducts its recipe ingredients and writes
`order_consumption` inventory movements; cancelling never touches stock.
Every change appends an order status history row.

#### Record payment

`POST http://127.0.0.1:8000/api/v1/orders/{order}/pay`

```json
{
  "method": "cash",
  "transaction_reference": "TX-1"
}
```

`method` is required: `cash`, `card`, `qr`, `mobile_wallet`, or `other`.
`transaction_reference` is optional, and no amount is sent — the server
always charges the full order total (partial payments are not supported).
The payment row and the order's `payment_status` (`paid`), `payment_method`,
and `paid_at` are written in one transaction; `payment_status` cannot be set
any other way. Paying twice, or paying a cancelled order, returns `409`.

#### Cancel order

`POST http://127.0.0.1:8000/api/v1/orders/{order}/cancel`

```json
{
  "note": "Customer left"
}
```

`note` is optional — `{}` is a valid body. This is shorthand for setting the
status to `cancelled`; it never touches stock. Cancelling an already
completed, cancelled, or paid order returns `409` (refunds are not supported).

#### List orders

`GET http://127.0.0.1:8000/api/v1/orders` — no body. Returns the shop's
orders newest first, paginated, and accepts `?status=`, `?from=`, and `?to=`
(date filters on `created_at`, read in the shop's timezone). Invalid values
return `422`. For example:

```text
GET http://127.0.0.1:8000/api/v1/orders?status=preparing&from=2026-10-01&to=2026-10-31
```

#### Full happy-path sequence

```text
POST  /api/v1/orders                                      {"type":"takeaway","items":[...]}
GET   /api/v1/orders/1
PATCH /api/v1/orders/1/status                             {"status":"preparing"}
PATCH /api/v1/orders/1/status                             {"status":"completed"}
POST  /api/v1/orders/1/pay                                {"method":"cash"}
```

## Responses

Resource responses use a `data` field; collections may also include
pagination metadata. Logout and successful deletes return `204 No Content`.
Validation errors return JSON when `Accept: application/json` is set.

## Planned endpoints (not available to test yet)

These routes are in the architecture plan but are not registered in Laravel.

| Method | Full URL | Purpose |
|---|---|---|
| GET | `http://127.0.0.1:8000/api/v1/tables` | List table availability |
| PATCH | `http://127.0.0.1:8000/api/v1/tables/{table}/status` | Update table status |
| GET/PATCH | `http://127.0.0.1:8000/api/v1/settings` | Read or update shop settings |
| GET | `http://127.0.0.1:8000/api/v1/reports/sales` | Sales by date range |
| GET | `http://127.0.0.1:8000/api/v1/reports/best-sellers` | Best sellers |
| GET | `http://127.0.0.1:8000/api/v1/reports/staff-revenue` | Revenue by staff member |

When implemented, creating a `dine_in` order will occupy its table; completing
or cancelling the order will make the table available again. Order totals
must be calculated by the server from current variant prices, shop tax, and
discounts. Payment, order status, and stock changes must use transactions.
