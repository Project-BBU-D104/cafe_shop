import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/controllers/inventory_movement_controller.dart';
import 'package:frontend/locator.dart';
import 'package:frontend/screen/inventory/inventory_movement/inventory_movement_screen.dart';
import 'package:frontend/services/main_service/inventory_movement_service.dart';
import 'package:frontend/services/storage_service.dart';
import 'package:get/get.dart';

class _FakeMovementService extends InventoryMovementService {
  final List<Map<String, dynamic>> ledger = [];

  @override
  Future<dynamic> getMovements() async => {'data': ledger};

  @override
  Future<dynamic> createMovement(
    int ingredientId,
    Map<String, dynamic> data,
  ) async {
    ledger.insert(0, {
      'id': 1,
      'ingredient_id': ingredientId,
      'type': data['type'],
      'quantity': '5.000',
      'notes': null,
      'created_at': '2026-10-30T06:00:00.000000Z',
      'ingredient': {'id': ingredientId, 'name': 'Milk', 'unit': 'L'},
    });

    // Same shape as InventoryMovementResource with a loaded ingredient.
    return {
      'data': {
        'ingredient': {
          'id': ingredientId,
          'name': 'Milk',
          'unit': 'L',
          'current_stock': 15,
          'is_active': true,
        },
      },
    };
  }
}

class _EmptyMovementService extends InventoryMovementService {
  @override
  Future<dynamic> getMovements() async => {};
}

/// Logged-in manager: onGetMovements/onSubmit read canManage through the locator.
class _FakeStorageService implements IStorageService {
  @override
  Map<String, dynamic> get lastUserLoginRead =>
      {'user': {'id': 1, 'role': 'manager'}};

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  setUpAll(() {
    // ApiService reads API_URL from dotenv at construction time.
    dotenv.testLoad(fileInput: 'API_URL=http://127.0.0.1:8000/api/v1');

    if (!locator.isRegistered<IStorageService>()) {
      locator.registerSingleton<IStorageService>(_FakeStorageService());
    }
  });

  test('validateQuantity mirrors the API rules', () {
    final ctr = InventoryMovementController();

    expect(ctr.validateQuantity('stock_in', ''), isNotNull);
    expect(ctr.validateQuantity('stock_in', '0'), isNotNull);
    expect(ctr.validateQuantity('stock_in', '-2'), isNotNull);
    expect(ctr.validateQuantity('stock_in', 'abc'), isNotNull);
    expect(ctr.validateQuantity('stock_in', '1.5'), isNull);

    expect(ctr.validateQuantity('adjustment', '-2'), isNull);
    expect(ctr.validateQuantity('adjustment', '0'), isNotNull);
  });

  test('buildPayload drops blank optional fields', () {
    final ctr = InventoryMovementController();

    ctr.quantityController.text = '5';
    ctr.unitCostController.clear();
    ctr.notesController.clear();

    final payload = ctr.buildPayload();

    expect(payload['type'], 'stock_in');
    expect(payload['quantity'], 5);
    expect(payload.containsKey('unit_cost'), isFalse);
    expect(payload.containsKey('notes'), isFalse);
  });

  test('buildPayload includes unit cost and notes when filled', () {
    final ctr = InventoryMovementController();

    ctr.movementType.value = 'adjustment';
    ctr.quantityController.text = '-2';
    ctr.unitCostController.text = '12.5';
    ctr.notesController.text = 'Spilled';

    final payload = ctr.buildPayload();

    expect(payload['type'], 'adjustment');
    expect(payload['quantity'], -2);
    expect(payload['unit_cost'], 12.5);
    expect(payload['notes'], 'Spilled');
  });

  test('formatQuantity takes its sign from the type, not the stored number', () {
    // stock_out/waste/order_consumption are stored positive but reduce stock.
    expect(InventoryMovementScreen.formatQuantity('stock_in', '3.500'), '+3.5');
    expect(InventoryMovementScreen.formatQuantity('stock_out', '0.500'), '-0.5');
    expect(InventoryMovementScreen.formatQuantity('waste', '3.000'), '-3');
    expect(
      InventoryMovementScreen.formatQuantity('order_consumption', '2.000'),
      '-2',
    );

    // An adjustment carries its own sign.
    expect(
      InventoryMovementScreen.formatQuantity('adjustment', '-2.000'),
      '-2',
    );
    expect(
      InventoryMovementScreen.formatQuantity('adjustment', '1.500'),
      '+1.5',
    );

    expect(InventoryMovementScreen.formatQuantity('stock_in', 'abc'), 'abc');
  });

  test('selectableIngredients excludes archived ingredients', () {
    final ctr = InventoryMovementController();

    ctr.ingredients.assignAll([
      {'id': 1, 'name': 'Milk', 'is_active': true},
      {'id': 2, 'name': 'Sugar', 'is_active': false},
    ]);

    expect(ctr.selectableIngredients.map((i) => i['id']).toList(), [1]);
  });

  test('onGetMovements unwraps the paginated data list', () async {
    final fake = _FakeMovementService()
      ..ledger.addAll([
        {'id': 2, 'type': 'stock_out', 'quantity': '0.500'},
        {'id': 1, 'type': 'stock_in', 'quantity': '1.000'},
      ]);
    final ctr = InventoryMovementController(movementService: fake);

    await ctr.onGetMovements();

    expect(ctr.movements.map((m) => m['id']).toList(), [2, 1]);
    expect(ctr.isLoadingMovements.value, isFalse);
  });

  test('onGetMovements clears the list for a body without data', () async {
    final ctr = InventoryMovementController(
      movementService: _EmptyMovementService(),
    );
    ctr.movements.assignAll([
      {'id': 1, 'type': 'stock_in'},
    ]);

    await ctr.onGetMovements();

    expect(ctr.movements, isEmpty);
  });

  testWidgets('onSubmit refreshes the stock shown from the response',
      (tester) async {
    // The success toast needs a navigator overlay to land in.
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));

    final fake = _FakeMovementService();
    final ctr = InventoryMovementController(movementService: fake);

    ctr.ingredients.assignAll([
      {
        'id': 1,
        'name': 'Milk',
        'unit': 'L',
        'current_stock': 10,
        'is_active': true,
      },
    ]);
    ctr.selectedIngredient.value = ctr.ingredients.first;
    ctr.quantityController.text = '5';

    await ctr.onSubmit();
    await tester.pump(const Duration(seconds: 4)); // let the toast timer fire
    await tester.pumpAndSettle();

    expect(ctr.selectedIngredient.value!['current_stock'], 15);
    expect(ctr.ingredients.first['current_stock'], 15);
    expect(ctr.quantityController.text, isEmpty);

    // The ledger is refetched so the new row shows without a manual refresh.
    expect(ctr.movements, hasLength(1));
    expect(ctr.movements.first['type'], 'stock_in');
  });
}