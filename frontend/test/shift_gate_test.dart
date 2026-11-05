import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/locator.dart';
import 'package:frontend/routes/app_routes.dart';
import 'package:frontend/services/main_service/shift_service.dart';
import 'package:frontend/services/storage_service.dart';
import 'package:frontend/utils/shift_gate.dart';

/// In-memory stand-in for the shifts API; throws the exact 409 messages.
class _FakeShiftService extends ShiftService {
  Map<String, dynamic>? openShift;
  final List<Map<String, dynamic>> history = [];

  /// Rows returned instead of [history] when page > 1.
  List<Map<String, dynamic>> extraPageRows = [];
  int historyLastPage = 3;

  int startCalls = 0;
  int closeCalls = 0;
  int currentCalls = 0;
  int historyCalls = 0;
  Map<String, dynamic>? lastStartPayload;
  Map<String, dynamic>? lastClosePayload;

  /// When set, [start] throws this instead of its normal behavior.
  Object? startError;

  /// When true, [getCurrent] throws instead of returning a result.
  bool shouldThrow = false;

  @override
  Future<dynamic> getCurrent() async {
    currentCalls++;
    if (shouldThrow) throw Exception('network down');
    return {'data': openShift};
  }

  @override
  Future<dynamic> start(Map<String, dynamic> data) async {
    startCalls++;
    if (startError != null) throw startError!;
    if (openShift != null) {
      throw Exception('You already have an open shift.');
    }
    lastStartPayload = data;
    final shift = {
      'id': history.length + 1,
      'opening_cash': (data['opening_cash'] as num).toStringAsFixed(2),
      'notes': data['notes'],
      'started_at': '2026-11-03T08:00:00.000000Z',
      'ended_at': null,
      'closing_cash': null,
    };
    openShift = shift;
    // Like the real index, the history lists open shifts too.
    history.insert(0, shift);
    return {'data': shift};
  }

  @override
  Future<dynamic> close(int shiftId, Map<String, dynamic> data) async {
    closeCalls++;
    final shift = openShift;
    if (shift == null || shift['id'] != shiftId) {
      throw Exception('This shift is already closed.');
    }
    lastClosePayload = data;
    // The backend updates the same row the index already shows.
    shift['closing_cash'] = (data['closing_cash'] as num).toStringAsFixed(2);
    shift['ended_at'] = '2026-11-03T16:00:00.000000Z';
    openShift = null;
    return {'data': shift};
  }

  @override
  Future<dynamic> getShifts({int page = 1}) async {
    historyCalls++;
    return {
      'data': page == 1 ? history : extraPageRows,
      'meta': {'current_page': page, 'last_page': historyLastPage},
    };
  }
}

/// Logged-in staff member; tests flip [role] to exercise the gate.
class _FakeStorageService implements IStorageService {
  String role = 'cashier';

  /// Returned instead of the default login map when non-null.
  Map<String, dynamic>? loginOverride;

  @override
  Map<String, dynamic> get lastUserLoginRead =>
      loginOverride ?? {'user': {'id': 1, 'role': role}};

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  late _FakeStorageService fakeStorage;

  setUpAll(() {
    // ApiService reads API_URL from dotenv at construction time.
    dotenv.testLoad(fileInput: 'API_URL=http://127.0.0.1:8000/api/v1');

    fakeStorage = _FakeStorageService();
    if (!locator.isRegistered<IStorageService>()) {
      locator.registerSingleton<IStorageService>(fakeStorage);
    }
  });

  tearDown(() {
    fakeStorage.role = 'cashier';
    fakeStorage.loginOverride = null;
  });

  test('shiftGateRoute sends a cashier with no open shift to the shift screen',
      () async {
    final fake = _FakeShiftService();

    expect(await shiftGateRoute(service: fake), AppRoutes.shift);
  });

  test('shiftGateRoute lets a cashier with an open shift through', () async {
    final fake = _FakeShiftService()
      ..openShift = {'id': 1, 'opening_cash': '100.00', 'ended_at': null};

    expect(await shiftGateRoute(service: fake), AppRoutes.home);
  });

  test('shiftGateRoute skips the check for manager, owner and admin', () async {
    for (final role in ['manager', 'owner', 'admin']) {
      fakeStorage.role = role;
      final fake = _FakeShiftService();

      expect(await shiftGateRoute(service: fake), AppRoutes.home, reason: role);
      expect(fake.currentCalls, 0, reason: role);
    }
  });

  test('shiftGateRoute fails open when getCurrent throws', () async {
    final fake = _FakeShiftService()..shouldThrow = true;

    expect(await shiftGateRoute(service: fake), AppRoutes.home);
  });

  test('shiftGateRoute returns home when the stored user is missing',
      () async {
    fakeStorage.loginOverride = {};

    expect(await shiftGateRoute(service: _FakeShiftService()), AppRoutes.home);
  });
}