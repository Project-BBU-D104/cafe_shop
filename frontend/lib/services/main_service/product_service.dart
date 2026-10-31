import 'package:frontend/services/api_service.dart';

class ProductService {
  final ApiService _api = ApiService();

  static const String endpoint = "products";

  /// GET ALL Product (including unavailable ones: the management screens need them)
  Future<dynamic> getProducts() async {
    return await _api.get('$endpoint/?include_unavailable=1');
  }

  /// GET only the products the POS catalog may sell.
  Future<dynamic> getAvailableProducts() async {
    return await _api.get('$endpoint/');
  }

  /// GET Product BY ID
  Future<dynamic> getProductById(int id) async {
    return await _api.getById(
      endpoint,
      id.toString(),
    );
  }

  /// CREATE Product
  Future<dynamic> createProduct(
    Map<String, dynamic> data,
  ) async {
    return await _api.post(
      endpoint,
      data,
    );
  }

  /// UPDATE Product
  Future<dynamic> updateProduct(
    int id,
    Map<String, dynamic> data,
  ) async {
    return await _api.put(
      endpoint,
      id.toString(),
      data,
    );
  }

  /// DELETE Product
  Future<dynamic> deleteProduct(int id) async {
    return await _api.delete(
      endpoint,
      id.toString(),
    );
  }
}