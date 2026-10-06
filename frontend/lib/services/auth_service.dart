import 'package:frontend/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> login({
    required String name,
    required String password,
  }) async {
    final response = await _api.post(
      "auth/login",
      {
        "name": name,
        "password": password,
      },

    );

    final data = Map<String, dynamic>.from(response);
    
    if (data.containsKey('access_token')) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['access_token']);
    }

    return data;
  }
}