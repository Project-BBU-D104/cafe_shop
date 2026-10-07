import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ToastWidget {
  static void show({
    required String message,
    ToastType type = ToastType.success,
    String title = "",
    Duration duration = const Duration(seconds: 3),
  }) {
    Get.snackbar(
      title.isEmpty ? _title(type) : title,
      message,
      snackPosition: SnackPosition.TOP,
      duration: duration,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      backgroundColor: _color(type),
      colorText: Colors.white,
      icon: Icon(
        _icon(type),
        color: Colors.white,
      ),
      snackStyle: SnackStyle.FLOATING,
      animationDuration: const Duration(milliseconds: 300),
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOut,
    );
  }

  static String _title(ToastType type) {
    switch (type) {
      case ToastType.success:
        return "Success";
      case ToastType.error:
        return "Error";
      case ToastType.warning:
        return "Warning";
      case ToastType.info:
        return "Info";
    }
  }

  static Color _color(ToastType type) {
    switch (type) {
      case ToastType.success:
        return Colors.green;
      case ToastType.error:
        return Colors.red;
      case ToastType.warning:
        return Colors.orange;
      case ToastType.info:
        return Colors.blue;
    }
  }

  static IconData _icon(ToastType type) {
    switch (type) {
      case ToastType.success:
        return Icons.check_circle;
      case ToastType.error:
        return Icons.cancel;
      case ToastType.warning:
        return Icons.warning_rounded;
      case ToastType.info:
        return Icons.info;
    }
  }
}


enum ToastType {
  success,
  error,
  warning,
  info,
}