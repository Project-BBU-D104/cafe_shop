import 'package:flutter/material.dart';
import 'package:frontend/widget/confirm_dailog_widget.dart';

Future<void> showConfirmDialog({
  required BuildContext context,
  String title = "Confirm",
  required String message,
  String cancelText = "Cancel",
  String confirmText = "Ok",
  VoidCallback? onCancel,
  VoidCallback? onConfirm,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return ConfirmDialogWidget(
        title: title,
        message: message,
        cancelText: cancelText,
        confirmText: confirmText,
        onCancel: () {
          Navigator.pop(context);
          if (onCancel != null) onCancel();
        },
        onConfirm: () {
          Navigator.pop(context);
          if (onConfirm != null) onConfirm();
        },
      );
    },
  );
}