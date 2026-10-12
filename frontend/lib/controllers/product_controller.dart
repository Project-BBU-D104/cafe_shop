import 'package:frontend/services/main_service/product_service.dart';
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

      

    }catch(e){
      // 
    }finally{
      // 
    }
  }
}