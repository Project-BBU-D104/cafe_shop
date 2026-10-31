import 'package:flutter/material.dart';
import 'package:frontend/controllers/order_detail_controller.dart';
import 'package:frontend/helper/confirm_dialog_helper.dart';
import 'package:frontend/screen/order/order_screen.dart';
import 'package:frontend/utils/date_formatter.dart';
import 'package:frontend/widget/custom_app_bar.dart';
import 'package:get/get.dart';

class OrderDetailScreen extends StatelessWidget {
  OrderDetailScreen({super.key});

  static const Map<String, String> _paymentMethods = {
    'cash': 'Cash',
    'card': 'Card',
    'qr': 'QR',
    'mobile_wallet': 'Mobile wallet',
    'other': 'Other',
  };

  // First path-param route in the app; arguments are the fallback in case the
  // nested navigator does not fill Get.parameters.
  static int _resolveOrderId() {
    final int? fromPath = int.tryParse(Get.parameters['id'] ?? '');

    if (fromPath != null) return fromPath;

    final args = Get.arguments;

    if (args is Map) {
      return int.tryParse((args['id'] ?? '').toString()) ?? 0;
    }

    return 0;
  }

  final OrderDetailController ctr =
      Get.put(OrderDetailController(_resolveOrderId()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Order Detail'),
      body: Obx(() {
        if (ctr.isLoading.value && ctr.order.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final order = ctr.order.value;

        if (order == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    ctr.error.value ?? 'Order not found'.tr,
                    textAlign: TextAlign.center,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: ctr.loadDetail,
                      child: Text('Retry'.tr),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => Get.back(id: 1),
                      child: Text('Back'.tr),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Header(order: order),
            const SizedBox(height: 16),
            _SectionTitle(text: 'Items'.tr),
            ...(order['items'] is List
                ? (order['items'] as List).map(
                    (item) => _ItemRow(
                        item: Map<String, dynamic>.from(item as Map)))
                : const <Widget>[]),
            const SizedBox(height: 16),
            _SectionTitle(text: 'Totals'.tr),
            _TotalRow(label: 'Subtotal'.tr, value: order['subtotal']),
            _TotalRow(label: 'Discount'.tr, value: order['discount_amount']),
            _TotalRow(label: 'Tax'.tr, value: order['tax_amount']),
            _TotalRow(
              label: 'Total'.tr,
              value: order['total_amount'],
              bold: true,
            ),
            if ((order['notes'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              _SectionTitle(text: 'Notes'.tr),
              Text((order['notes'] ?? '').toString()),
            ],
            if (order['payment_status'] == 'paid') ...[
              const SizedBox(height: 16),
              _SectionTitle(text: 'Payment'.tr),
              Text(
                '${_paymentMethods[(order['payment_method'] ?? '').toString()] ?? order['payment_method']}'
                '${order['paid_at'] != null ? ' — ${DateFormatter.formatDateTime(DateTime.tryParse(order['paid_at'].toString())?.toLocal())}' : ''}',
              ),
            ],
            const SizedBox(height: 24),
            _Actions(ctr: ctr, paymentMethods: _paymentMethods),
            const SizedBox(height: 24),
          ],
        );
      }),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.order});

  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final String status = (order['status'] ?? '').toString();
    final MaterialColor tint = OrderScreen.statusColor(status);
    final bool paid = (order['payment_status'] ?? '').toString() == 'paid';
    final String date = DateFormatter.formatDateTime(
      DateTime.tryParse((order['created_at'] ?? '').toString())?.toLocal(),
    );

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    (order['order_number'] ?? '#${order['id']}').toString(),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: tint.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.replaceAll('_', ' ').tr,
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: tint.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${(order['type'] ?? '').toString().replaceAll('_', ' ').tr} · $date · '
              '${paid ? 'paid'.tr : 'unpaid'.tr}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final String variant = (item['variant_name'] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((item['product_name'] ?? '').toString()),
                if (variant.isNotEmpty)
                  Text(
                    variant,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
          Text('${item['quantity']} × \$${item['unit_price']}'),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Text(
              '\$${item['line_total']}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value, this.bold = false});

  final String label;
  final dynamic value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '\$$value',
            style: TextStyle(fontWeight: bold ? FontWeight.w700 : null),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.ctr, required this.paymentMethods});

  final OrderDetailController ctr;
  final Map<String, String> paymentMethods;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!ctr.canStart &&
          !ctr.canComplete &&
          !ctr.canCancel &&
          !ctr.canPay) {
        return const SizedBox.shrink();
      }

      // Guard against double taps while a lifecycle call is in flight.
      final bool busy = ctr.isActing.value;

      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (ctr.canStart)
            ElevatedButton.icon(
              onPressed: busy ? null : ctr.start,
              icon: const Icon(Icons.play_arrow),
              label: Text('Start Preparing'.tr),
            ),
          if (ctr.canComplete)
            ElevatedButton.icon(
              onPressed: busy ? null : ctr.complete,
              icon: const Icon(Icons.check),
              label: Text('Complete'.tr),
            ),
          if (ctr.canPay)
            ElevatedButton.icon(
              onPressed: busy ? null : () => _openPaymentSheet(context),
              icon: const Icon(Icons.payments),
              label: Text('Record Payment'.tr),
            ),
          if (ctr.canCancel)
            OutlinedButton.icon(
              onPressed: busy
                  ? null
                  : () => showConfirmDialog(
                        context: context,
                        message: 'Cancel this order?'.tr,
                        confirmText: 'Yes, cancel'.tr,
                        onConfirm: ctr.cancel,
                      ),
              icon: const Icon(Icons.cancel_outlined),
              label: Text('Cancel Order'.tr),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            ),
        ],
      );
    });
  }

  void _openPaymentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PaymentSheet(ctr: ctr, methods: paymentMethods),
    );
  }
}

class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet({required this.ctr, required this.methods});

  final OrderDetailController ctr;
  final Map<String, String> methods;

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  String _method = 'cash';
  final TextEditingController _reference = TextEditingController();

  @override
  void dispose() {
    _reference.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Obx(() {
          // The pay call finished (success swaps in the paid order, failure
          // toasts and reloads) — either way the sheet is done.
          if (!widget.ctr.isActing.value && !widget.ctr.canPay) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) Navigator.pop(context);
            });
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Record Payment'.tr,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                'The full total is always charged.'.tr,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _method,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Method',
                ),
                items: widget.methods.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value.tr),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _method = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reference,
                maxLength: 100,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Reference (optional)'.tr,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: widget.ctr.isActing.value
                      ? null
                      : () => widget.ctr
                              .pay(_method, reference: _reference.text.trim()),
                  child: Text('Pay'.tr),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
