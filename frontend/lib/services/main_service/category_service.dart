import 'package:frontend/services/api_service.dart';

class CategoryService {
  final ApiService _api = ApiService();

  static const String endpoint = "category";

  /// GET ALL CATEGORY
  Future<dynamic> getCategories() async {
    return await _api.get(endpoint);
  }

  /// GET CATEGORY BY ID
  Future<dynamic> getCategoryById(int id) async {
    return await _api.getById(
      endpoint,
      id.toString(),
    );
  }

  /// CREATE CATEGORY
  Future<dynamic> createCategory(
    Map<String, dynamic> data,
  ) async {
    return await _api.post(
      endpoint,
      data,
    );
  }

  /// UPDATE CATEGORY
  Future<dynamic> updateCategory(
    int id,
    Map<String, dynamic> data,
  ) async {
    return await _api.put(
      endpoint,
      id.toString(),
      data,
    );
  }

  /// DELETE Category
  Future<dynamic> deleteCategory(int id) async {
    return await _api.delete(
      endpoint,
      id.toString(),
    );
  }
}