import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/app_background.dart';
import 'package:frontend/controllers/language_controller.dart';
import 'package:frontend/locator.dart';
import 'package:frontend/themes/app_theme.dart';
import 'package:get/get.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'localization/app_translation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/gestures.dart'; 
import 'package:get_storage/get_storage.dart';
import 'package:device_preview/device_preview.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/.env");
  await _initConfig();

  _initStorage();
  
  await GetStorage.init();
  setupLocator();

  Get.put(LanguageController());
 

  runApp(const MyApp());

  // runApp(
  //   DevicePreview(
  //     enabled: !kReleaseMode,
  //     builder: (context) => const MyApp(),
  //   ),
  // );
}

Future<void> _initConfig() async {
  await dotenv.load(fileName: "assets/.env");
}

Future<void> _initStorage() async {
  const boxName = ".appsettings";
  if (kIsWeb) {
    await GetStorage.init(boxName);
  } else if (Platform.isWindows) {
    final dir = "${Directory.current.path}\\.config";
    final directory = Directory(dir);
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    await GetStorage(".appsettings", dir).initStorage;
  } else {
    await GetStorage.init(boxName);
  }
}

class _CustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageController = Get.put(LanguageController());

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,

      useInheritedMediaQuery: true,
      locale: DevicePreview.isEnabled(context)
          ? DevicePreview.locale(context)
          : languageController.locale.value,
      fallbackLocale: const Locale("en", "US"),

      scrollBehavior: _CustomScrollBehavior(),
      initialRoute: AppRoutes.landing,
      getPages: AppPages.pages,

      translations: AppTranslation(),

      transitionDuration: const Duration(milliseconds: 0),
      defaultTransition: Transition.noTransition,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,

      builder: (context, child) {
        return DevicePreview.appBuilder(
          context,
          Stack(
            children: [
              const AppBackground(child: SizedBox.expand()),
              child ?? const SizedBox(),
            ],
          ),
        );
      },
    );
  }
}