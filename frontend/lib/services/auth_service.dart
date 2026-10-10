import 'package:frontend/services/api_service.dart';

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

    return loginData;
  }
}