import 'package:flutter/material.dart' hide SearchController;
import 'package:frontend/helper/confirm_dialog_helper.dart';
import 'package:frontend/screen/category/widget/edit_category_widget.dart';
import 'package:get/get.dart';
import 'package:frontend/screen/category/widget/add_category_widget.dart';
import 'package:frontend/services/main_service/category_service.dart';
import 'package:frontend/widget/bottom_sheets.dart';
import 'package:frontend/widget/toast_widget.dart';
import 'package:frontend/controllers/search_controller.dart';
class CategoryController extends GetxController {
  
  final CategoryService service = CategoryService();
  final RxList<Map<String, dynamic>> categoriesList = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final searchCategoryList = <Map<String, dynamic>>[].obs;
  final cateNameController = TextEditingController();
  final cateDescController = TextEditingController();
  final cateSortOrderController = TextEditingController();
  final isActiveController = true.obs;

  @override
  void onInit() {
    super.onInit();
    onGetCategories();

    final search = Get.put(SearchController());
    ever(
      search.keyword,
      (keyword) {
        onSearchCategory(keyword);
      }
    );
  }

  void onClear(){
    // Clear form
    cateNameController.clear();
    cateDescController.clear();
    cateSortOrderController.clear();
    isActiveController.value = true;
  }

  Future<void> onGetCategories() async {
    try {
      isLoading.value = true;

      final resp = await service.getCategories();

      if (resp is Map && resp['data'] is List) {
      final List<dynamic> data = resp['data'];

      categoriesList.assignAll(
        data.map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      ); 

      searchCategoryList.value = categoriesList;

      } else {
        categoriesList.clear();
      }
    } catch (e) {
      ToastWidget.show(
        message: 'Failed to load categories: $e',
        type: ToastType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void onAddCategory(BuildContext context) {
    AppBottomSheets.show(
      context,
      child: AddCategoryWidget(),
    );
  }

  void onSearchCategory(String keyword){
    final search = keyword.trim().toLowerCase();

    if (search.isEmpty) {
      searchCategoryList.value = categoriesList;
      return;
    }

    searchCategoryList.value = categoriesList.where((category) {
      return (category["name"] ?? "").toString().toLowerCase().contains(search);
    }).toList();
  }

  Future<void> onSaveCategory() async{

    final String name = cateNameController.text.trim();
    final String description = cateDescController.text.trim();
    final int sortOrder = int.tryParse(cateSortOrderController.text.trim()) ?? 0;
    final bool isActive = isActiveController.value;
      
    try{

      isLoading.value = true;

      final Map<String, dynamic> data = {
      'name': name,
      'description': description,
      'sort_order': sortOrder,
      'is_active': isActive,
    };

    await service.createCategory(data);

    await onGetCategories();

    onClear();
    Get.back();

    ToastWidget.show(
      message: 'Category saved successfully',
      type: ToastType.success,
    );
    }catch(e){
         
      ToastWidget.show(
        message: e.toString(),
        type: ToastType.error,
      );
    }finally{
      isLoading.value = false;
    }
  }

Future<void> onEditCategory(
  BuildContext context,
  int categoryId,
) async {
  try {
     
    isLoading.value = true;

    final response = await service.getCategoryById(categoryId);
 
    dynamic category = response;

    if (response is Map && response['data'] != null) {
      category = response['data'];
    }

    if (category is List && category.isNotEmpty) {
      category = category.first;
    }

    if (category is! Map) {
      throw Exception('Invalid category response: $response');
    }

    // Fill the edit form.
    cateNameController.text =
        (category['name'] ?? '').toString();

    cateDescController.text =
        (category['description'] ?? '').toString();

    cateSortOrderController.text =
        (category['sort_order'] ?? category['sortOrder'] ?? 0)
            .toString();

    final active = category['is_active'] ?? category['isActive'];

    isActiveController.value =
        active == true ||
        active == 1 ||
        active == '1' ||
        active == 'true';

  
    if (!context.mounted) return;

    AppBottomSheets.show(
      context,
      child: EditCategoryWidget(
        categoryId: categoryId,
      ),
    );
  } catch (e) {
    ToastWidget.show(
      message: 'Failed to open edit category: $e',
      type: ToastType.error,
    );
  } finally {
    isLoading.value = false;
  }
}

Future<void> onUpdateCategory(int categoryId) async {
  final String name = cateNameController.text.trim();
  final String description = cateDescController.text.trim();

  final int? sortOrder = int.tryParse(
    cateSortOrderController.text.trim().isEmpty
        ? '0'
        : cateSortOrderController.text.trim(),
  );

  final bool isActive = isActiveController.value;

  // Validate category name.
  if (name.isEmpty) {
    ToastWidget.show(
      message: 'Category name is required',
      type: ToastType.error,
    );
    return;
  }
 
  if (sortOrder == null || sortOrder < 0) {
    ToastWidget.show(
      message: 'Please enter a valid sort order',
      type: ToastType.error,
    );
    return;
  }

  try {
    isLoading.value = true;

    // Data to send to the API.
    final Map<String, dynamic> data = {
      'name': name,
      'description': description,
      'sort_order': sortOrder,
      'is_active': isActive,
    };

    // Update the existing category.
    await service.updateCategory(categoryId, data);

    // Refresh  
    await onGetCategories();
    onClear();
    Get.back();
 
    ToastWidget.show(
      message: 'Category updated successfully',
      type: ToastType.success,
    );
  } catch (e) {
    ToastWidget.show(
      message: 'Failed to update category: $e',
      type: ToastType.error,
    );
  } finally {
    isLoading.value = false;
  }
}

  Future<void> onDeleteCategory(int categoryId, BuildContext context) async{
   showConfirmDialog(
      context: context,
      message: "Do you want to delete this category?".tr,
      onConfirm: () async {
        try{
          await service.deleteCategory(categoryId);

          // Refresh category list
          await onGetCategories();

          ToastWidget.show(
            message: "Category deleted successfully".tr,
            type: ToastType.success,
          );

          Get.back();

        }catch(e){
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
 