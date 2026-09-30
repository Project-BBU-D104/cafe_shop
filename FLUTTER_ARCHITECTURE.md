# Coffee Shop Flutter Application

## Delivery scope for this assignment

This document describes the Flutter client for the coffee-shop management
assignment. It is designed to work with the Laravel API described in
`COFFEE_SHOP_ARCHITECTURE.md`.

The app should demonstrate:

1. Login and logout.
2. Product and category browsing.
3. Creating and viewing orders.
4. Recording payments and updating order status.
5. Inventory and low-stock viewing for managers.
6. Basic staff, shift, customer, and report screens.

The app is for one shop and one assignment demo. Do not build offline sync,
push notifications, multiple API environments, complex dependency injection,
or a large design system unless the assignment specifically requires them.

## 1. Recommended Flutter structure

Use a small feature-based structure. Keep API calls in services, screen state
in controllers, and visual components in widgets.

```text
flutter_app/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── config/
│   │   │   └── app_config.dart
│   │   ├── network/
│   │   │   ├── api_client.dart
│   │   │   └── api_exception.dart
│   │   ├── storage/
│   │   │   └── token_storage.dart
│   │   ├── theme/
│   │   │   └── app_theme.dart
│   │   └── widgets/
│   │       ├── app_error_view.dart
│   │       ├── app_loading.dart
│   │       └── empty_state.dart
│   ├── models/
│   │   ├── category.dart
│   │   ├── customer.dart
│   │   ├── ingredient.dart
│   │   ├── order.dart
│   │   ├── product.dart
│   │   ├── shop_table.dart
│   │   ├── user.dart
│   │   └── report_summary.dart
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── catalog_service.dart
│   │   ├── inventory_service.dart
│   │   ├── order_service.dart
│   │   ├── staff_service.dart
│   │   └── report_service.dart
│   ├── features/
│   │   ├── auth/
│   │   │   ├── login_page.dart
│   │   │   └── auth_controller.dart
│   │   ├── dashboard/
│   │   │   ├── dashboard_page.dart
│   │   │   └── dashboard_controller.dart
│   │   ├── catalog/
│   │   │   ├── catalog_page.dart
│   │   │   ├── product_detail_page.dart
│   │   │   └── catalog_controller.dart
│   │   ├── orders/
│   │   │   ├── cart_page.dart
│   │   │   ├── create_order_page.dart
│   │   │   ├── order_detail_page.dart
│   │   │   ├── orders_page.dart
│   │   │   └── order_controller.dart
│   │   ├── inventory/
│   │   │   ├── inventory_page.dart
│   │   │   └── inventory_controller.dart
│   │   ├── customers/
│   │   │   ├── customers_page.dart
│   │   │   └── customer_controller.dart
│   │   ├── staff/
│   │   │   ├── staff_page.dart
│   │   │   ├── shifts_page.dart
│   │   │   └── staff_controller.dart
│   │   └── reports/
│   │       ├── reports_page.dart
│   │       └── reports_controller.dart
│   └── routing/
│       └── app_router.dart
├── test/
│   ├── models/
│   ├── services/
│   └── widget_test.dart
└── pubspec.yaml
```

This is a guide rather than a requirement to create every file immediately.
Create a feature folder when that feature is implemented.

## 2. Simple application flow

```text
main.dart
  ↓
App configuration and theme
  ↓
Auth controller checks saved token
  ├── no token → LoginPage
  └── valid token → DashboardPage
                         ↓
                 role-based navigation
```

The normal data flow is:

```text
Page/Widget
  ↓
Controller
  ↓
Service
  ↓
ApiClient
  ↓
Laravel API
```

Do not add repositories, use-case classes, or multiple state-management layers
for this assignment. A controller and service per feature are enough.

## 3. Suggested dependencies

Keep dependencies small:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.0.0
  provider: ^6.0.0
  shared_preferences: ^2.0.0
```

- `http`: sends requests to the Laravel API.
- `provider`: exposes controllers to screens and rebuilds the UI when state
  changes.
- `shared_preferences`: stores the Sanctum token and basic user information.

Use the current compatible versions when installing packages. Do not add a
separate package for every UI component, chart, form, or networking feature.

## 4. Core models

Models should represent API JSON and contain only small conversion helpers.
They should not make HTTP requests.

### User

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

The other models should follow the same pattern:

```text
Category
Product
ProductVariant
Ingredient
ShopTable
Customer
Order
OrderItem
Payment
ReportSummary
```

Use nullable fields for values that are nullable in the API. Keep monetary
values as `double` for display, or as strings if exact decimal preservation is
needed at the payment boundary.

## 5. API client

`ApiClient` owns common HTTP behavior:

- Base URL.
- JSON headers.
- Sanctum bearer token.
- GET, POST, PATCH, and DELETE methods.
- JSON decoding.
- Mapping non-2xx responses to `ApiException`.

Example request:

```dart
final response = await apiClient.post(
  '/orders',
  body: {
    'type': 'dine_in',
    'table_id': tableId,
    'payment_method': 'cash',
    'items': cartItems,
  },
);
```

The base URL must come from configuration:

```dart
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000/api/v1',
);
```

Use:

```text
Android emulator → http://10.0.2.2:8000
iOS simulator    → http://127.0.0.1:8000
Physical device  → computer's local network IP
```

Do not commit a personal computer's local IP as the only API URL.

## 6. Authentication

### Login flow

```text
LoginPage
  → POST /auth/login
  → save token
  → save user
  → open DashboardPage
```

### Logout flow

```text
Logout button
  → POST /auth/logout
  → remove token and saved user
  → open LoginPage
```

If an API request returns `401`:

1. Clear the saved token.
2. Clear the current user.
3. Navigate to the login page.
4. Show a short session-expired message.

Never display or log the token.

## 7. Screens and roles

### Shared screens

| Screen | Purpose |
|---|---|
| Login | Authenticate a user. |
| Dashboard | Show shortcuts and a small summary based on the user's role. |
| Profile | Show current user and logout. |

### Cashier screens

| Screen | Purpose |
|---|---|
| Catalog | Browse available products by category. |
| Product detail | Select a product variant and quantity. |
| Cart | Review items before submitting an order. |
| Create order | Select dine-in/takeaway, table, customer, and payment method. |
| Orders | View recent orders. |
| Order detail | View items, totals, payment, and current status. |
| Shift | Start or close the cashier shift. |

### Manager screens

| Screen | Purpose |
|---|---|
| Inventory | View ingredients and current stock. |
| Stock movement | Record stock in, stock out, adjustment, or waste. |
| Low-stock alerts | Display ingredients below their minimum stock. |
| Reports | Display sales, best sellers, and staff revenue. |
| Tables | View and update table availability. |
| Customers | Search and register customers. |

### Owner/admin screens

| Screen | Purpose |
|---|---|
| Product management | Create, edit, activate, or archive products. |
| Staff management | Create, update, or deactivate staff. |
| Settings | Edit basic shop settings such as tax rate and receipt footer. |

Hide navigation items that the current role cannot use. The API remains the
final authority and must still reject unauthorized requests.

## 8. Main user flows

### Create an order

```text
Login
  → Catalog
  → Select category
  → Select product variant
  → Add to cart
  → Review cart
  → Select order type and payment method
  → Submit order
  → Show order confirmation
```

The Flutter app sends product IDs and quantities. It must not calculate the
final total as the source of truth. The Laravel API recalculates prices, tax,
discount, and total.

### Update order status

```text
Pending → Preparing → Completed
Pending/Preparing → Cancelled
```

Show only actions allowed for the current status and role. If the API rejects
a transition, refresh the order and show the server error.

### Inventory movement

```text
Inventory
  → Select ingredient
  → Enter movement type and quantity
  → Submit
  → Refresh stock and alerts
```

The Flutter app validates obvious input such as required fields and positive
quantities, but the API performs the authoritative validation.

## 9. Controller state

A controller can use `ChangeNotifier` with a small state shape:

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

Each screen should support these states:

```text
Loading → Content
Loading → Error with retry
Content → Empty state
Content → Refreshing
```

Do not silently replace an API error with an empty list. Show an error and
provide a retry action.

## 10. Navigation

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

The router should protect authenticated routes. Role checks should control
which screens are reachable from navigation, while Laravel continues to
enforce authorization.

For this assignment, a `NavigationBar` or `Drawer` is sufficient. Use a
`Drawer` for manager and owner sections if the bottom navigation would become
too crowded.

## 11. UI and design rules

- Use Material 3 widgets and one shared `ThemeData`.
- Use a small coffee-shop color palette rather than styling every screen
  independently.
- Use `Form` and `TextFormField` for login, product, customer, and inventory
  forms.
- Show a progress indicator while submitting.
- Disable submit buttons during a request to prevent duplicate submissions.
- Use confirmation dialogs before cancelling an order or deleting/archiving a
  product.
- Use `SnackBar` for short success/error messages.
- Use `ListView.builder` for API-backed lists.
- Use `RefreshIndicator` on catalog, orders, inventory, and reports.
- Provide readable labels and adequate button sizes.

## 12. Error handling

Map common API errors to clear messages:

| HTTP status | Flutter behavior |
|---|---|
| `401` | Clear session and return to login. |
| `403` | Show an authorization message. |
| `404` | Show that the record no longer exists and refresh the list. |
| `409` | Show the state conflict and reload the affected record. |
| `422` | Display validation messages near the relevant fields. |
| `429` | Ask the user to wait and try again. |
| `500` | Show a generic server error with retry. |
| Network failure | Show that the API is unreachable with retry. |

Do not show stack traces, raw HTML responses, tokens, or passwords in the UI.

## 13. Testing strategy

For the assignment, test the important behavior rather than every widget:

### Unit tests

- Model JSON parsing.
- Cart subtotal calculation for display.
- Role-to-navigation visibility.
- API exception mapping.

### Service tests

- Login stores a token and user.
- Catalog service parses products.
- Order service sends the expected item and payment payload.
- `401` responses clear the session.

### Widget tests

- Login validation.
- Catalog loading and error states.
- Adding a product to the cart.
- Cart displays quantity and items.
- Unauthorized navigation items are hidden.

At least verify the main demo flow:

```text
Login → browse catalog → add product → create order → view order
```

## 14. Assignment implementation order

1. Replace the starter counter screen with `App`, theme, routing, and login.
2. Add `ApiClient`, token storage, authentication, and role handling.
3. Add catalog models, catalog service, product list, and product details.
4. Add cart state and order creation.
5. Add order history, order details, payment recording, and status updates.
6. Add inventory and low-stock screens.
7. Add tables, customers, staff, shifts, settings, and reports as time allows.
8. Add loading, error, empty states, and tests for the main flow.

The minimum successful Flutter demonstration is:

```text
Login → Product list → Cart → Create order → Order detail
```

The remaining screens demonstrate the broader assignment requirements but
should not delay the core ordering flow.

## 15. Deferred Flutter features

Do not implement these unless required:

- Offline-first storage and synchronization.
- Push notifications.
- Background location or delivery tracking.
- Multiple shops and branch switching.
- Real payment SDKs.
- Receipt printers and barcode scanners.
- Complex charts or analytics packages.
- Automatic code generation for API models.
- Separate repositories and domain/use-case layers.

The Flutter client should remain a small API client with clear screens and
enough state management to demonstrate the assignment requirements.
