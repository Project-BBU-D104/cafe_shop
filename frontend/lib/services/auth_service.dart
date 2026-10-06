import 'package:frontend/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      "auth/login",
      {
        "email": email,
        "password": password,
      },

    );

    final data = Map<String, dynamic>.from(response);

    final loginData = Map<String, dynamic>.from(data['data']);

     final token = loginData['token'];
    
    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
    }

    return loginData;
  }
}