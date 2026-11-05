import 'package:frontend/controllers/order_controller.dart';
import 'package:frontend/services/main_service/order_service.dart';
import 'package:frontend/widget/toast_widget.dart';
import 'package:get/get.dart';

/// One order + its lifecycle actions. Predicates mirror the server state
/// machine; the server still has the final say (409 on illegal moves).
class OrderDetailController extends GetxController {
  OrderDetailController(this.orderId, {OrderService? service})
      : service = service ?? OrderService();

  final int orderId;
  final OrderService service;

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
  Future<bool> _act(
    Future<dynamic> Function() call, {
    String? successMessage,
    bool reload = false,
  }) async {
    if (isActing.value) return false;

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

      return true;
    } catch (e) {
      ToastWidget.show(message: e.toString(), type: ToastType.error);
      await loadDetail();
      return false;
    } finally {
      isActing.value = false;
    }
  }

  Future<bool> start() => _act(
        () => service.updateStatus(orderId, 'preparing'),
        successMessage: 'Order is now preparing',
      );

  Future<bool> complete() => _act(
        () => service.updateStatus(orderId, 'completed'),
        successMessage: 'Order completed',
      );

  Future<bool> cancel({String? note}) => _act(
        () => service.cancelOrder(orderId, note: note),
        successMessage: 'Order cancelled',
      );

  Future<bool> pay(String method, {String? reference}) async {
    final bool paid = await _act(
      () => service.payOrder(orderId, method, reference: reference),
      successMessage: 'Payment recorded',
      reload: true,
    );

    if (!paid) return false;

    // The detail route lives in the home shell's nested navigator; popping to
    // its first route closes the payment sheet and shows the order list again.
    Get.until((route) => route.isFirst, id: 1);

    // The cart flow has no awaiting push to refresh the list, so do it here.
    if (Get.isRegistered<OrderController>()) {
      Get.find<OrderController>().load(refresh: true);
    }

    return true;
  }
}
