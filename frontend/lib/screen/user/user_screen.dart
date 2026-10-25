import 'package:flutter/material.dart' hide SearchController;
import 'package:frontend/controllers/search_controller.dart';
import 'package:frontend/controllers/user_controller.dart';
import 'package:frontend/screen/user/widget/card_user_widget.dart';
import 'package:frontend/widget/custom_app_bar.dart';
import 'package:get/get.dart';

const _coffeeBrown = Color(0xFF5C4033);
const _caramel = Color(0xFFC58B50);
const _warmCream = Color(0xFFF8F6F2);
const _surfaceWhite = Color(0xFFFFFFFF);
const _mainText = Color(0xFF252525);
const _secondaryText = Color(0xFF858585);
const _softBorder = Color(0xFFE9E3DC);

class UserScreen extends StatelessWidget {
  UserScreen({super.key});

  final UserController ctr = Get.put(UserController());

  @override
  Widget build(BuildContext context) {
    // Read once: canManage decrypts storage, so don't call it per card.
    final bool canManage = ctr.canManage;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'User Management',
        showBack: true,
        onBack: () => Navigator.pop(context),
        showRefresh: true,
        onRefresh: ctr.onGetStaff,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textScaler = MediaQuery.textScalerOf(context);
            final textScale = textScaler.scale(14) / 14;
            final isCompact = constraints.maxWidth < 768 || textScale >= 1.25;
            final horizontalPadding = isCompact ? 16.0 : 28.0;

            return RefreshIndicator(
              onRefresh: ctr.onGetStaff,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PageHeader(
                      isCompact: isCompact,
                      canManage: canManage,
                      onAdd: () => ctr.onAddStaff(context),
                    ),
                    const SizedBox(height: 16),
                    if (canManage) ...[
                      _SearchAndFilters(
                        width: constraints.maxWidth,
                        textScale: textScale,
                        ctr: ctr,
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Outside the Obx: the no-access panel reads no observable,
                    // and an Obx with zero reads throws.
                    if (!canManage)
                      const _StatePanel(
                        icon: Icons.lock_outline_rounded,
                        title: 'Access restricted',
                        message: 'You do not have access to staff management.',
                      )
                    else
                      Obx(() => _buildBody(context)),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      backgroundColor: _warmCream,
    );
  }

  Widget _buildBody(BuildContext context) {
    if (ctr.isLoading.value && ctr.staffList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (ctr.staffList.isEmpty) {
      return const _StatePanel(
        icon: Icons.people_outline_rounded,
        title: 'No staff found',
        message: 'Add your first team member to get started.',
      );
    }

    if (ctr.searchStaffList.isEmpty) {
      return const _StatePanel(
        icon: Icons.search_off_rounded,
        title: 'Search not found',
        message: 'Try another name, employee code, role, or hire date.',
      );
    }

    return Column(
      children: ctr.searchStaffList.map((staff) {
        return CardUserWidget(
          staff: staff,
          onEdit: () => ctr.onEditStaff(context, staff),
          onDelete: () => ctr.onDeleteStaff(staff['id'], context),
        );
      }).toList(),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.isCompact,
    required this.canManage,
    required this.onAdd,
  });

  final bool isCompact;
  final bool canManage;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = Text(
      'User Management',
      style: theme.textTheme.headlineSmall?.copyWith(
        color: _mainText,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
    );
    final subtitle = Text(
      'Manage your café team and account access.',
      style: theme.textTheme.bodyMedium?.copyWith(color: _secondaryText),
    );
    final addButton = canManage
        ? ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.person_add_alt_1_outlined, size: 19),
            label: const Text('Add User'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _coffeeBrown,
              foregroundColor: _surfaceWhite,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          )
        : null;

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 6),
          subtitle,
          if (addButton != null) ...[
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerLeft, child: addButton),
          ],
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 6), subtitle],
          ),
        ),
        if (addButton != null) ...[
          const SizedBox(width: 20),
          addButton,
        ],
      ],
    );
  }
}

class _SearchAndFilters extends StatelessWidget {
  const _SearchAndFilters({
    required this.width,
    required this.textScale,
    required this.ctr,
  });

  final double width;
  final double textScale;
  final UserController ctr;

  @override
  Widget build(BuildContext context) {
    final roleFilter = Obx(
      () => _FilterField(
        icon: Icons.badge_outlined,
        value: ctr.roleFilter.value,
        options: const {
          'all': 'All roles',
          'owner': 'Owner',
          'admin': 'Admin',
          'manager': 'Manager',
          'cashier': 'Cashier',
        },
        onChanged: (value) {
          ctr.roleFilter.value = value;
          ctr.applyFilters();
        },
      ),
    );
    final statusFilter = Obx(
      () => _FilterField(
        icon: Icons.tune,
        value: ctr.statusFilter.value,
        options: const {
          'all': 'All statuses',
          'active': 'Active',
          'inactive': 'Inactive',
        },
        onChanged: (value) {
          ctr.statusFilter.value = value;
          ctr.applyFilters();
        },
      ),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _softBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stackFilters = constraints.maxWidth < 420 || textScale >= 1.4;
          final filterWidth = stackFilters
              ? constraints.maxWidth
              : (constraints.maxWidth - 12) / 2;

          final filters = stackFilters
              ? Column(
                  children: [
                    roleFilter,
                    const SizedBox(height: 12),
                    statusFilter,
                  ],
                )
              : Row(
                  children: [
                    SizedBox(width: filterWidth, child: roleFilter),
                    const SizedBox(width: 12),
                    SizedBox(width: filterWidth, child: statusFilter),
                  ],
                );

          if (width < 1200 || textScale >= 1.25) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SearchField(),
                const SizedBox(height: 8),
                filters,
              ],
            );
          }

          return Row(
            children: [
              const Expanded(child: _SearchField()),
              const SizedBox(width: 12),
              SizedBox(width: 170, child: roleFilter),
              const SizedBox(width: 12),
              SizedBox(width: 180, child: statusFilter),
            ],
          );
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    final search = Get.find<SearchController>();

    return Obx(
      () => TextField(
        controller: search.textController,
        decoration: InputDecoration(
          hintText: 'Search users...',
          hintStyle: const TextStyle(color: _secondaryText),
          prefixIcon: const Icon(Icons.search, size: 20, color: _coffeeBrown),
          suffixIcon: search.keyword.value.isEmpty
              ? null
              : IconButton(
                  onPressed: search.clear,
                  icon: const Icon(Icons.close),
                ),
          filled: true,
          fillColor: _surfaceWhite,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: _fieldBorder(),
          enabledBorder: _fieldBorder(),
          focusedBorder: _fieldBorder(),
        ),
      ),
    );
  }
}

class _FilterField extends StatelessWidget {
  const _FilterField({
    required this.icon,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final IconData icon;
  final String value;

  /// value => label; insertion order is the dropdown order.
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 19, color: _coffeeBrown),
        filled: true,
        fillColor: _surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        border: _fieldBorder(),
        enabledBorder: _fieldBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _secondaryText,
            size: 20,
          ),
          style: const TextStyle(fontSize: 14, color: _mainText),
          items: options.entries
              .map(
                (entry) => DropdownMenuItem(
                  value: entry.key,
                  child: Text(
                    entry.value.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (newValue) {
            if (newValue != null) onChanged(newValue);
          },
        ),
      ),
    );
  }
}

class _StatePanel extends StatelessWidget {
  const _StatePanel({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceWhite,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _caramel.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: _coffeeBrown),
          ),
          const SizedBox(height: 12),
          Text(
            title.tr,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: _mainText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Text(
              message.tr,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _secondaryText,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

OutlineInputBorder _fieldBorder() {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(11),
    borderSide: const BorderSide(color: _softBorder),
  );
}