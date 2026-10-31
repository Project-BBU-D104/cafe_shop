import 'package:frontend/controllers/cart_controller.dart';
import 'package:frontend/global.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/widget/toast_widget.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ProfileController extends GetxController{

  final username = "".obs;
  final email = "".obs;
  final phone = "".obs;
  final photo = "".obs;
  final role = "".obs;

  final AuthService _authService = AuthService();

  @override
  void onInit() {
    super.onInit();
    loadUserLogin();
  }

  Future<void> loadUserLogin() async {
    _applyUser(storage.lastUserLoginRead["user"]);

    try {
      final user = await _authService.me();

      await storage.lastUserLoginWrite(
        data: {
          "token": storage.lastUserLoginRead["token"],
          "token_type": "Bearer Token",
          "user": user,
        },
      );

      _applyUser(user);
    } on http.ClientException {
      ToastWidget.show(
        message: "Can't connect to the internet",
        type: ToastType.error,
      );
    } catch (_) {
      ToastWidget.show(
        message: "Couldn't refresh profile",
        type: ToastType.error,
      );
    }
  }

  void _applyUser(dynamic user) {
    if (user is! Map) return;

    username.value = user["name"] ?? "";
    email.value = user["email"] ?? "";
    phone.value = user["phone"] ?? "";
    photo.value = user["photo"] ?? "";
    role.value = user["role"] ?? "";
  }

  void onLogoutPress(){
    Get.offAllNamed('/login');

    // The POS cart is permanent; don't leak it or its shop-scoped catalog
    // cache to the next user.
    if (Get.isRegistered<CartController>()) {
      Get.find<CartController>().resetSession();
    }

    storage.lastUserLoginRemove();
    storage.appStartUpWrite(route: '/login');
  }
}