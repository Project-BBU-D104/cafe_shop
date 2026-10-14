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

### Staff and users

| Method | Full URL | Access |
|---|---|---|
| GET | `http://127.0.0.1:8000/api/v1/staff/me` | Authenticated; own profile |
| GET/POST | `http://127.0.0.1:8000/api/v1/staff` | owner, admin |
| PUT/PATCH | `http://127.0.0.1:8000/api/v1/staff/{staff}` | owner, admin |
| DELETE | `http://127.0.0.1:8000/api/v1/staff/{staff}` | owner, admin; deactivates staff |
| POST | `http://127.0.0.1:8000/api/v1/users` | owner, admin |

### Shifts

| Method | Full URL | Access |
|---|---|---|
| POST | `http://127.0.0.1:8000/api/v1/shifts/start` | cashier, manager |
| POST | `http://127.0.0.1:8000/api/v1/shifts/{shift}/close` | cashier, manager |
| GET | `http://127.0.0.1:8000/api/v1/shifts` | owner, admin, manager |

## Responses

Resource responses use a `data` field; collections may also include
pagination metadata. Logout and successful deletes return `204 No Content`.
Validation errors return JSON when `Accept: application/json` is set.

## Planned endpoints (not available to test yet)

These routes are in the architecture plan but are not registered in Laravel.

| Method | Full URL | Purpose |
|---|---|---|
| POST | `http://127.0.0.1:8000/api/v1/ingredients/{ingredient}/movements` | Record a stock movement |
| GET | `http://127.0.0.1:8000/api/v1/inventory/movements` | List stock movement history |
| GET | `http://127.0.0.1:8000/api/v1/tables` | List table availability |
| PATCH | `http://127.0.0.1:8000/api/v1/tables/{table}/status` | Update table status |
| GET/POST | `http://127.0.0.1:8000/api/v1/orders` | List or create orders |
| GET | `http://127.0.0.1:8000/api/v1/orders/{order}` | Read order details |
| PATCH | `http://127.0.0.1:8000/api/v1/orders/{order}/status` | Change order status |
| POST | `http://127.0.0.1:8000/api/v1/orders/{order}/pay` | Record payment |
| POST | `http://127.0.0.1:8000/api/v1/orders/{order}/cancel` | Cancel order |
| GET/PATCH | `http://127.0.0.1:8000/api/v1/settings` | Read or update shop settings |
| GET | `http://127.0.0.1:8000/api/v1/reports/sales` | Sales by date range |
| GET | `http://127.0.0.1:8000/api/v1/reports/best-sellers` | Best sellers |
| GET | `http://127.0.0.1:8000/api/v1/reports/staff-revenue` | Revenue by staff member |

When implemented, creating a `dine_in` order will occupy its table; completing
or cancelling the order will make the table available again. Order totals
must be calculated by the server from current variant prices, shop tax, and
discounts. Payment, order status, and stock changes must use transactions.
