import 'package:flutter/material.dart';
import 'package:frontend/constants/constant.dart';

class AppBottomSheets {
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
  }) {
    return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: lightColor,
    builder: (_) {
      return child;
    },
  );
  }
}