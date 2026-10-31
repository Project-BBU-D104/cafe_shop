import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/controllers/cart_controller.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_URL=http://127.0.0.1:8000/api/v1');
  });

  // The API serializes decimal prices as strings ("2.50").
  Map<String, dynamic> variant(int id, String price) => {
        'id': id,
        'name': 'V$id',
        'price': price,
        'is_available': true,
      };

  test('adding the same variant twice merges quantity', () {
    final cart = CartController();

    cart.addVariant('Latte', variant(1, '2.50'));
    cart.addVariant('Latte', variant(1, '2.50'));

    expect(cart.items.length, 1);
    expect(cart.items[1]!['quantity'], 2);
    expect(cart.itemCount, 2);
    expect(cart.subtotal, closeTo(5.0, 0.001));
  });

  test('increase/decrease/remove keep subtotal correct', () {
    final cart = CartController();

    cart.addVariant('Latte', variant(1, '2.50'));
    cart.addVariant('Mocha', variant(2, '3.00'));

    cart.increase(1);
    expect(cart.subtotal, closeTo(8.0, 0.001)); // 2×2.50 + 3.00
    expect(cart.itemCount, 3);

    cart.decrease(1);
    expect(cart.subtotal, closeTo(5.5, 0.001));

    // Decreasing the last unit drops the line.
    cart.decrease(1);
    expect(cart.items.containsKey(1), isFalse);
    expect(cart.subtotal, closeTo(3.0, 0.001));

    cart.remove(2);
    expect(cart.items.isEmpty, isTrue);
    expect(cart.itemCount, 0);
    expect(cart.subtotal, 0);
  });

  test('clear empties items and subtotal', () {
    final cart = CartController();

    cart.addVariant('Latte', variant(1, '2.50'));
    cart.discountController.text = '1.00';
    cart.notesController.text = 'note';
    cart.clear();

    expect(cart.items.isEmpty, isTrue);
    expect(cart.subtotal, 0);
    expect(cart.itemCount, 0);
  });

  test('buildOrderPayload matches the StoreOrderRequest contract', () {
    final cart = CartController();

    cart.addVariant('Latte', variant(1, '2.50'));
    cart.increase(1);

    Map<String, dynamic> payload = cart.buildOrderPayload();

    expect(payload['type'], 'dine_in');
    expect(payload['items'], [
      {'product_variant_id': 1, 'quantity': 2},
    ]);
    expect(payload.containsKey('discount_amount'), isFalse);
    expect(payload.containsKey('notes'), isFalse);
    // Payment is recorded separately via the pay endpoint.
    expect(payload.containsKey('payment_method'), isFalse);

    cart.orderType.value = 'takeaway';
    cart.discountController.text = ' 1.5 ';
    cart.notesController.text = ' less sugar ';

    payload = cart.buildOrderPayload();

    expect(payload['type'], 'takeaway');
    expect(payload['discount_amount'], '1.5');
    expect(payload['notes'], 'less sugar');
  });
}
