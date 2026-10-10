import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/global.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = dotenv.env['API_URL']!;

   Map<String, String> get headers {
    final loginData = storage.lastUserLoginRead;
    final token = loginData["token"];

    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (token != null && token.toString().isNotEmpty)
        "Authorization": "Bearer $token",
    };
  }

  /// GET ALL
  Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      _buildUri(endpoint, trailingSlash: !endpoint.contains('/')),
      headers: headers,
    );

    return _handleResponse(response);
  }

  /// GET BY ID
  Future<dynamic> getById(
    String endpoint,
    String id,
  ) async {
    final response = await http.get(
      _buildUri("$endpoint/$id"),
      headers: headers,
    );

    return _handleResponse(response);
  }

  /// POST
  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      _buildUri(endpoint, trailingSlash: true),
      headers: headers,
      body: jsonEncode(data),
    );

    return _handleResponse(response);
  }

  /// PUT
  Future<dynamic> put(
    String endpoint,
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      _buildUri("$endpoint/$id"),
      headers: headers,
      body: jsonEncode(data),
    );

    return _handleResponse(response);
  }

  /// DELETE
  Future<dynamic> delete(
    String endpoint,
    String id,
  ) async {
    final response = await http.delete(
      _buildUri("$endpoint/$id"),
      headers: headers,
    );

    return _handleResponse(response);
  }

  Uri _buildUri(String endpoint, {bool trailingSlash = false}) {
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanEndpoint = endpoint.startsWith('/')
        ? endpoint.substring(1)
        : endpoint;
    final path = trailingSlash && !cleanEndpoint.endsWith('/')
        ? '$cleanEndpoint/'
        : cleanEndpoint;

    return Uri.parse('$cleanBaseUrl/$path');
  }

  dynamic _handleResponse(http.Response response) {
  final dynamic body = response.body.isEmpty
      ? null
      : jsonDecode(response.body);

  // Successful response
  if (response.statusCode >= 200 && response.statusCode < 300) {
    return body;
  }

  // Extract the backend error message dynamically
  String errorMessage = 'API Error (${response.statusCode})';

  if (body is Map) {
    // Check validation errors first
    final errors = body['errors'];

    if (errors is Map && errors.isNotEmpty) {
      final firstError = errors.values.first;

      if (firstError is List && firstError.isNotEmpty) {
        errorMessage = firstError.first.toString();
      } else if (firstError != null) {
        errorMessage = firstError.toString();
      }
    }

    // If there are no validation errors, check common message fields
    else if (body['message'] != null) {
      errorMessage = body['message'].toString();
    } else if (body['detail'] != null) {
      errorMessage = body['detail'].toString();
    }
  }

  throw Exception(errorMessage);
}
}
