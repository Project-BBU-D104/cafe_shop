import 'package:frontend/services/main_service/order_service.dart';
import 'package:frontend/widget/toast_widget.dart';
import 'package:get/get.dart';

/// One order + its lifecycle actions. Predicates mirror the server state
/// machine; the server still has the final say (409 on illegal moves).
class OrderDetailController extends GetxController {
  OrderDetailController(this.orderId);

  final int orderId;
  final OrderService service = OrderService();

  final Rxn<Map<String, dynamic>> order = Rxn<Map<String, dynamic>>();
  final RxBool isLoading = false.obs;
  final RxBool isActing = false.obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadDetail();
  }

  String get status => (order.value?['status'] ?? '').toString();
  String get paymentStatus => (order.value?['payment_status'] ?? '').toString();

  bool get canStart => order.value != null && status == 'pending';
  bool get canComplete => order.value != null && status == 'preparing';
  bool get canCancel =>
      order.value != null &&
      (status == 'pending' || status == 'preparing') &&
      paymentStatus != 'paid';
  // Completed-but-unpaid orders can still be paid; cancelled never.
  bool get canPay =>
      order.value != null &&
      status != 'cancelled' &&
      paymentStatus != 'paid';

  Future<void> loadDetail() async {
    try {
      isLoading.value = true;
      error.value = null;

      final resp = await service.getOrder(orderId);

      if (resp is Map && resp['data'] is Map) {
        order.value = Map<String, dynamic>.from(resp['data']);
      } else {
        throw Exception('Invalid order response');
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Runs a lifecycle call; on success swaps in the fresh order, on any error
  /// (409/404/network) shows the server message and reloads to resync.
  /// [reload] re-fetches the order instead of using the response body — the
  /// pay endpoint returns a PaymentResource, not an order.
  Future<void> _act(
    Future<dynamic> Function() call, {
    String? successMessage,
    bool reload = false,
  }) async {
    if (isActing.value) return;

    try {
      isActing.value = true;

      final resp = await call();

      if (reload) {
        await loadDetail();
      } else if (resp is Map && resp['data'] is Map) {
        order.value = Map<String, dynamic>.from(resp['data']);
      }

      if (successMessage != null) {
        ToastWidget.show(message: successMessage, type: ToastType.success);
      }
    } catch (e) {
      ToastWidget.show(message: e.toString(), type: ToastType.error);
      await loadDetail();
    } finally {
      isActing.value = false;
    }
  }

  Future<void> start() => _act(
        () => service.updateStatus(orderId, 'preparing'),
        successMessage: 'Order is now preparing',
      );

  Future<void> complete() => _act(
        () => service.updateStatus(orderId, 'completed'),
        successMessage: 'Order completed',
      );

  Future<void> cancel({String? note}) => _act(
        () => service.cancelOrder(orderId, note: note),
        successMessage: 'Order cancelled',
      );

  Future<void> pay(String method, {String? reference}) => _act(
        () => service.payOrder(orderId, method, reference: reference),
        successMessage: 'Payment recorded',
        reload: true,
      );
}
