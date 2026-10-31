import 'package:frontend/services/main_service/order_service.dart';
import 'package:get/get.dart';

/// Paginated order list (the API pages at a fixed 15).
class OrderController extends GetxController {
  final OrderService service = OrderService();

  final RxList<Map<String, dynamic>> orders = <Map<String, dynamic>>[].obs;
  final RxInt page = 0.obs;
  final RxBool hasMore = false.obs;
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    load(refresh: true);
  }

  Future<void> load({bool refresh = false}) async {
    if (isLoading.value) return;

    final int next = refresh ? 1 : page.value + 1;

    try {
      isLoading.value = true;
      error.value = null;

      final resp = await service.getOrders(page: next);

      if (resp is Map && resp['data'] is List) {
        final rows = (resp['data'] as List).map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(item as Map),
        );

        if (refresh) {
          orders.assignAll(rows);
        } else {
          orders.addAll(rows);
        }

        final Map<String, dynamic> meta =
            resp['meta'] is Map ? Map<String, dynamic>.from(resp['meta']) : {};

        page.value =
            int.tryParse((meta['current_page'] ?? next).toString()) ?? next;
        final int lastPage =
            int.tryParse((meta['last_page'] ?? '').toString()) ?? page.value;
        hasMore.value = page.value < lastPage;
      } else {
        if (refresh) {
          orders.clear();
          page.value = 0;
        }
        hasMore.value = false;
      }
    } catch (e) {
      error.value = e.toString();

      if (refresh) {
        orders.clear();
        page.value = 0;
      }
      hasMore.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (!hasMore.value || isLoading.value) return;

    await load();
  }
}
