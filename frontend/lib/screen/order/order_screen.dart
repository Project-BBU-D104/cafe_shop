import 'package:flutter/material.dart';
import 'package:frontend/controllers/order_controller.dart';
import 'package:frontend/routes/app_routes.dart';
import 'package:frontend/utils/date_formatter.dart';
import 'package:frontend/widget/custom_app_bar.dart';
import 'package:get/get.dart';

class OrderScreen extends StatelessWidget {
  OrderScreen({super.key});

  final OrderController ctr = Get.put(OrderController());

  static MaterialColor statusColor(String status) => switch (status) {
        'pending' => Colors.orange,
        'preparing' => Colors.blue,
        'completed' => Colors.green,
        'cancelled' => Colors.red,
        _ => Colors.blueGrey,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Orders',
        showBack: false,
        showRefresh: true,
        onRefresh: () => ctr.load(refresh: true),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Get.toNamed(AppRoutes.catalog, id: 1);
          // A new order may have been created inside the catalog flow.
          ctr.load(refresh: true);
        },
        icon: const Icon(Icons.add_shopping_cart),
        label: Text('New Order'.tr),
      ),
      body: Obx(() {
        if (ctr.isLoading.value && ctr.orders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (ctr.error.value != null && ctr.orders.isEmpty) {
          return _Message(
            text: ctr.error.value!,
            actionLabel: 'Retry',
            onAction: () => ctr.load(refresh: true),
          );
        }

        if (ctr.orders.isEmpty) {
          return _Message(text: 'No orders yet'.tr);
        }

        return RefreshIndicator(
          onRefresh: () => ctr.load(refresh: true),
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 200) {
                ctr.loadMore();
              }
              return false;
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: ctr.orders.length + (ctr.isLoading.value ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= ctr.orders.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                return _OrderTile(
                  order: ctr.orders[index],
                  onTap: () async {
                    final id = ctr.orders[index]['id'];
                    await Get.toNamed(
                      '/orders/$id',
                      arguments: {'id': id},
                      id: 1,
                    );
                    ctr.load(refresh: true);
                  },
                );
              },
            ),
          ),
        );
      }),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, required this.onTap});

  final Map<String, dynamic> order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String status = (order['status'] ?? '').toString();
    final bool paid = (order['payment_status'] ?? '').toString() == 'paid';
    final MaterialColor tint = OrderScreen.statusColor(status);
    final String date = DateFormatter.formatDateTime(
      DateTime.tryParse((order['created_at'] ?? '').toString())?.toLocal(),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        title: Row(
          children: [
            Expanded(
              child: Text(
                (order['order_number'] ?? '#${order['id']}').toString(),
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '\$${order['total_amount']}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              _Chip(label: status.replaceAll('_', ' '), tint: tint),
              const SizedBox(width: 8),
              _Chip(
                label: paid ? 'paid' : 'unpaid',
                tint: paid ? Colors.green : Colors.blueGrey,
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  date,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.tint});

  final String label;
  final MaterialColor tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tint.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.tr,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: tint.shade700,
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.actionLabel, this.onAction});

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 12),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
