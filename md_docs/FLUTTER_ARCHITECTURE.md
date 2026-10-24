# Coffee Shop Flutter Application

This document describes the Flutter client for the Laravel API in
`COFFEE_SHOP_ARCHITECTURE.md`. It is a one-shop assignment demo, not a
production platform.

## Scope

The client must support:

- Login and logout.
- Product and category browsing.
- Cart creation and order viewing.
- Payment recording and order-status updates.
- Inventory and low-stock viewing for managers.
- Basic staff, shift, customer, table, settings, and report screens as time
  allows.

The minimum successful demo is:

```text
Login → Product list → Cart → Create order → Order detail
```

## Structure

Create files when their feature is implemented; do not scaffold the whole
tree first.

```text
lib/
├── main.dart
├── app.dart
├── core/
│   ├── api_client.dart
│   ├── api_exception.dart
│   ├── app_config.dart
│   ├── app_theme.dart
│   └── token_storage.dart
├── models/
├── services/
├── features/
│   ├── auth/
│   ├── catalog/
│   ├── orders/
│   ├── inventory/
│   ├── customers/
│   ├── staff/
│   └── reports/
└── app_router.dart
test/
pubspec.yaml
```

Use this data flow:

```text
Page/Widget → ChangeNotifier controller → service → ApiClient → Laravel API
```

Do not add repositories, use-case classes, or another state-management layer.
One controller and service per feature is enough.

## Dependencies

Keep `pubspec.yaml` small:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.0.0
  provider: ^6.0.0
  shared_preferences: ^2.0.0
```

- `http` sends API requests.
- `provider` exposes `ChangeNotifier` controllers.
- `shared_preferences` stores the Sanctum token and basic user data.

Use current compatible versions. Do not add a package for individual widgets,
charts, forms, or networking helpers.

## Application flow

On startup, load the saved token:

```text
No token → LoginPage
Token → DashboardPage
```

Use named routes or a small router:

```text
/login
/dashboard
/catalog
/catalog/product/:id
/cart
/orders
/orders/:id
/inventory
/customers
/staff
/shifts
/reports
/settings
```

Authenticated routes require a token. Hide navigation items unavailable to the
current role, but rely on Laravel for final authorization.

## Models

Models only represent API JSON. They do not make HTTP requests.

Implement these as needed:

```text
User, Category, Product, ProductVariant, Ingredient, ShopTable,
Customer, Order, OrderItem, Payment, ReportSummary
```

Use `fromJson` factories and nullable fields where the API is nullable.
`User` is representative:

```dart
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.shopId,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final int? shopId;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        shopId: json['shop_id'] as int?,
      );
}
```

Keep money as `double` for display. Use strings or a decimal-safe approach at
payment boundaries if exact precision is required.

## API and authentication

`ApiClient` owns:

- Base URL and JSON headers.
- The bearer token.
- GET, POST, PATCH, and DELETE requests.
- JSON decoding.
- Mapping non-2xx responses to `ApiException`.

Configure the URL instead of committing a developer's machine address:

```dart
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000/api/v1',
);
```

```text
Android emulator → http://10.0.2.2:8000
iOS simulator    → http://127.0.0.1:8000
Physical device  → computer's local network IP
```

Login:

```text
POST /auth/login → save token and user → DashboardPage
```

Logout:

```text
POST /auth/logout → clear token and user → LoginPage
```

On `401`, clear the session, return to login, and show a session-expired
message. Never display or log tokens, passwords, stack traces, or raw HTML.

## Features and roles

Shared:

- Login.
- Dashboard summary.
- Profile and logout.

Cashier:

- Catalog and product details.
- Cart and create order.
- Recent orders and order details.
- Start or close shift.

Manager:

- Inventory, stock movements, and low-stock alerts.
- Reports.
- Tables and customers.

Owner/admin:

- Product management.
- Staff management.
- Basic shop settings.

Add screens only when they support the assignment or the demo.

## Required behavior

### Orders

The app sends product IDs and quantities. The API is the source of truth for
prices, tax, discounts, and totals.

```text
Pending → Preparing → Completed
Pending/Preparing → Cancelled
```

Show only valid actions for the current role and status. If the API rejects a
transition, refresh the order and show the server error.

### Inventory

Validate required fields and positive quantities in the form. The API remains
the authoritative validator.

```text
Select ingredient → enter movement → submit → refresh stock and alerts
```

### Controller state

Controllers use `ChangeNotifier` and expose only the state their screen needs:

```dart
class CatalogController extends ChangeNotifier {
  CatalogController(this.service);

  final CatalogService service;
  bool isLoading = false;
  String? errorMessage;
  List<Product> products = [];

  Future<void> loadProducts() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      products = await service.getProducts();
    } on ApiException catch (error) {
      errorMessage = error.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
```

Every API-backed screen handles:

```text
Loading → Content
Loading → Error with retry
Content → Empty
Content → Refreshing
```

Do not turn an API error into an empty list.

## UI rules

- Use Material 3 and one shared `ThemeData`.
- Use `Form` and `TextFormField` for user input.
- Disable submit buttons while a request is active.
- Show progress indicators during requests.
- Confirm cancellation and deletion/archive actions.
- Use `SnackBar` for short feedback.
- Use `ListView.builder` for API-backed lists.
- Use `RefreshIndicator` on catalog, orders, inventory, and reports.
- Use readable labels and adequately sized controls.

Map common failures as follows:

| Response | Behavior |
|---|---|
| `401` | Clear session and return to login. |
| `403` | Show an authorization message. |
| `404` | Explain that the record is gone and refresh. |
| `409` | Explain the conflict and reload the record. |
| `422` | Show validation messages near fields. |
| `429` | Ask the user to wait and retry. |
| `500` or network failure | Show a generic error and retry action. |

## Testing

Test the behavior that can break:

- Model JSON parsing.
- Cart display subtotal calculation.
- Role-based navigation visibility.
- API exception mapping.
- Login persistence and `401` session clearing.
- The main login-to-order flow.

Do not write a widget test for every static layout.

## Implementation order

1. Replace the starter screen with `App`, theme, routing, and login.
2. Add `ApiClient`, token storage, authentication, and role handling.
3. Add catalog models, service, list, and product details.
4. Add cart and order creation.
5. Add order history, details, payments, and status updates.
6. Add inventory and low-stock views.
7. Add the remaining manager and owner screens only as time allows.
8. Add loading, error, empty states, and tests for the main flow.

## Explicitly deferred

Do not implement these unless the assignment changes:

- Offline sync.
- Push notifications.
- Delivery tracking.
- Multiple shops or branch switching.
- Real payment SDKs.
- Receipt printers or barcode scanners.
- Complex charts or analytics packages.
- API model code generation.
- Separate repositories or domain/use-case layers.
