import 'package:flutter/material.dart' hide SearchController;
import 'package:frontend/controllers/search_controller.dart';
import 'package:frontend/global.dart';
import 'package:frontend/helper/confirm_dialog_helper.dart';
import 'package:frontend/screen/user/widget/user_form_widget.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/main_service/staff_service.dart';
import 'package:frontend/widget/bottom_sheets.dart';
import 'package:frontend/widget/toast_widget.dart';
import 'package:get/get.dart';

class UserController extends GetxController {
  UserController([StaffService? service]) : service = service ?? StaffService();

  final StaffService service;
  final RxList<Map<String, dynamic>> staffList = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final searchStaffList = <Map<String, dynamic>>[].obs;

  // Last 422 from the API, field => message, shown under the matching form field.
  final RxMap<String, String> serverErrors = <String, String>{}.obs;

  final RxString roleFilter = 'all'.obs;
  final RxString statusFilter = 'all'.obs;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final employeeCodeController = TextEditingController();
  final hireDateController = TextEditingController();
  final hourlyRateController = TextEditingController();
  final emergencyContactController = TextEditingController();
  final roleController = 'cashier'.obs;

  // True once POST /users succeeded inside the Add sheet. The form freezes the
  // account fields then, so a retry only re-sends the profile and nothing the
  // user typed afterwards is silently discarded.
  final RxBool accountCreated = false.obs;

  // Set once POST /users succeeded, so a retry only re-sends the staff profile.
  int? _pendingUserId;
  String _keyword = '';
  Worker? _searchWorker;

  /// Only these roles may manage staff (same rule as the API).
  bool get canManage {
    final user = storage.lastUserLoginRead['user'];
    final String role = user is Map ? (user['role'] ?? '').toString() : '';

    return const ['owner', 'admin'].contains(role);
  }

  @override
  void onInit() {
    super.onInit();
    onGetStaff();

    final search = Get.put(SearchController());

    // Shared search box: drop any leftover keyword from another screen.
    search.clear();

    _searchWorker = ever(search.keyword, onSearchStaff);
  }

  @override
  void onClose() {
    _searchWorker?.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    employeeCodeController.dispose();
    hireDateController.dispose();
    hourlyRateController.dispose();
    emergencyContactController.dispose();
    super.onClose();
  }

  void onClear() {
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    phoneController.clear();
    employeeCodeController.clear();
    hireDateController.clear();
    hourlyRateController.clear();
    emergencyContactController.clear();
    roleController.value = 'cashier';
    serverErrors.clear();
    _pendingUserId = null;
    accountCreated.value = false;
  }

  Future<void> onGetStaff() async {
    // Non-owner/admin roles cannot read staff; skip the guaranteed 403.
    if (!canManage) return;

    try {
      isLoading.value = true;

      final resp = await service.getStaff();

      if (resp is Map && resp['data'] is List) {
        final List<dynamic> data = resp['data'];

        staffList.assignAll(
          data.map<Map<String, dynamic>>(
            (item) => Map<String, dynamic>.from(item as Map),
          ),
        );

        // Keep the active keyword and filters applied to the fresh list.
        applyFilters();
      } else {
        staffList.clear();
        searchStaffList.clear();
      }
    } catch (e) {
      ToastWidget.show(
        message: 'Failed to load staff: $e',
        type: ToastType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void onSearchStaff(String keyword) {
    _keyword = keyword.trim().toLowerCase();
    applyFilters();
  }

  /// Keyword (name, employee code, role, hire date) x role x status, client-side:
  /// the staff endpoint has no search or filter parameters.
  void applyFilters() {
    final role = roleFilter.value;
    final status = statusFilter.value;

    searchStaffList.value = staffList.where((staff) {
      final profile = staff['staff_profile'];
      final profileMap = profile is Map ? profile : null;

      final haystack = [
        staff['name'],
        staff['role'],
        profileMap?['employee_code'],
        profileMap?['hire_date'],
      ].map((value) => (value ?? '').toString().toLowerCase()).join(' ');

      if (_keyword.isNotEmpty && !haystack.contains(_keyword)) return false;

      if (role != 'all' && (staff['role'] ?? '').toString() != role) {
        return false;
      }

      if (status != 'all') {
        final bool active = _isActive(staff['is_active']);
        if (status == 'active' && !active) return false;
        if (status == 'inactive' && active) return false;
      }

      return true;
    }).toList();
  }

  bool _isActive(dynamic value) {
    return value == true || value == 1 || value == '1' || value == 'true';
  }

  @visibleForTesting
  Map<String, dynamic> buildUserPayload() {
    final password = passwordController.text;

    return {
      'name': nameController.text.trim(),
      'email': emailController.text.trim(),
      'password': password,
      'password_confirmation': password,
      'role': roleController.value,
    };
  }

  // Blank optional -> null, otherwise clearing a field would keep the old value.
  Map<String, dynamic> _profileFields() {
    return {
      'employee_code': employeeCodeController.text.trim(),
      'hire_date': _blankToNull(hireDateController.text),
      'hourly_rate': _blankToNull(hourlyRateController.text),
      'emergency_contact': _blankToNull(emergencyContactController.text),
    };
  }

  @visibleForTesting
  Map<String, dynamic> buildStaffPayload(int userId) {
    return {'user_id': userId, ..._profileFields()};
  }

  @visibleForTesting
  Map<String, dynamic> buildUpdatePayload() {
    return {
      'name': nameController.text.trim(),
      'phone': _blankToNull(phoneController.text),
      ..._profileFields(),
    };
  }

  String? _blankToNull(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  // Fields that exist in the form; a 422 on any other key falls back to a toast.
  static const _formFields = {
    'name',
    'email',
    'password',
    'role',
    'phone',
    'employee_code',
    'hire_date',
    'hourly_rate',
    'emergency_contact',
  };

  void _handleSaveError(Object e) {
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

    ToastWidget.show(
      message: e.toString(),
      type: ToastType.error,
    );
  }

  // The user can dismiss the sheet while a request runs; a blind Get.back()
  // would then pop this screen instead.
  void _closeSheet() {
    if (Get.routing.route is ModalBottomSheetRoute) {
      Get.back();
    }
  }

  void onAddStaff(BuildContext context) {
    // A sheet opened mid-save would overwrite the same form controllers.
    if (isLoading.value) return;

    // The edit sheet fills the same controllers; start from a blank form.
    onClear();

    AppBottomSheets.show(
      context,
      child: UserFormWidget(
        title: 'Add Staff',
        mode: UserFormMode.add,
        onSave: onSaveStaffCreate,
      ),
    );
  }

  Future<void> onSaveStaffCreate() async {
    // Snapshot the form before the first await: the sheet stays editable while
    // the request runs, and later edits must not leak into this save.
    final userPayload = buildUserPayload();
    final profileFields = _profileFields();
    final phone = phoneController.text.trim();

    try {
      isLoading.value = true;
      serverErrors.clear();

      var userId = _pendingUserId;

      // A new staff member is a login user plus a staff profile: two calls.
      if (userId == null) {
        final resp = await service.createUser(userPayload);
        final created = resp is Map ? resp['data'] : null;

        if (created is! Map) {
          throw Exception('Invalid user response: $resp');
        }

        userId = created['id'] as int;
        _pendingUserId = userId;
        // The login user now exists; freeze its fields so a retry only
        // re-sends the profile instead of silently dropping edits.
        accountCreated.value = true;
      }

      await service.createStaff({'user_id': userId, ...profileFields});
      _pendingUserId = null;

      // POST /users takes no phone; save it right after so the form stays honest.
      if (phone.isNotEmpty) {
        try {
          await service.updateStaff(userId, {'phone': phone});
        } catch (e) {
          ToastWidget.show(
            message: 'Staff saved, but phone was not: $e',
            type: ToastType.error,
          );
        }
      }

      await onGetStaff();

      onClear();
      _closeSheet();

      ToastWidget.show(
        message: 'Staff added successfully',
        type: ToastType.success,
      );
    } catch (e) {
      // The login user already exists if the profile call failed; show it so the
      // next Save only retries the profile instead of hitting "email taken".
      if (_pendingUserId != null) await onGetStaff();
      _handleSaveError(e);
    } finally {
      isLoading.value = false;
    }
  }

  void onEditStaff(BuildContext context, Map<String, dynamic> staff) {
    // A sheet opened mid-save would overwrite the same form controllers.
    if (isLoading.value) return;

    final profile = staff['staff_profile'];
    final profileMap = profile is Map ? profile : null;

    // There is no GET staff/{id}; fill the form from the row we already have.
    nameController.text = (staff['name'] ?? '').toString();
    emailController.text = (staff['email'] ?? '').toString();
    phoneController.text = (staff['phone'] ?? '').toString();
    roleController.value = (staff['role'] ?? 'cashier').toString();
    employeeCodeController.text =
        (profileMap?['employee_code'] ?? '').toString();
    hireDateController.text = (profileMap?['hire_date'] ?? '').toString();
    // Server sends hourly_rate as a string ("8.50"); keep it untouched.
    hourlyRateController.text = (profileMap?['hourly_rate'] ?? '').toString();
    emergencyContactController.text =
        (profileMap?['emergency_contact'] ?? '').toString();
    serverErrors.clear();
    _pendingUserId = null;
    accountCreated.value = false;

    final userId = staff['id'] as int;
    final isAttach = profileMap == null;

    AppBottomSheets.show(
      context,
      child: UserFormWidget(
        // PUT 404s without a profile, so a profile-less user gets POST instead.
        title: isAttach ? 'Add Staff Profile' : 'Edit Staff',
        mode: isAttach ? UserFormMode.attach : UserFormMode.edit,
        onSave: isAttach
            ? () => onAttachStaffProfile(userId)
            : () => onSaveStaffUpdate(userId),
      ),
    );
  }

  Future<void> onSaveStaffUpdate(int userId) async {
    try {
      isLoading.value = true;
      serverErrors.clear();

      await service.updateStaff(userId, buildUpdatePayload());

      // Refresh
      await onGetStaff();
      onClear();
      _closeSheet();

      ToastWidget.show(
        message: 'Staff updated successfully',
        type: ToastType.success,
      );
    } catch (e) {
      _handleSaveError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> onAttachStaffProfile(int userId) async {
    try {
      isLoading.value = true;
      serverErrors.clear();

      await service.createStaff(buildStaffPayload(userId));

      await onGetStaff();
      onClear();
      _closeSheet();

      ToastWidget.show(
        message: 'Staff profile added successfully',
        type: ToastType.success,
      );
    } catch (e) {
      _handleSaveError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> onDeleteStaff(int userId, BuildContext context) async {
    // The API also refuses this (422); check here first for a friendly message.
    final user = storage.lastUserLoginRead['user'];
    if (user is Map && user['id']?.toString() == userId.toString()) {
      ToastWidget.show(
        message: 'You cannot deactivate your own account',
        type: ToastType.error,
      );
      return;
    }

    showConfirmDialog(
      context: context,
      title: 'Deactivate staff',
      message:
          'This deactivates the account so the person can no longer sign in. It cannot be undone here.',
      confirmText: 'Deactivate',
      onConfirm: () async {
        try {
          await service.deleteStaff(userId);

          // Refresh staff list
          await onGetStaff();

          ToastWidget.show(
            message: 'Staff deactivated successfully',
            type: ToastType.success,
          );
        } catch (e) {
          ToastWidget.show(
            message: e.toString(),
            type: ToastType.error,
          );
        }
      },
      onCancel: () {
        // Do nothing
      },
    );
  }
}