import 'package:frontend/services/api_service.dart';

class TableNumberService {
  final ApiService _api = ApiService();

  static const String endpoint = "sale_table";

  /// GET ALL TableNumber
  Future<dynamic> getTableNumber() async {
    return await _api.get(endpoint);
  }

  /// GET TableNumber BY ID
  Future<dynamic> getTableNumberById(int id) async {
    return await _api.getById(
      endpoint,
      id.toString(),
    );
  }

  /// CREATE TableNumber
  Future<dynamic> createTableNumber(
    Map<String, dynamic> data,
  ) async {
    return await _api.post(
      endpoint,
      data,
    );
  }

  /// UPDATE TableNumber
  Future<dynamic> updateTableNumber(
    int id,
    Map<String, dynamic> data,
  ) async {
    return await _api.put(
      endpoint,
      id.toString(),
      data,
    );
  }

  /// DELETE TableNumber
  Future<dynamic> deleteTableNumber(int id) async {
    return await _api.delete(
      endpoint,
      id.toString(),
    );
  }
}