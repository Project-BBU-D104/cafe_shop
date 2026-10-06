import 'package:frontend/global.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController{

  final username = "".obs;
  final email = "".obs;
  final phone = "".obs;
  final photo = "".obs;
  final role = "".obs;

  @override
  void onInit() {
    super.onInit();
    loadUserLogin();
  }

  void loadUserLogin() {
    final data = storage.lastUserLoginRead;
    final user = data["user"];
    if(user !=null){
      username.value = data["user"]["name"] ?? "";
      email.value = data["user"]["email"] ?? "";
      phone.value = data["user"]["phone"] ?? "";
      photo.value = data["user"]["photo"] ?? "";
      role.value = data["user"]["role"] ?? "";
    }
  }

  void onLogoutPress(){
    Get.offAllNamed('/login');

    storage.lastUserLoginRemove();
    storage.appStartUpWrite(route: '/login');
  } 
}