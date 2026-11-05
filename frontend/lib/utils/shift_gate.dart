import 'package:flutter/foundation.dart';
import 'package:frontend/global.dart';
import 'package:frontend/routes/app_routes.dart';
import 'package:frontend/services/main_service/shift_service.dart';

/// Last successful check this session; null until one runs.
bool? _openShiftSeen;

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

    _openShiftSeen = resp is Map && resp['data'] is Map;

    return _openShiftSeen! ? AppRoutes.home : AppRoutes.shift;
  } catch (_) {
    // Fail open: a broken check must not lock a cashier out of the POS.
    _openShiftSeen = true;
    return AppRoutes.home;
  }
}

/// Route guard for /home: non-cashiers always pass; a cashier passes only
/// after a check found an open shift. Unknown counts as blocked, so a URL
/// deep-link or reload cannot skip the gate.
bool get shiftGatePasses {
  final user = storage.lastUserLoginRead['user'];
  final String role = user is Map ? (user['role'] ?? '').toString() : '';

  return role != 'cashier' || _openShiftSeen == true;
}

void setShiftGateOpen(bool open) => _openShiftSeen = open;

@visibleForTesting
void resetShiftGateCache() => _openShiftSeen = null;