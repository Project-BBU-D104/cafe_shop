import 'package:flutter/material.dart';
import 'package:frontend/constants/constant.dart';

class AppBottomSheets {
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
  }) {
    return showModalBottomSheet<T>(
    context: context,
    // Get.back() closes routes on the root navigator, so the sheet must live
    // there too when it is opened from a page inside the nested navigator.
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: lightColor,
    builder: (_) {
      return child;
    },
  );
  }
}