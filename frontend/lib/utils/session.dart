import 'package:frontend/controllers/cart_controller.dart';
import 'package:frontend/global.dart';
import 'package:frontend/routes/app_routes.dart';
import 'package:get/get.dart';

/// Clears the login session and returns to the login screen. Shared by manual
/// logout and the automatic logout after a cashier closes their shift.
void logout() {
  Get.offAllNamed(AppRoutes.login);

  // The POS cart is permanent; don't leak it or its shop-scoped catalog
  // cache to the next user.
  if (Get.isRegistered<CartController>()) {
    Get.find<CartController>().resetSession();
  }

  storage.lastUserLoginRemove();
  storage.appStartUpWrite(route: AppRoutes.login);
}