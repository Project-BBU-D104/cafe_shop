import 'package:frontend/services/api_service.dart';

class ShiftService {
  final ApiService _api = ApiService();

  static const String endpoint = "shifts";

  /// GET the caller's open shift, or {'data': null}
  Future<dynamic> getCurrent() async {
    return await _api.get("$endpoint/current");
  }

  /// START a shift with {opening_cash, notes?}
  Future<dynamic> start(Map<String, dynamic> data) async {
    return await _api.post("$endpoint/start", data);
  }

  /// CLOSE a shift with {closing_cash} — the API accepts no notes here
  Future<dynamic> close(int shiftId, Map<String, dynamic> data) async {
    return await _api.post("$endpoint/$shiftId/close", data);
  }

  /// GET the shop's paginated shift history (manager and above only)
  Future<dynamic> getShifts({int page = 1}) async {
    return await _api.get("$endpoint/?page=$page");
  }
}
