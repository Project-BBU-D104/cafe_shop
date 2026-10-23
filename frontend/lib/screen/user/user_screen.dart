import 'package:flutter/material.dart';
import 'package:frontend/widget/custom_app_bar.dart';

const _coffeeBrown = Color(0xFF5C4033);
const _caramel = Color(0xFFC58B50);
const _warmCream = Color(0xFFF8F6F2);
const _surfaceWhite = Color(0xFFFFFFFF);
const _mainText = Color(0xFF252525);
const _secondaryText = Color(0xFF858585);
const _softBorder = Color(0xFFE9E3DC);

class UserScreen extends StatelessWidget {
  const UserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'User Management',
        showBack: true,
        onBack: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textScaler = MediaQuery.textScalerOf(context);
            final textScale = textScaler.scale(14) / 14;
            final isCompact = constraints.maxWidth < 768 || textScale >= 1.25;
            final horizontalPadding = isCompact ? 16.0 : 28.0;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PageHeader(isCompact: isCompact),
                  const SizedBox(height: 16),
                  _SearchAndFilters(
                    width: constraints.maxWidth,
                    textScale: textScale,
                  ),
                  const SizedBox(height: 16),
                  const _EmptyUsersPanel(),
                ],
              ),
            );
          },
        ),
      ),
      backgroundColor: _warmCream,
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.isCompact});

  final bool isCompact;

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
    final addButton = ElevatedButton.icon(
      onPressed: null,
      icon: const Icon(Icons.person_add_alt_1_outlined, size: 19),
      label: const Text('Add User'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _coffeeBrown,
        foregroundColor: _surfaceWhite,
        disabledBackgroundColor: _coffeeBrown,
        disabledForegroundColor: _surfaceWhite,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 6),
          subtitle,
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerLeft, child: addButton),
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
        const SizedBox(width: 20),
        addButton,
      ],
    );
  }
}

class _SearchAndFilters extends StatelessWidget {
  const _SearchAndFilters({required this.width, required this.textScale});

  final double width;
  final double textScale;

  @override
  Widget build(BuildContext context) {
    final roleFilter = _FilterField(
      label: 'All roles',
      icon: Icons.badge_outlined,
    );
    final statusFilter = _FilterField(label: 'All statuses', icon: Icons.tune);

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
    return TextField(
      enabled: false,
      decoration: InputDecoration(
        hintText: 'Search users...',
        hintStyle: const TextStyle(color: _secondaryText),
        prefixIcon: const Icon(Icons.search, size: 20, color: _coffeeBrown),
        filled: true,
        fillColor: _surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: _fieldBorder(),
        enabledBorder: _fieldBorder(),
        disabledBorder: _fieldBorder(),
      ),
    );
  }
}

class _FilterField extends StatelessWidget {
  const _FilterField({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InputDecorator(
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 19, color: _coffeeBrown),
        filled: true,
        fillColor: _surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: _fieldBorder(),
        enabledBorder: _fieldBorder(),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(color: _mainText),
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _secondaryText,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _EmptyUsersPanel extends StatelessWidget {
  const _EmptyUsersPanel();

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
            child: Icon(
              Icons.people_outline_rounded,
              size: 28,
              color: _coffeeBrown,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'User directory is not connected yet.',
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
              'Connect user management to display team members, roles, and '
              'account status here.',
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
