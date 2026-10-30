import 'package:frontend/services/api_service.dart';

class InventoryMovementService {
  final ApiService _api = ApiService();

  static const String endpoint = "ingredients";

  /// GET the shop's movement ledger, newest first (50 per page)
  Future<dynamic> getMovements() async {
    return await _api.get("inventory/movements");
  }

  /// RECORD a stock movement for an ingredient
  Future<dynamic> createMovement(
    int ingredientId,
    Map<String, dynamic> data,
  ) async {
    return await _api.post(
      "$endpoint/$ingredientId/movements",
      data,
    );
  }
}