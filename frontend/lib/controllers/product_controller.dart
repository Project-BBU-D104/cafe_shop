import 'package:frontend/services/main_service/product_service.dart';
import 'package:frontend/widget/toast_widget.dart';
import 'package:get/get.dart';

class ProductController extends GetxController{
  final ProductService service = ProductService(); 
  final products = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;

  @override
  void onInit(){
    super.onInit();
    onGetProductList();
  }

  Future<void> onGetProductList() async{
    try{
      isLoading.value = true;

      final resp = await service.getProducts();

      if (resp is Map && resp['data'] is List) {
        final List<dynamic> data = resp['data'];

        products.assignAll(
          data.map<Map<String, dynamic>>(
            (item) => Map<String, dynamic>.from(item as Map),
          ),
        );
      } else {
        products.clear();
      }

    }catch(e){
      ToastWidget.show(
        message: 'Failed to load products: $e',
        type: ToastType.error,
      );
    }finally{
      isLoading.value = false;
    }
  }
}
