import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/controllers/inventory_movement_controller.dart';
import 'package:frontend/services/main_service/inventory_movement_service.dart';
import 'package:get/get.dart';

class _FakeMovementService extends InventoryMovementService {
  @override
  Future<dynamic> createMovement(
    int ingredientId,
    Map<String, dynamic> data,
  ) async {
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

void main() {
  setUpAll(() {
    // ApiService reads API_URL from dotenv at construction time.
    dotenv.testLoad(fileInput: 'API_URL=http://127.0.0.1:8000/api/v1');
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

  test('selectableIngredients excludes archived ingredients', () {
    final ctr = InventoryMovementController();

    ctr.ingredients.assignAll([
      {'id': 1, 'name': 'Milk', 'is_active': true},
      {'id': 2, 'name': 'Sugar', 'is_active': false},
    ]);

    expect(ctr.selectableIngredients.map((i) => i['id']).toList(), [1]);
  });

  testWidgets('onSubmit refreshes the stock shown from the response',
      (tester) async {
    // The success toast needs a navigator overlay to land in.
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));

    final ctr = InventoryMovementController(
      movementService: _FakeMovementService(),
    );

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
  });
}