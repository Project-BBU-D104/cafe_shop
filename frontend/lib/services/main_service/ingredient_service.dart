import 'package:frontend/services/api_service.dart';

class IngredientService {
  final ApiService _api = ApiService();

  static const String endpoint = "ingredients";

  /// GET ALL Ingredient
  Future<dynamic> getIngredients() async {
    return await _api.get(endpoint);
  }

  /// GET Ingredient BY ID
  Future<dynamic> getIngredientById(int id) async {
    return await _api.getById(
      endpoint,
      id.toString(),
    );
  }

  /// CREATE Ingredient
  Future<dynamic> createIngredient(
    Map<String, dynamic> data,
  ) async {
    return await _api.post(
      endpoint,
      data,
    );
  }

  /// UPDATE Ingredient
  Future<dynamic> updateIngredient(
    int id,
    Map<String, dynamic> data,
  ) async {
    return await _api.put(
      endpoint,
      id.toString(),
      data,
    );
  }

  /// DELETE Ingredient
  Future<dynamic> deleteIngredient(int id) async {
    return await _api.delete(
      endpoint,
      id.toString(),
    );
  }
}