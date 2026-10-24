import 'package:flutter/material.dart';
import 'package:frontend/controllers/category_controller.dart';
import 'package:frontend/screen/category/category_management_theme.dart';
import 'package:frontend/screen/category/widget/card_category_widget.dart';
import 'package:frontend/utils/date_formatter.dart';
import 'package:frontend/widget/custom_app_bar.dart';
import 'package:frontend/widget/search_widget.dart';
import 'package:get/get.dart';

class CategoryScreen extends StatelessWidget {
  CategoryScreen({super.key});

  final CategoryController cateCtr = Get.put(CategoryController());

  @override
  Widget build(BuildContext context) {
    return CategoryManagementTheme(
      child: Builder(
        builder: (categoryContext) => Scaffold(
          appBar: CustomAppBar(
            title: 'Category Management',
            showBack: true,
            centerTitle: false,
            onBack: () => Navigator.pop(categoryContext),
            onRefresh: cateCtr.onGetCategories,
            showRefresh: true,
          ),
          body: RefreshIndicator(
            onRefresh: cateCtr.onGetCategories,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = constraints.maxWidth < 600
                    ? 16.0
                    : constraints.maxWidth < 1200
                    ? 24.0
                    : 32.0;

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    20,
                    horizontalPadding,
                    96,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CategoryPageHeader(),
                      const SizedBox(height: 20),
                      SearchWidget(title: 'Search Category'),
                      const SizedBox(height: 16),
                      _CategoryContent(
                        controller: cateCtr,
                        actionContext: categoryContext,
                        onCategoryTap: (category) =>
                            _showCategoryDetails(categoryContext, category),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => cateCtr.onAddCategory(categoryContext),
            icon: const Icon(Icons.add_rounded),
            label: Text('Add Category'.tr),
          ),
        ),
      ),
    );
  }

  void _showCategoryDetails(
    BuildContext context,
    Map<String, dynamic> category,
  ) {
    final name = (category['name'] ?? '').toString();
    final description = (category['description'] ?? '').toString();
    final categoryId = category['id'];
    final isActive = _isCategoryActive(category);
    final sortOrder = category['sort_order'] ?? category['sortOrder'];
    final createdAt = category['created_at']?.toString();
    final updatedAt = category['updated_at']?.toString();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final screenSize = MediaQuery.sizeOf(dialogContext);

        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: screenSize.width < 520 ? 16 : 32,
            vertical: 24,
          ),
          contentPadding: EdgeInsets.zero,
          titlePadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 560,
              maxHeight: screenSize.height * 0.78,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Category Details'.tr,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close'.tr,
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.category_outlined,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name.isEmpty ? 'Unnamed category'.tr : name,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _CategoryStatusBadge(isActive: isActive),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Text(
                      'Category Information'.tr,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (categoryId != null)
                    _CategoryDetailRow(
                      icon: Icons.tag_rounded,
                      label: 'Category ID'.tr,
                      value: categoryId.toString(),
                    ),
                  _CategoryDetailRow(
                    icon: Icons.circle_outlined,
                    label: 'Status'.tr,
                    value: (isActive ? 'Active' : 'Inactive').tr,
                  ),
                  if (sortOrder != null)
                    _CategoryDetailRow(
                      icon: Icons.sort_rounded,
                      label: 'Sort Order'.tr,
                      value: sortOrder.toString(),
                    ),
                  if (createdAt != null && createdAt.isNotEmpty)
                    _CategoryDetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Created'.tr,
                      value: _formatCategoryDate(createdAt),
                    ),
                  if (updatedAt != null && updatedAt.isNotEmpty)
                    _CategoryDetailRow(
                      icon: Icons.update_rounded,
                      label: 'Last Updated'.tr,
                      value: _formatCategoryDate(updatedAt),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      'Description'.tr,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Text(
                        description.isEmpty
                            ? 'No description provided'.tr
                            : description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            cateCtr.onDeleteCategory(category['id'], context);
                          },
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: theme.colorScheme.error,
                          ),
                          label: Text(
                            'Delete'.tr,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            cateCtr.onEditCategory(context, category['id']);
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: Text('Edit'.tr),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CategoryPageHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories'.tr,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Organize the products in your menu.'.tr,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _CategoryContent extends StatelessWidget {
  const _CategoryContent({
    required this.controller,
    required this.actionContext,
    required this.onCategoryTap,
  });

  final CategoryController controller;
  final BuildContext actionContext;
  final ValueChanged<Map<String, dynamic>> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.categoriesList.isEmpty) {
        return const _CategoryStatePanel(
          icon: null,
          title: 'Loading categories...',
          showProgress: true,
        );
      }

      if (controller.categoriesList.isEmpty) {
        if (controller.errorMessage.value != null) {
          return _CategoryStatePanel(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load categories',
            message: 'Check your connection and try again.',
            actionLabel: 'Retry',
            onAction: controller.onGetCategories,
          );
        }

        return const _CategoryStatePanel(
          icon: Icons.category_outlined,
          title: 'No categories found',
          message: 'Add a category to start organizing your products.',
        );
      }

      if (controller.searchCategoryList.isEmpty) {
        return const _CategoryStatePanel(
          icon: Icons.search_off_rounded,
          title: 'Search not found',
          message: 'Try another category name.',
        );
      }

      return Column(
        children: controller.searchCategoryList.map((category) {
          return CardCategoryWidget(
            category: category,
            onTap: () => onCategoryTap(category),
            onEdit: () {
              controller.onEditCategory(actionContext, category['id']);
            },
            onDelete: () {
              controller.onDeleteCategory(category['id'], actionContext);
            },
          );
        }).toList(),
      );
    });
  }
}

class _CategoryStatePanel extends StatelessWidget {
  const _CategoryStatePanel({
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.showProgress = false,
  });

  final IconData? icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showProgress)
            const CircularProgressIndicator()
          else
            Icon(
              icon ?? Icons.category_outlined,
              size: 34,
              color: theme.colorScheme.primary,
            ),
          const SizedBox(height: 14),
          Text(
            title.tr,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(
              message!.tr,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(actionLabel!.tr),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryStatusBadge extends StatelessWidget {
  const _CategoryStatusBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isActive
        ? const Color(0xFF287A4B)
        : theme.colorScheme.onSurfaceVariant;
    final background = isActive
        ? const Color(0xFFEAF5EE)
        : theme.colorScheme.surfaceContainerHighest;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            (isActive ? 'Active' : 'Inactive').tr,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryDetailRow extends StatelessWidget {
  const _CategoryDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              softWrap: true,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

bool _isCategoryActive(Map<String, dynamic> category) {
  final value = category['is_active'] ?? category['isActive'];
  return value == true || value == 1 || value == '1' || value == 'true';
}

String _formatCategoryDate(String value) {
  final date = DateTime.tryParse(value)?.toLocal();
  if (date == null) return value;

  final hasTime = value.contains('T') || value.contains(' ');
  return hasTime
      ? DateFormatter.formatDateTime(date)
      : DateFormatter.formatDate(date);
}
