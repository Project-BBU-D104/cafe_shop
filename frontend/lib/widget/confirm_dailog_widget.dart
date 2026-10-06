import 'package:flutter/material.dart';
import 'package:frontend/constants/constant.dart';

class ConfirmDialogWidget extends StatelessWidget {
  final String title;
  final String message;
  final String cancelText;
  final String confirmText;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const ConfirmDialogWidget({
    super.key,
    this.title = "Confirm",
    required this.message,
    this.cancelText = "Cancel",
    this.confirmText = "Save",
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dangerColor.shade500,
                      foregroundColor: titleColor,
                    ),
                    onPressed: onCancel,
                    child: Text(cancelText),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: titleColor,
                    ),
                    onPressed: onConfirm,
                    child: Text(confirmText),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


// how to use it
// ElevatedButton(
//   onPressed: () {
//     showConfirmDialog(
//       context: context,
//       message: "Do you want to save this data?",
//       onConfirm: () {
//         print("Saved!");
//       },
//       onCancel: () {
//         print("Cancelled!");
//       },
//     );
//   },
//   child: const Text("Show Dialog"),
// ),