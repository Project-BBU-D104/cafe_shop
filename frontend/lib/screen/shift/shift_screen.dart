import 'package:flutter/material.dart';
import 'package:frontend/controllers/shift_controller.dart';
import 'package:frontend/routes/app_routes.dart';
import 'package:frontend/utils/date_formatter.dart';
import 'package:frontend/widget/custom_app_bar.dart';
import 'package:get/get.dart';

class ShiftScreen extends StatelessWidget {
  ShiftScreen({super.key, this.gate = false});

  /// Blocking variant: no back arrow, and starting the shift opens home.
  final bool gate;

  final ShiftController ctr = Get.isRegistered<ShiftController>()
      ? Get.find<ShiftController>()
      : Get.put(ShiftController());

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Shift Management',
        showBack: !gate,
        onBack: () => Navigator.pop(context),
      ),
      body: RefreshIndicator(
        onRefresh: ctr.onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ctr.canManageOwnShift)
                  Obx(() {
                    if (ctr.isLoading.value && !ctr.hasOpenShift) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return ctr.hasOpenShift
                        ? _buildOpenShiftSection(context)
                        : _buildStartForm(context);
                  }),
                if (ctr.canViewHistory) _buildHistorySection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOpenShiftSection(BuildContext context) {
    final shift = ctr.currentShift.value!;
    final String notes = (shift['notes'] ?? '').toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Current Shift'.tr),
        const SizedBox(height: 8),
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.play_circle_outline,
                        color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Open'.tr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormatter.formatDateTime(
                        DateTime.tryParse((shift['started_at'] ?? '').toString())
                            ?.toLocal(),
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${'Opening cash'.tr}: ${shift['opening_cash'] ?? '—'}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (notes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      notes,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        _buildLabel('Close Shift'.tr),
        const SizedBox(height: 5),
        _buildTextField(
          errorKey: 'closing_cash',
          controller: ctr.closingCashController,
          hintText: 'Enter closing cash'.tr,
          prefixIcon: const Icon(Icons.attach_money),
          validator: _validateCash,
        ),
        const SizedBox(height: 15),
        _buildSubmitButton(
          context,
          label: 'Close Shift'.tr,
          onPressed: ctr.onCloseShift,
        ),
      ],
    );
  }

  Widget _buildStartForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Start Shift'.tr),
        const SizedBox(height: 5),
        _buildTextField(
          errorKey: 'opening_cash',
          controller: ctr.openingCashController,
          hintText: 'Enter opening cash'.tr,
          prefixIcon: const Icon(Icons.attach_money),
          validator: _validateCash,
        ),
        const SizedBox(height: 12),
        _buildLabel('Notes (optional)'.tr),
        const SizedBox(height: 5),
        _buildTextField(
          errorKey: 'notes',
          controller: ctr.startNotesController,
          hintText: 'Enter notes'.tr,
          prefixIcon: const Icon(Icons.notes),
          maxLines: 3,
        ),
        const SizedBox(height: 15),
        _buildSubmitButton(
          context,
          label: 'Start Shift'.tr,
          onPressed: () async {
            await ctr.onStartShift();
            // shortcut: another device may open the shift before this screen
            // loads; hasOpenShift is still true, so home is the right route.
            if (gate && ctr.hasOpenShift) Get.offAllNamed(AppRoutes.home);
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton(
    BuildContext context, {
    required String label,
    required Future<void> Function() onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: Obx(
        () => ElevatedButton(
          style: ElevatedButton.styleFrom(foregroundColor: Colors.white),
          onPressed: (ctr.isSaving.value || ctr.isLoading.value)
              ? null
              : () {
                  if (_formKey.currentState!.validate()) {
                    FocusScope.of(context).unfocus();
                    onPressed();
                  }
                },
          child: ctr.isSaving.value
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    return Obx(() {
      if (ctr.isLoadingHistory.value && ctr.shifts.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          _buildLabel('Shift History'.tr),
          const SizedBox(height: 8),
          if (ctr.shifts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No shifts yet'.tr,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          else
            // shortcut: plain ListView of the loaded pages; add infinite scroll if lists get long.
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ctr.shifts.length,
              itemBuilder: (context, index) =>
                  _buildHistoryRow(ctr.shifts[index]),
            ),
          if (ctr.historyPage.value < ctr.historyLastPage.value)
            Center(
              child: TextButton(
                onPressed: ctr.isLoadingHistory.value
                    ? null
                    : () => ctr.loadHistory(append: true),
                child: Text('Load more'.tr),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildHistoryRow(Map<String, dynamic> shift) {
    final bool isOpen = shift['ended_at'] == null;
    final String started = DateFormatter.formatDateTime(
      DateTime.tryParse((shift['started_at'] ?? '').toString())?.toLocal(),
    );
    final String ended = isOpen
        ? 'Open'.tr
        : DateFormatter.formatDateTime(
            DateTime.tryParse(shift['ended_at'].toString())?.toLocal(),
          );
    final MaterialColor tint = isOpen ? Colors.green : Colors.blueGrey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$started → $ended',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${'Opening'.tr}: ${shift['opening_cash'] ?? '—'}'
                    '${isOpen ? '' : '   ·   ${'Closing'.tr}: ${shift['closing_cash'] ?? '—'}'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: tint.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isOpen ? 'Open'.tr : 'Closed'.tr,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: tint.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
    );
  }

  String? _validateCash(String? value) => ctr.validateCash(value ?? '');

  Widget _buildTextField({
    required String errorKey,
    required TextEditingController controller,
    required String hintText,
    required Widget prefixIcon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Obx(() => TextFormField(
          controller: controller,
          keyboardType: keyboardType ??
              (maxLines == 1 && errorKey.endsWith('cash')
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : null),
          maxLines: maxLines,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: hintText,
            // Last 422 message for this field, if the API rejected it.
            errorText: ctr.serverErrors[errorKey],
            border: const OutlineInputBorder(),
            prefixIcon: prefixIcon,
          ),
          onChanged: (_) => ctr.serverErrors.remove(errorKey),
          validator: validator,
        ));
  }
}
