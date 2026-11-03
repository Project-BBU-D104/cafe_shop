import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/controllers/shift_controller.dart';
import 'package:frontend/locator.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/main_service/shift_service.dart';
import 'package:frontend/services/storage_service.dart';
import 'package:get/get.dart';

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

  @override
  Future<dynamic> getCurrent() async {
    currentCalls++;
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

/// Logged-in staff member; tests flip [role] to exercise the history gate.
class _FakeStorageService implements IStorageService {
  String role = 'manager';

  @override
  Map<String, dynamic> get lastUserLoginRead =>
      {'user': {'id': 1, 'role': role}};

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

  tearDown(() => fakeStorage.role = 'manager');

  test('validateCash mirrors the API decimal rules', () {
    final ctr = ShiftController(service: _FakeShiftService());

    for (final bad in ['', 'abc', '-1', '10.123']) {
      expect(ctr.validateCash(bad), isNotNull, reason: '"$bad" must fail');
    }
    for (final good in ['0', '100', '100.50']) {
      expect(ctr.validateCash(good), isNull, reason: '"$good" must pass');
    }
  });

  test('buildStartPayload includes notes only when filled', () {
    final ctr = ShiftController(service: _FakeShiftService());

    ctr.openingCashController.text = '100.50';
    ctr.startNotesController.clear();
    expect(ctr.buildStartPayload(), {'opening_cash': 100.5});

    ctr.startNotesController.text = 'Morning till';
    expect(
      ctr.buildStartPayload(),
      {'opening_cash': 100.5, 'notes': 'Morning till'},
    );
  });

  test('buildClosePayload never includes notes', () {
    final ctr = ShiftController(service: _FakeShiftService());

    ctr.openingCashController.text = '100';
    ctr.startNotesController.text = 'Some start note';
    ctr.closingCashController.text = '80.25';

    final payload = ctr.buildClosePayload();

    expect(payload.keys.toList(), ['closing_cash']);
    expect(payload['closing_cash'], 80.25);
  });

  test('loadCurrent sets currentShift from the data envelope', () async {
    final fake = _FakeShiftService()
      ..openShift = {'id': 7, 'opening_cash': '100.00', 'ended_at': null};
    final ctr = ShiftController(service: fake);

    await ctr.loadCurrent();

    expect(ctr.currentShift.value!['id'], 7);
    expect(ctr.hasOpenShift, isTrue);
    expect(ctr.isLoading.value, isFalse);
    expect(fake.currentCalls, 1);
  });

  test('loadCurrent clears currentShift when data is null', () async {
    final ctr = ShiftController(service: _FakeShiftService());
    ctr.currentShift.value = {'id': 1};

    await ctr.loadCurrent();

    expect(ctr.currentShift.value, isNull);
    expect(ctr.hasOpenShift, isFalse);
  });

  test('loadHistory unwraps the paginated list for managers', () async {
    final fake = _FakeShiftService()
      ..history.addAll([
        {'id': 2, 'ended_at': '2026-11-02T16:00:00.000000Z'},
        {'id': 1, 'ended_at': '2026-11-01T16:00:00.000000Z'},
      ]);
    final ctr = ShiftController(service: fake);

    await ctr.loadHistory();

    expect(ctr.shifts.map((s) => s['id']).toList(), [2, 1]);
    expect(ctr.isLoadingHistory.value, isFalse);
    expect(ctr.historyLastPage.value, 3); // from meta.last_page
  });

  test('loadHistory appends the next page', () async {
    final fake = _FakeShiftService()..history.add({'id': 2});
    final ctr = ShiftController(service: fake);

    await ctr.loadHistory();
    fake.extraPageRows = [
      {'id': 1},
    ];
    await ctr.loadHistory(append: true);

    expect(ctr.shifts.map((s) => s['id']).toList(), [2, 1]);
    expect(ctr.historyPage.value, 2);
  });

  test('loadHistory is skipped for cashiers', () async {
    fakeStorage.role = 'cashier';
    final fake = _FakeShiftService();
    final ctr = ShiftController(service: fake);

    await ctr.loadHistory();

    expect(ctr.shifts, isEmpty);
    expect(fake.historyCalls, 0);
  });

  test('canViewHistory gates on role', () {
    final ctr = ShiftController(service: _FakeShiftService());

    for (final role in ['owner', 'admin', 'manager']) {
      fakeStorage.role = role;
      expect(ctr.canViewHistory, isTrue, reason: role);
    }
    fakeStorage.role = 'cashier';
    expect(ctr.canViewHistory, isFalse);
  });

  // --- start/close flows (Task 4) ---

  testWidgets('onStartShift sets currentShift, clears fields and refreshes history',
      (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));

    final fake = _FakeShiftService();
    final ctr = ShiftController(service: fake);
    ctr.openingCashController.text = '100.50';
    ctr.startNotesController.text = 'Morning';

    await ctr.onStartShift();
    await tester.pump(const Duration(seconds: 4)); // let the toast timer fire
    await tester.pumpAndSettle();

    expect(ctr.hasOpenShift, isTrue);
    expect(ctr.currentShift.value!['id'], 1);
    expect(ctr.openingCashController.text, isEmpty);
    expect(ctr.startNotesController.text, isEmpty);
    expect(ctr.shifts, hasLength(1)); // silent history reload ran
    expect(ctr.isSaving.value, isFalse);
  });

  testWidgets('onStartShift on 409 shows server message and resyncs currentShift',
      (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));

    final fake = _FakeShiftService()
      ..openShift = {'id': 7, 'opening_cash': '50.00', 'ended_at': null};
    final ctr = ShiftController(service: fake);
    ctr.openingCashController.text = '100';

    await ctr.onStartShift(); // fake throws 'You already have an open shift.'
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // The resync via getCurrent recovered the pre-existing shift's id.
    expect(ctr.currentShift.value!['id'], 7);
    expect(ctr.isSaving.value, isFalse);
  });

  test('onStartShift maps 422 to serverErrors under the field', () async {
    final fake = _FakeShiftService()
      ..startError = ValidationException(
        'The opening cash field is required.',
        {'opening_cash': ['The opening cash field is required.']},
      );
    final ctr = ShiftController(service: fake);
    ctr.openingCashController.text = '100';

    await ctr.onStartShift();

    expect(ctr.serverErrors['opening_cash'], isNotNull);
    expect(ctr.currentShift.value, isNull);
    expect(ctr.isSaving.value, isFalse);
  });

  test('onStartShift validates before calling the API', () async {
    final fake = _FakeShiftService();
    final ctr = ShiftController(service: fake);
    ctr.openingCashController.text = '';

    await ctr.onStartShift();

    expect(fake.startCalls, 0);
    expect(ctr.serverErrors['opening_cash'], isNotNull);
  });

  testWidgets('onCloseShift clears currentShift and reloads history',
      (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));

    final fake = _FakeShiftService();
    await fake.start({'opening_cash': 50.0});
    final ctr = ShiftController(service: fake);
    await ctr.loadCurrent();
    ctr.closingCashController.text = '80.25';

    await ctr.onCloseShift();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(ctr.hasOpenShift, isFalse);
    expect(ctr.closingCashController.text, isEmpty);
    expect(ctr.shifts, hasLength(1));
    expect(ctr.shifts.first['closing_cash'], '80.25');
    expect(ctr.isSaving.value, isFalse);
  });

  testWidgets('onCloseShift sends no notes', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));

    final fake = _FakeShiftService();
    await fake.start({'opening_cash': 50.0});
    final ctr = ShiftController(service: fake);
    await ctr.loadCurrent();
    ctr.startNotesController.text = 'A start note';
    ctr.closingCashController.text = '80';

    await ctr.onCloseShift();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(fake.lastClosePayload!.keys.toList(), ['closing_cash']);
  });

  testWidgets('onCloseShift on 409 already-closed resyncs to no open shift',
      (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));

    final fake = _FakeShiftService(); // getCurrent → {'data': null}
    final ctr = ShiftController(service: fake);
    ctr.currentShift.value = {'id': 7}; // stale local state
    ctr.closingCashController.text = '80';

    await ctr.onCloseShift(); // close(7) throws 'This shift is already closed.'
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(ctr.hasOpenShift, isFalse);
    expect(ctr.isSaving.value, isFalse);
  });

  test('start/close ignore re-entry while saving', () async {
    final fake = _FakeShiftService();
    final ctr = ShiftController(service: fake);
    ctr.currentShift.value = {'id': 7};
    ctr.openingCashController.text = '100';
    ctr.closingCashController.text = '80';
    ctr.isSaving.value = true;

    await ctr.onStartShift();
    await ctr.onCloseShift();

    expect(fake.startCalls, 0);
    expect(fake.closeCalls, 0);
  });
}
