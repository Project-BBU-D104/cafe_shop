import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/controllers/order_detail_controller.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_URL=http://127.0.0.1:8000/api/v1');
  });

  Map<String, dynamic> order(String status, String paymentStatus) => {
        'id': 1,
        'status': status,
        'payment_status': paymentStatus,
      };

  // Predicates mirror the server state machine: pending → preparing|cancelled,
  // preparing → completed|cancelled; paid can't cancel; cancelled can't pay.
  test('predicate matrix matches the API transitions', () {
    final ctr = OrderDetailController(1);

    ctr.order.value = order('pending', 'unpaid');
    expect(ctr.canStart, isTrue);
    expect(ctr.canComplete, isFalse);
    expect(ctr.canCancel, isTrue);
    expect(ctr.canPay, isTrue);

    ctr.order.value = order('preparing', 'unpaid');
    expect(ctr.canStart, isFalse);
    expect(ctr.canComplete, isTrue);
    expect(ctr.canCancel, isTrue);
    expect(ctr.canPay, isTrue);

    // Completed but unpaid can still be paid.
    ctr.order.value = order('completed', 'unpaid');
    expect(ctr.canStart, isFalse);
    expect(ctr.canComplete, isFalse);
    expect(ctr.canCancel, isFalse);
    expect(ctr.canPay, isTrue);

    ctr.order.value = order('cancelled', 'unpaid');
    expect(ctr.canStart, isFalse);
    expect(ctr.canComplete, isFalse);
    expect(ctr.canCancel, isFalse);
    expect(ctr.canPay, isFalse);
  });

  test('paid order cannot be cancelled or paid again', () {
    final ctr = OrderDetailController(1);

    ctr.order.value = order('pending', 'paid');
    expect(ctr.canStart, isTrue);
    expect(ctr.canCancel, isFalse);
    expect(ctr.canPay, isFalse);

    ctr.order.value = order('completed', 'paid');
    expect(ctr.canCancel, isFalse);
    expect(ctr.canPay, isFalse);
  });

  test('no order loaded yet means no actions', () {
    final ctr = OrderDetailController(1);

    expect(ctr.canStart, isFalse);
    expect(ctr.canComplete, isFalse);
    expect(ctr.canCancel, isFalse);
    expect(ctr.canPay, isFalse);
  });
}
