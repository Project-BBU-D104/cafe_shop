import 'package:frontend/services/api_service.dart';

class OrderService {
  final ApiService _api = ApiService();

  static const String endpoint = "orders";

  /// GET ALL orders (paginated at 15 by the API; ?status= filters).
  /// shortcut: the query rides in the path because ApiService has no query
  /// support and only appends a trailing slash when the endpoint lacks '/'.
  Future<dynamic> getOrders({int page = 1, String? status}) {
    final String query = status == null || status.isEmpty
        ? 'page=$page'
        : 'page=$page&status=${Uri.encodeComponent(status)}';

    return _api.get('$endpoint/?$query');
  }

  /// GET Order BY ID
  Future<dynamic> getOrder(int id) async {
    return await _api.getById(endpoint, id.toString());
  }

  /// CREATE Order
  Future<dynamic> createOrder(Map<String, dynamic> data) async {
    return await _api.post(endpoint, data);
  }

  /// PATCH orders/{id}/status — status is one of the OrderStatus enum values.
  Future<dynamic> updateStatus(int id, String status, {String? note}) async {
    return await _api.patch(
      endpoint,
      '$id/status',
      {
        'status': status,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
  }

  /// POST orders/{id}/cancel — {} is a valid body.
  Future<dynamic> cancelOrder(int id, {String? note}) async {
    return await _api.post(
      '$endpoint/$id/cancel',
      {if (note != null && note.isNotEmpty) 'note': note},
    );
  }

  /// POST orders/{id}/pay — always charges the full total; no amount field.
  Future<dynamic> payOrder(
    int id,
    String method, {
    String? reference,
  }) async {
    return await _api.post(
      '$endpoint/$id/pay',
      {
        'method': method,
        if (reference != null && reference.isNotEmpty)
          'transaction_reference': reference,
      },
    );
  }
}
