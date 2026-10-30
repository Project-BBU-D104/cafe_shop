import 'package:frontend/services/api_service.dart';

class InventoryMovementService {
  final ApiService _api = ApiService();

  static const String endpoint = "ingredients";

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