import 'package:flutter/material.dart';
import 'package:get/get.dart';

const _coffeeBrown = Color(0xFF5C4033);
const _caramel = Color(0xFFC58B50);
const _softBorder = Color(0xFFE9E3DC);

/// The API sends real booleans; the string forms cover cached/legacy payloads.
bool staffIsActive(dynamic value) =>
    value == true || value == 1 || value == '1' || value == 'true';

Map<String, dynamic>? staffProfileOf(Map<String, dynamic> staff) {
  final profile = staff['staff_profile'];
  return profile is Map ? Map<String, dynamic>.from(profile) : null;
}

class CardUserWidget extends StatelessWidget {
  final Map<String, dynamic> staff;
  final VoidCallback? onEdit;

  /// Deactivates the account. Never shown for inactive staff (no reactivation).
  final VoidCallback? onDelete;

  const CardUserWidget({
    super.key,
    required this.staff,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final String name = (staff['name'] ?? '').toString();
    final String email = (staff['email'] ?? '').toString();
    final String role = (staff['role'] ?? '').toString();

    final profile = staffProfileOf(staff);
    final bool isActive = staffIsActive(staff['is_active']);

    final String employeeCode = (profile?['employee_code'] ?? '').toString();
    final String hireDate = (profile?['hire_date'] ?? '').toString();
    final String hourlyRate = (profile?['hourly_rate'] ?? '').toString();

    final profileLine = profile == null
        ? 'No staff profile'.tr
        : [
            employeeCode,
            if (hireDate.isNotEmpty) 'hired $hireDate',
            if (hourlyRate.isNotEmpty) '$hourlyRate/hr',
          ].join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _softBorder),
        boxShadow: [
          BoxShadow(
            color: _coffeeBrown.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _caramel.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.person_outline_rounded,
              color: _coffeeBrown,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Unnamed staff' : name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  email.isEmpty ? role : '$email · $role',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 5),
                Text(
                  profileLine,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isActive ? 'Active'.tr : 'Inactive'.tr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _caramel.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        role.isEmpty ? '-' : role,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _coffeeBrown,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          StaffActionsMenu(
            hasProfile: profile != null,
            isActive: isActive,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        ],
      ),
    );
  }
}

/// Shared per-row actions for the card (compact) and table (wide) views.
class StaffActionsMenu extends StatelessWidget {
  const StaffActionsMenu({
    super.key,
    required this.hasProfile,
    required this.isActive,
    this.onEdit,
    this.onDelete,
  });

  final bool hasProfile;
  final bool isActive;
  final VoidCallback? onEdit;

  /// Deactivates the account. Never shown for inactive staff (no reactivation).
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final bool canDeactivate = isActive && onDelete != null;
    if (onEdit == null && !canDeactivate) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        if (value == 'edit') {
          onEdit?.call();
        } else if (value == 'delete') {
          onDelete?.call();
        }
      },
      itemBuilder: (context) => [
        if (onEdit != null)
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                const Icon(Icons.edit_outlined, size: 20),
                const SizedBox(width: 10),
                Text(hasProfile ? 'Edit'.tr : 'Add profile'.tr),
              ],
            ),
          ),
        if (canDeactivate)
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.person_off_outlined, size: 20, color: Colors.red),
                const SizedBox(width: 10),
                Text(
                  'Deactivate'.tr,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
      ],
    );
  }
}