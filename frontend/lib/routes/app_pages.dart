import 'package:frontend/controllers/landing_controller.dart';
import 'package:frontend/controllers/login_controller.dart';
import 'package:frontend/screen/auth/login_screen.dart';
import 'package:frontend/screen/home/home_screen.dart';
import 'package:frontend/screen/report/report_screen.dart';
import 'package:get/get.dart';
import 'app_routes.dart';
import 'package:frontend/screen/landing.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.landing,
      page: () => const LandingScreen(),
      binding: BindingsBuilder(() {
        Get.put(LandingController());
      }),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => LoginScreen(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => HomeScreen(),
    ),
    GetPage(
      name: AppRoutes.report,
      page: () => ReportScreen(),
    ),
  ];
}
  