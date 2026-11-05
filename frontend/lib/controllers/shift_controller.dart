import 'package:flutter/material.dart';
import 'package:frontend/global.dart';
import 'package:frontend/routes/app_routes.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/main_service/shift_service.dart';
import 'package:frontend/utils/session.dart';
import 'package:frontend/utils/shift_gate.dart';
import 'package:frontend/widget/toast_widget.dart';
import 'package:get/get.dart';

class ShiftController extends GetxController {
  final ShiftService _service;

  /// True on the blocking gate screen: open home once a shift exists.
  final bool gate;

  ShiftController({ShiftService? service, this.gate = false})
      : _service = service ?? ShiftService();

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

  String get _role {
    final user = storage.lastUserLoginRead['user'];
    return user is Map ? (user['role'] ?? '').toString() : '';
  }

  /// Same rule as GET /shifts (role:owner,admin,manager).
  bool get canViewHistory => const ['owner', 'admin', 'manager'].contains(_role);

  /// Same rule as shifts/start (role:cashier,manager).
  bool get canManageOwnShift => const ['cashier', 'manager'].contains(_role);

  /// Closing the shift ends the cashier's session; other roles keep working.
  bool get isCashier => _role == 'cashier';

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
    if (!canManageOwnShift) return; // guaranteed 403 for owner/admin
    if (isLoading.value) return;

    try {
      isLoading.value = true;

      final resp = await _service.getCurrent();

      currentShift.value = resp is Map && resp['data'] is Map
          ? Map<String, dynamic>.from(resp['data'] as Map)
          : null;
      setShiftGateOpen(hasOpenShift);

      // Deep-link/reload with a shift already open: let it through.
      if (gate && hasOpenShift) Get.offAllNamed(AppRoutes.home);
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
  /// Used by the screen's form validators too, so not test-only.
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

  static const _formFields = {'opening_cash', 'notes', 'closing_cash'};

  /// Blocking warning; dismissing it still continues to the logout below.
  Future<void> _showShiftClosedDialog() {
    return Get.dialog<void>(
      AlertDialog(
        title: Text('Shift Closed'.tr),
        content: Text(
          'Your shift has been closed. You will be logged out now.'.tr,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('OK'.tr),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _handleActionError(Object e) async {
    if (e is ValidationException) {
      // Show each message under its own field instead of a generic toast.
      serverErrors.assignAll(
        e.errors.map(
          (field, messages) => MapEntry(
            field,
            messages is List && messages.isNotEmpty
                ? messages.first.toString()
                : messages.toString(),
          ),
        ),
      );

      // Nothing maps to a visible field — fall back so the user isn't stuck.
      if (!e.errors.keys.any(_formFields.contains)) {
        ToastWidget.show(
          message: e.message,
          type: ToastType.error,
        );
      }
      return;
    }

    // 409 (already open/closed), network, anything else: show the server
    // message, then reload so the screen matches the server again.
    ToastWidget.show(
      message: e.toString(),
      type: ToastType.error,
    );
    await loadCurrent();
  }

  Future<void> onStartShift() async {
    if (isSaving.value) return;

    serverErrors.clear();

    final cashError = validateCash(openingCashController.text);
    if (cashError != null) {
      serverErrors['opening_cash'] = cashError;
      return;
    }

    try {
      isSaving.value = true;

      final resp = await _service.start(buildStartPayload());

      if (resp is Map && resp['data'] is Map) {
        currentShift.value = Map<String, dynamic>.from(resp['data'] as Map);
      }
      setShiftGateOpen(true);

      openingCashController.clear();
      startNotesController.clear();

      await loadHistory(silent: true);

      ToastWidget.show(
        message: 'Shift started successfully'.tr,
        type: ToastType.success,
      );
    } catch (e) {
      await _handleActionError(e);
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> onCloseShift() async {
    final shift = currentShift.value;
    if (shift == null || isSaving.value) return;

    serverErrors.clear();

    final cashError = validateCash(closingCashController.text);
    if (cashError != null) {
      serverErrors['closing_cash'] = cashError;
      return;
    }

    try {
      isSaving.value = true;

      await _service.close(shift['id'] as int, buildClosePayload());

      currentShift.value = null;
      setShiftGateOpen(false);
      closingCashController.clear();

      await loadHistory(silent: true);

      if (isCashier) {
        await _showShiftClosedDialog();
        logout();
        return;
      }

      ToastWidget.show(
        message: 'Shift closed successfully'.tr,
        type: ToastType.success,
      );
    } catch (e) {
      await _handleActionError(e);
    } finally {
      isSaving.value = false;
    }
  }
}
