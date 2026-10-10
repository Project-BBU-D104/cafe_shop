import 'package:flutter/material.dart';
import 'package:frontend/screen/category/widget/add_category_widget.dart';
import 'package:frontend/services/main_service/category_service.dart';
import 'package:frontend/widget/bottom_sheets.dart';
import 'package:frontend/widget/toast_widget.dart';
import 'package:frontend/helper/confirm_dialog_helper.dart';
import 'package:get/get.dart';

class CategoryController extends GetxController{
  
  final CategoryService service = CategoryService();

  final categoriesList = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;

  @override
  void onInit(){
    super.onInit();
    // get categories
    onGetCategories();

  }

  Future<void> onGetCategories() async{
    try{
      isLoading.value = true;

      final resp = await service.getCategories();

      if(resp is List){
        categoriesList.value = List<Map<String, dynamic>>.from(resp);

        print(categoriesList);
      }
    }catch(e){
      ToastWidget.show(
          message: e.toString(),
          type: ToastType.error,
        );
    }finally{
      isLoading.value = false;
    }
  }

  void onAddCategory(BuildContext context){
    AppBottomSheets.show(
      context,
      child: AddCategoryWidget()
    );
  }
}