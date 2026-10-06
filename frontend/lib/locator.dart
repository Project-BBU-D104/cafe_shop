import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/services/storage_service.dart';
import 'package:frontend/services/telegram_service.dart';
import 'package:get_it/get_it.dart';

GetIt locator = GetIt.instance;
  
void setupLocator() {
  locator.registerLazySingleton<IStorageService>(() => StorageService());
  locator.registerLazySingleton<TelegramService>(() => TelegramService(
    chatId: dotenv.env['TELEGRAM_CHAT_ID'] ?? '',
    botToken: dotenv.env['TELEGRAM_BOT_TOKEN'] ?? '',
  ));
}
