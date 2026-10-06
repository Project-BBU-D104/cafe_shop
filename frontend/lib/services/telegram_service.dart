import 'package:http/http.dart' as http;

class TelegramService {
  final String botToken;
  final String chatId;

  TelegramService({
    required this.botToken,
    required this.chatId,
  });

  Future<void> sendMessage(String message) async {
    
    final url = Uri.parse(
      "https://api.telegram.org/bot$botToken/sendMessage",
    );

    try {
      final response = await http.post(
        url,
        body: {
          "chat_id": chatId,
          "text": message,
          "parse_mode": "HTML",
        },
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to send message: ${response.body}");
      }
    } catch (e) {
      // print("Telegram error: $e");
    }
  }
}

// how to use it
// void onSaveCategory() async {
//     await telegram.sendMessage(
//     "🆕 New Data Saved\nName: John\nPrice: 100\$\nTesting",
//   );
// }