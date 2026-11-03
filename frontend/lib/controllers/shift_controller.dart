import 'package:flutter/material.dart';
import 'package:frontend/global.dart';
import 'package:frontend/services/main_service/shift_service.dart';
import 'package:frontend/widget/toast_widget.dart';
import 'package:get/get.dart';

class ShiftController extends GetxController {
  final ShiftService _service;

  ShiftController({ShiftService? service}) : _service = service ?? ShiftService();

  /// The caller's open shift, or null.
  final Rxn<Map<String, dynamic>> currentShift = Rxn();

  /// Shop-wide shift history (manager and above only).
  final RxList<Map<String, dynamic>> shifts = <Map<String, dynamic>>[].obs;
  final RxInt historyPage = 1.obs;
  final RxInt historyLastPage = 1.obs;

  final RxBool isLoading = false.obs;
  final RxBool isLoadingHistory = false.obs;
  final RxBool isSaving = false.obs;

  // Last 422 from the API, field => message, shown under the matching form field.
  final RxMap<String, String> serverErrors = <String, String>{}.obs;

  final openingCashController = TextEditingController();
  final startNotesController = TextEditingController();
  final closingCashController = TextEditingController();

  /// Same rule as GET /shifts (role:owner,admin,manager).
  bool get canViewHistory {
    final user = storage.lastUserLoginRead['user'];
    final String role = user is Map ? (user['role'] ?? '').toString() : '';

    return const ['owner', 'admin', 'manager'].contains(role);
  }

  bool get hasOpenShift => currentShift.value != null;

  @override
  void onInit() {
    super.onInit();
    loadCurrent();
    loadHistory();
  }

  @override
  void onClose() {
    openingCashController.dispose();
    startNotesController.dispose();
    closingCashController.dispose();
    super.onClose();
  }

  Future<void> loadCurrent() async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;

      final resp = await _service.getCurrent();

      currentShift.value = resp is Map && resp['data'] is Map
          ? Map<String, dynamic>.from(resp['data'] as Map)
          : null;
    } catch (e) {
      ToastWidget.show(
        message: 'Failed to load current shift: $e',
        type: ToastType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadHistory({bool append = false, bool silent = false}) async {
    // Cashiers cannot read the history; skip the guaranteed 403.
    if (!canViewHistory) return;

    try {
      isLoadingHistory.value = true;

      final page = append ? historyPage.value + 1 : 1;
      final resp = await _service.getShifts(page: page);

      if (resp is Map && resp['data'] is List) {
        final rows = (resp['data'] as List).map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(item as Map),
        );
        if (append) {
          shifts.addAll(rows);
        } else {
          shifts.assignAll(rows);
        }
        historyPage.value = page;
        final meta = resp['meta'];
        if (meta is Map && meta['last_page'] is int) {
          historyLastPage.value = meta['last_page'] as int;
        }
      } else if (!append) {
        shifts.clear();
      }
    } catch (e) {
      // After start/close the shift is already saved; don't alarm the user
      // with a failed reload.
      if (!silent) {
        ToastWidget.show(
          message: 'Failed to load shift history: $e',
          type: ToastType.error,
        );
      }
    } finally {
      isLoadingHistory.value = false;
    }
  }

  Future<void> onRefresh() => Future.wait([loadCurrent(), loadHistory()]);

  /// Mirrors StartShiftRequest/CloseShiftRequest: numeric, min 0, max 2 decimals.
  @visibleForTesting
  String? validateCash(String text) =>
      RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(text.trim())
          ? null
          : 'Enter a valid amount'.tr;

  @visibleForTesting
  Map<String, dynamic> buildStartPayload() {
    final notes = startNotesController.text.trim();

    return {
      'opening_cash': double.parse(openingCashController.text.trim()),
      if (notes.isNotEmpty) 'notes': notes,
    };
  }

  /// CloseShiftRequest has no notes field — never send one.
  @visibleForTesting
  Map<String, dynamic> buildClosePayload() => {
        'closing_cash': double.parse(closingCashController.text.trim()),
      };
}
