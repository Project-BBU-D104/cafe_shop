import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/controllers/order_detail_controller.dart';
import 'package:frontend/screen/order/order_detail_screen.dart';
import 'package:frontend/services/main_service/order_service.dart';
import 'package:get/get.dart';

/// In-memory orders API; `payError` makes the pay call fail like a 409/network.
class _FakeOrderService extends OrderService {
  _FakeOrderService({this.payError});

  final Object? payError;
  int payCalls = 0;

  Map<String, dynamic> current = {
    'id': 1,
    'status': 'completed',
    'payment_status': 'unpaid',
  };

  @override
  Future<dynamic> getOrder(int id) async => {'data': current};

  @override
  Future<dynamic> payOrder(int id, String method, {String? reference}) async {
    payCalls++;
    if (payError != null) throw payError!;
    current = {...current, 'payment_status': 'paid'};
    return {
      'data': {'id': 1, 'method': method},
    };
  }
}

/// Home-shell stand-in: nested navigator id 1 with the order list under a
/// pushed detail route, so the post-payment pop is observable.
Future<void> _pumpNestedShell(WidgetTester tester) async {
  await tester.pumpWidget(
    GetMaterialApp(
      home: Navigator(
        key: Get.nestedKey(1),
        onGenerateRoute: (settings) => MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(
            body: Text(settings.name == '/detail' ? 'DETAIL' : 'LIST'),
          ),
        ),
      ),
    ),
  );

  Get.nestedKey(1)!.currentState!.pushNamed('/detail');
  await tester.pumpAndSettle();
}

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

  testWidgets('successful payment returns to the order list', (tester) async {
    await _pumpNestedShell(tester);

    final fake = _FakeOrderService();
    final ctr = OrderDetailController(1, service: fake);
    await ctr.loadDetail();

    final bool paid = await ctr.pay('cash');

    await tester.pumpAndSettle();
    expect(paid, isTrue);
    expect(fake.payCalls, 1);
    expect(ctr.paymentStatus, 'paid'); // reloaded from GET, not the pay body
    expect(find.text('DETAIL'), findsNothing);
    expect(find.text('LIST'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4)); // let the success toast expire
    await tester.pumpAndSettle();
  });

  testWidgets('failed payment stays on the detail page', (tester) async {
    await _pumpNestedShell(tester);

    final fake = _FakeOrderService(payError: Exception('Card declined'));
    final ctr = OrderDetailController(1, service: fake);
    await ctr.loadDetail();

    final bool paid = await ctr.pay('cash');

    await tester.pumpAndSettle();
    expect(paid, isFalse);
    expect(fake.payCalls, 1);
    expect(ctr.paymentStatus, 'unpaid');
    expect(find.text('DETAIL'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4)); // let the error toast expire
    await tester.pumpAndSettle();
  });

  testWidgets('paying from the real sheet closes it and the detail once',
      (tester) async {
    final fake = _FakeOrderService();
    final ctr = OrderDetailController(1, service: fake);
    await ctr.loadDetail();
    Get.put(ctr); // the screen's own Get.put reuses this fake-backed instance

    await tester.pumpWidget(
      GetMaterialApp(
        home: Navigator(
          key: Get.nestedKey(1),
          onGenerateRoute: (settings) => MaterialPageRoute(
            settings: settings,
            builder: (_) => settings.name == '/detail'
                ? OrderDetailScreen()
                : Scaffold(body: Text('LIST')),
          ),
        ),
      ),
    );
    Get.nestedKey(1)!.currentState!.pushNamed('/detail');
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Record Payment'));
    await tester.tap(find.text('Record Payment'));
    await tester.pumpAndSettle();
    expect(find.text('Pay'), findsOneWidget);

    await tester.tap(find.text('Pay'));
    await tester.pumpAndSettle();

    expect(fake.payCalls, 1);
    expect(ctr.paymentStatus, 'paid');
    expect(find.text('Pay'), findsNothing);
    expect(find.text('Record Payment'), findsNothing);
    expect(find.text('LIST'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4)); // let the success toast expire
    await tester.pumpAndSettle();
  });
}
