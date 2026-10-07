import 'package:frontend/controllers/landing_controller.dart';
import 'package:frontend/screen/auth/login_screen.dart';
import 'package:frontend/screen/home/home_screen.dart';
import 'package:frontend/screen/report/report_screen.dart';
import 'package:get/get.dart';
import 'app_routes.dart';
import 'package:frontend/screen/landing.dart';

import 'package:frontend/screen/setting/setting_screen.dart';
import 'package:frontend/screen/user/user_screen.dart';
import 'package:frontend/screen/category/category_screen.dart';
import 'package:frontend/screen/product/product_screen.dart';
import 'package:frontend/screen/inventory/inventory_movement/inventory_movement_screen.dart';
import 'package:frontend/screen/shift/shift_screen.dart';


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
    GetPage(
      name: AppRoutes.category,
      page: () => CategoryScreen(),
    ),
    GetPage(
      name: AppRoutes.product,
      page: () => ProductScreen(),
    ),
    GetPage(
      name: AppRoutes.user,
      page: () => UserScreen(),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => SettingScreen(),
    ),
    GetPage(
      name: AppRoutes.inventoryMovements,
      page: () => InventoryMovementScreen(),
    ),
    
    GetPage(
      name: AppRoutes.shift,
      page: () => ShiftScreen(),
    ),
  ];
}
  