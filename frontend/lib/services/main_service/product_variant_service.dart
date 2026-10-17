import 'package:frontend/services/api_service.dart';

class ProductVariantService {
  final ApiService _api = ApiService();

  static String _path(int productId) => "products/$productId/variants";

  /// GET ALL PRODUCT VARIANTS
  Future<dynamic> getVariants(int productId) async {
    return await _api.get(_path(productId));
  }

  /// GET PRODUCT VARIANT BY ID
  Future<dynamic> getVariantById(
    int productId,
    int variantId,
  ) async {
    return await _api.getById(
      _path(productId),
      variantId.toString(),
    );
  }

  /// CREATE PRODUCT VARIANT
  Future<dynamic> createVariant(
    int productId,
    Map<String, dynamic> data,
  ) async {
    return await _api.post(
      _path(productId),
      data,
    );
  }

  /// UPDATE PRODUCT VARIANT
  Future<dynamic> updateVariant(
    int productId,
    int variantId,
    Map<String, dynamic> data,
  ) async {
    return await _api.put(
      _path(productId),
      variantId.toString(),
      data,
    );
  }

  /// DELETE PRODUCT VARIANT
  Future<dynamic> deleteVariant(
    int productId,
    int variantId,
  ) async {
    return await _api.delete(
      _path(productId),
      variantId.toString(),
    );
  }
}
