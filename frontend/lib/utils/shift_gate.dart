import 'package:frontend/global.dart';
import 'package:frontend/routes/app_routes.dart';
import 'package:frontend/services/main_service/shift_service.dart';

/// Cashiers with no open shift are blocked on the shift screen; everyone else
/// (and any API/network failure) goes home.
Future<String> shiftGateRoute({ShiftService? service}) async {
  final user = storage.lastUserLoginRead['user'];
  final String role = user is Map ? (user['role'] ?? '').toString() : '';

  if (role != 'cashier') return AppRoutes.home;

  try {
    final resp = await (service ?? ShiftService())
        .getCurrent()
        .timeout(const Duration(seconds: 10));

    return resp is Map && resp['data'] is Map
        ? AppRoutes.home
        : AppRoutes.shift;
  } catch (_) {
    // Fail open: a broken check must not lock a cashier out of the POS.
    return AppRoutes.home;
  }
}