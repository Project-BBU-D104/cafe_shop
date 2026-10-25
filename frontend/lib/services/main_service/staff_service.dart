import 'package:frontend/services/api_service.dart';

class StaffService {
  final ApiService _api = ApiService();

  static const String endpoint = "staff";
  static const String userEndpoint = "users";

  /// GET ALL staff (incl. deactivated, so the screen can show them as Inactive).
  // shortcut: there is no reactivate endpoint, include_inactive only keeps rows visible.
  Future<dynamic> getStaff() async {
    return await _api.get("$endpoint/?include_inactive=1");
  }

  /// CREATE login user (name, email, password, role) for a staff member.
  Future<dynamic> createUser(Map<String, dynamic> data) async {
    return await _api.post(userEndpoint, data);
  }

  /// CREATE staff profile for an existing user.
  Future<dynamic> createStaff(Map<String, dynamic> data) async {
    return await _api.post(endpoint, data);
  }

  /// UPDATE staff (name, phone and the profile fields; role/email are not updatable).
  Future<dynamic> updateStaff(int userId, Map<String, dynamic> data) async {
    return await _api.put(endpoint, userId.toString(), data);
  }

  /// DELETE staff (deactivates the account).
  Future<dynamic> deleteStaff(int userId) async {
    return await _api.delete(endpoint, userId.toString());
  }
}