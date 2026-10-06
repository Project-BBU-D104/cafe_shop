import 'package:frontend/controllers/app_controller.dart';
import 'package:frontend/global.dart';
import 'package:frontend/routes/app_routes.dart';
import 'package:get/get.dart';

class LandingController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    _route();
  }

  void _route() async {
    Get.put(AppController(), permanent: true);
    await Future.delayed(Duration(seconds: 2));
    // Get.offAllNamed(AppRoutes.login);

    final user = storage.lastUserLoginRead;

    // if (user.isNotEmpty) {
    //   Get.offAllNamed(storage.appStartUpRead);
    // } else {
    //   Get.offAllNamed(AppRoutes.login);
    // }
    if (user.isNotEmpty && storage.appStartUpRead.isNotEmpty) {
      Get.offAllNamed(storage.appStartUpRead);

      // print(storage.appStartUpRead);
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
