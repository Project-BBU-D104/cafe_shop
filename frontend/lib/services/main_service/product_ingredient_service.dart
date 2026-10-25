import 'package:frontend/services/api_service.dart';

/// Recipe rows (product ingredients) bound to one product variant.
class ProductIngredientService {
  final ApiService _api = ApiService();

  static String _path(int variantId) => "variants/$variantId/ingredients";

  /// GET RECIPE FOR VARIANT
  Future<dynamic> getRecipe(int variantId) async {
    return await _api.get(_path(variantId));
  }

  /// ADD INGREDIENT TO RECIPE
  Future<dynamic> addIngredient(
    int variantId,
    Map<String, dynamic> data,
  ) async {
    return await _api.post(_path(variantId), data);
  }

  /// UPDATE RECIPE QUANTITY (the unit is pinned server-side)
  Future<dynamic> updateQuantity(
    int variantId,
    int ingredientId,
    Map<String, dynamic> data,
  ) async {
    return await _api.patch(_path(variantId), ingredientId.toString(), data);
  }

  /// REMOVE INGREDIENT FROM RECIPE
  Future<dynamic> removeIngredient(int variantId, int ingredientId) async {
    return await _api.delete(_path(variantId), ingredientId.toString());
  }
}
