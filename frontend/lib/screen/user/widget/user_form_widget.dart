import 'package:flutter/material.dart';
import 'package:frontend/controllers/user_controller.dart';
import 'package:frontend/utils/date_formatter.dart';
import 'package:get/get.dart';

/// add    = new login user + staff profile (two API calls)
/// edit   = update the account name and the existing staff profile
/// attach = the user exists but has no staff profile yet (POST, not PUT)
enum UserFormMode { add, edit, attach }

/// One form for adding and editing staff, shown in a bottom sheet.
class UserFormWidget extends StatelessWidget {
  UserFormWidget({
    super.key,
    required this.title,
    required this.onSave,
    this.mode = UserFormMode.add,
  });

  final String title;
  final Future<void> Function() onSave;
  final UserFormMode mode;

  final UserController ctr = Get.find<UserController>();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool get _isAdd => mode == UserFormMode.add;
  bool get _isAttach => mode == UserFormMode.attach;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title.tr,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // A retry after the login user was created: only the profile is
              // sent, so keep the account fields from looking editable.
              if (_isAdd)
                Obx(
                  () => ctr.accountCreated.value
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'The account was already created. Only the staff details below will be saved.'.tr,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

              if (!_isAttach) ...[
                _buildLabel('Full Name'.tr),
                const SizedBox(height: 5),
                _buildTextField(
                  errorKey: 'name',
                  controller: ctr.nameController,
                  hintText: 'Enter full name'.tr,
                  prefixIcon: const Icon(Icons.person_outline),
                  freezeOnAccountCreated: true,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'Name is required'.tr;
                    if (text.length > 120) return 'Name is too long'.tr;
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ],

              if (_isAdd) ...[
                _buildLabel('Email'.tr),
                const SizedBox(height: 5),
                _buildTextField(
                  errorKey: 'email',
                  controller: ctr.emailController,
                  hintText: 'Enter email'.tr,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.mail_outline),
                  freezeOnAccountCreated: true,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'Email is required'.tr;
                    if (!text.contains('@')) {
                      return 'Enter a valid email'.tr;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                _buildLabel('Password'.tr),
                const SizedBox(height: 5),
                _buildTextField(
                  errorKey: 'password',
                  controller: ctr.passwordController,
                  hintText: 'At least 8 characters'.tr,
                  prefixIcon: const Icon(Icons.lock_outline),
                  obscureText: true,
                  freezeOnAccountCreated: true,
                  validator: (value) {
                    final text = value ?? '';
                    if (text.isEmpty) return 'Password is required'.tr;
                    if (text.length < 8) {
                      return 'Password must be at least 8 characters'.tr;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                _buildLabel('Role'.tr),
                const SizedBox(height: 5),
                _buildRoleDropdown(),
                const SizedBox(height: 12),
              ] else
                _buildAccountSummary(),

              if (!_isAttach) ...[
                _buildLabel('Phone'.tr),
                const SizedBox(height: 5),
                _buildTextField(
                  errorKey: 'phone',
                  controller: ctr.phoneController,
                  hintText: 'Optional'.tr,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.length > 30) return 'Phone is too long'.tr;
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ],

              _buildLabel('Employee Code'.tr),
              const SizedBox(height: 5),
              _buildTextField(
                errorKey: 'employee_code',
                controller: ctr.employeeCodeController,
                hintText: 'e.g. EMP-001'.tr,
                prefixIcon: const Icon(Icons.badge_outlined),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'Employee code is required'.tr;
                  }
                  if (text.length > 30) {
                    return 'Employee code is too long'.tr;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              _buildLabel('Hire Date'.tr),
              const SizedBox(height: 5),
              _buildHireDateField(context),

              const SizedBox(height: 12),

              _buildLabel('Hourly Rate'.tr),
              const SizedBox(height: 5),
              _buildTextField(
                errorKey: 'hourly_rate',
                controller: ctr.hourlyRateController,
                hintText: 'Optional'.tr,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: const Icon(Icons.attach_money),
                validator: _validateAmount,
              ),

              const SizedBox(height: 12),

              _buildLabel('Emergency Contact'.tr),
              const SizedBox(height: 5),
              _buildTextField(
                errorKey: 'emergency_contact',
                controller: ctr.emergencyContactController,
                hintText: 'Optional'.tr,
                prefixIcon: const Icon(Icons.emergency_outlined),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.length > 255) {
                    return 'Emergency contact is too long'.tr;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 45,
                child: Obx(
                  () => ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    onPressed: ctr.isLoading.value
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              FocusScope.of(context).unfocus();
                              onSave();
                            }
                          },
                    child: ctr.isLoading.value
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Save'.tr,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Edit mode: the API cannot change email or role, so show them read-only
  // instead of rendering fields that would silently do nothing.
  Widget _buildAccountSummary() {
    final email = ctr.emailController.text.isEmpty
        ? 'No email'.tr
        : ctr.emailController.text;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$email · ${ctr.roleController.value}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Email and role cannot be changed.'.tr,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return Obx(
      () => InputDecorator(
        decoration: InputDecoration(
          errorText: ctr.serverErrors['role'],
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.badge_outlined),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: ctr.roleController.value,
            isExpanded: true,
            isDense: true,
            items: [
              DropdownMenuItem(value: 'cashier', child: Text('Cashier'.tr)),
              DropdownMenuItem(value: 'manager', child: Text('Manager'.tr)),
              DropdownMenuItem(value: 'admin', child: Text('Admin'.tr)),
              // POST /users rejects owner; the API cannot assign it.
              DropdownMenuItem(
                value: 'owner',
                enabled: false,
                child: Text('Owner (not assignable)'.tr),
              ),
            ],
            onChanged: ctr.accountCreated.value
                ? null
                : (value) {
                    if (value == null) return;
                    ctr.roleController.value = value;
                    ctr.serverErrors.remove('role');
                  },
          ),
        ),
      ),
    );
  }

  Widget _buildHireDateField(BuildContext context) {
    return Obx(
      () => TextFormField(
        controller: ctr.hireDateController,
        readOnly: true,
        onTap: () => _pickHireDate(context),
        decoration: InputDecoration(
          hintText: 'Select hire date'.tr,
          errorText: ctr.serverErrors['hire_date'],
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.event_outlined),
          suffixIcon: IconButton(
            tooltip: 'Clear',
            icon: const Icon(Icons.clear),
            onPressed: () {
              ctr.hireDateController.clear();
              ctr.serverErrors.remove('hire_date');
            },
          ),
        ),
        onChanged: (_) => ctr.serverErrors.remove('hire_date'),
        // The picker writes YYYY-MM-DD, which is what the API expects.
        validator: (value) {
          final text = value?.trim() ?? '';
          if (text.isEmpty) return null;
          if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) {
            return 'Enter a valid date'.tr;
          }
          return null;
        },
      ),
    );
  }

  Future<void> _pickHireDate(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = DateTime(2000);
    final lastDate = DateTime(now.year + 1, 12, 31);

    // A stored date may predate the range or be future-dated; the picker
    // asserts unless initialDate is inside [firstDate, lastDate].
    final proposed = DateTime.tryParse(ctr.hireDateController.text) ?? now;
    final initialDate = proposed.isBefore(firstDate)
        ? firstDate
        : (proposed.isAfter(lastDate) ? lastDate : proposed);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      ctr.hireDateController.text =
          DateFormatter.formatDate(picked, pattern: 'yyyy-MM-dd');
      ctr.serverErrors.remove('hire_date');
    }
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    );
  }

  // Optional amount: server stays authoritative on precision (decimal:0,2).
  String? _validateAmount(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return null;
    }

    final number = double.tryParse(text);

    if (number == null || number < 0) {
      return 'Enter a valid non-negative number'.tr;
    }

    return null;
  }

  Widget _buildTextField({
    required String errorKey,
    required TextEditingController controller,
    required String hintText,
    required Widget prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool freezeOnAccountCreated = false,
    String? Function(String?)? validator,
  }) {
    return Obx(() => TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          enabled: !(freezeOnAccountCreated && ctr.accountCreated.value),
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