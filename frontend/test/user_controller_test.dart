import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/controllers/user_controller.dart';
import 'package:frontend/locator.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/main_service/staff_service.dart';
import 'package:frontend/services/storage_service.dart';
import 'package:get/get.dart';

void main() {
  setUpAll(() {
    // ApiService reads API_URL from dotenv at construction time.
    dotenv.testLoad(fileInput: 'API_URL=http://127.0.0.1:8000/api/v1');

    // canManage() reads the logged-in user through the locator.
    if (!locator.isRegistered<IStorageService>()) {
      locator.registerSingleton<IStorageService>(_FakeStorageService());
    }
  });

  UserController withStaff() {
    final ctr = UserController();

    ctr.staffList.assignAll([
      {
        'id': 1,
        'name': 'Mia Staff',
        'role': 'cashier',
        'is_active': true,
        'staff_profile': {
          'employee_code': 'EMP-001',
          'hire_date': '2025-01-15',
          'hourly_rate': '8.50',
        },
      },
      {
        'id': 2,
        'name': 'Sokha',
        'role': 'manager',
        'is_active': false,
        'staff_profile': null,
      },
      {
        'id': 3,
        'name': 'Dara Owner',
        'role': 'owner',
        'is_active': true,
        'staff_profile': {
          'employee_code': 'EMP-100',
          'hire_date': '2024-12-01',
        },
      },
    ]);

    return ctr;
  }

  test('onSearchStaff matches name, employee code, role and hire date', () {
    final ctr = withStaff();

    ctr.onSearchStaff('mia');
    expect(ctr.searchStaffList.map((s) => s['id']).toList(), [1]);

    ctr.onSearchStaff('emp-100');
    expect(ctr.searchStaffList.map((s) => s['id']).toList(), [3]);

    // Keywords are case-insensitive.
    ctr.onSearchStaff('EMP-100');
    expect(ctr.searchStaffList.map((s) => s['id']).toList(), [3]);

    ctr.onSearchStaff('manager');
    expect(ctr.searchStaffList.map((s) => s['id']).toList(), [2]);

    ctr.onSearchStaff('2025-01');
    expect(ctr.searchStaffList.map((s) => s['id']).toList(), [1]);

    ctr.onSearchStaff('  ');
    expect(ctr.searchStaffList.length, 3);
  });

  test('applyFilters combines the role and status filters', () {
    final ctr = withStaff();

    ctr.roleFilter.value = 'manager';
    ctr.applyFilters();
    expect(ctr.searchStaffList.map((s) => s['id']).toList(), [2]);

    ctr.roleFilter.value = 'all';
    ctr.statusFilter.value = 'inactive';
    ctr.applyFilters();
    expect(ctr.searchStaffList.map((s) => s['id']).toList(), [2]);

    ctr.statusFilter.value = 'active';
    ctr.applyFilters();
    expect(ctr.searchStaffList.map((s) => s['id']).toList(), [1, 3]);

    // Both filters apply at once: the inactive manager drops out.
    ctr.roleFilter.value = 'manager';
    ctr.applyFilters();
    expect(ctr.searchStaffList, isEmpty);

    // Keyword and filters combine.
    ctr.roleFilter.value = 'cashier';
    ctr.onSearchStaff('mia');
    expect(ctr.searchStaffList.map((s) => s['id']).toList(), [1]);
  });

  test('buildUserPayload echoes the confirmation and never sends user_id', () {
    final ctr = UserController();
    ctr.nameController.text = ' Mia ';
    ctr.emailController.text = 'mia@cafe.local';
    ctr.passwordController.text = 'password123';
    ctr.roleController.value = 'manager';

    final payload = ctr.buildUserPayload();

    expect(payload['name'], 'Mia');
    expect(payload['password_confirmation'], 'password123');
    expect(payload['role'], 'manager');
    expect(payload.containsKey('user_id'), isFalse);
  });

  test('buildStaffPayload sends user_id, trimmed code and nulls for blanks', () {
    final ctr = UserController();
    ctr.employeeCodeController.text = ' EMP-002 ';
    ctr.hireDateController.clear();
    ctr.hourlyRateController.text = '8.50';
    ctr.emergencyContactController.clear();

    final payload = ctr.buildStaffPayload(7);

    expect(payload['user_id'], 7);
    expect(payload['employee_code'], 'EMP-002');
    expect(payload['hire_date'], isNull);
    expect(payload['hourly_rate'], '8.50');
    expect(payload['emergency_contact'], isNull);
  });

  test('buildUpdatePayload clears blanks to null and omits account fields', () {
    final ctr = UserController();
    ctr.nameController.text = 'Mia K';
    ctr.employeeCodeController.text = 'EMP-002';
    ctr.hireDateController.text = '2026-02-01';
    ctr.hourlyRateController.text = '10.25';
    ctr.phoneController.clear();
    ctr.emergencyContactController.clear();

    final payload = ctr.buildUpdatePayload();

    expect(payload['name'], 'Mia K');
    expect(payload['employee_code'], 'EMP-002');
    expect(payload['phone'], isNull);
    expect(payload['emergency_contact'], isNull);
    expect(payload['hire_date'], '2026-02-01');
    expect(payload['hourly_rate'], '10.25');
    expect(payload.containsKey('user_id'), isFalse);
    expect(payload.containsKey('email'), isFalse);
    expect(payload.containsKey('role'), isFalse);
    expect(payload.containsKey('password'), isFalse);
  });

  // Widget shell only because ToastWidget needs a live overlay.
  testWidgets('a failed profile save retries only the staff profile', (
    tester,
  ) async {
    await tester.pumpWidget(const GetMaterialApp(home: SizedBox()));

    // A 422 on the profile call takes the field-error path, so no toast fires.
    final service = _FakeStaffService()
      ..failCreateStaff = ValidationException(
        'The employee code has already been taken.',
        {
          'employee_code': ['Taken.'],
        },
      );
    final ctr = UserController(service);
    ctr.nameController.text = 'Mia';
    ctr.emailController.text = 'mia@cafe.local';
    ctr.passwordController.text = 'password123';

    await ctr.onSaveStaffCreate();
    await tester.pumpAndSettle();

    expect(service.countOf('createUser'), 1);
    expect(service.countOf('createStaff'), 1);

    // The retry must not POST /users again ("email already taken") nor leave
    // a login user without a profile.
    service.failCreateStaff = null;
    await ctr.onSaveStaffCreate();
    await tester.pumpAndSettle();

    expect(service.countOf('createUser'), 1);
    expect(service.countOf('createStaff'), 2);

    Get.closeAllSnackbars();
    await tester.pumpAndSettle();
    Get.reset();
  });

  testWidgets('refuses to deactivate your own account', (tester) async {
    final service = _FakeStaffService();
    final ctr = UserController(service);

    late BuildContext context;
    await tester.pumpWidget(
      GetMaterialApp(
        home: Builder(
          builder: (ctx) {
            context = ctx;
            return const SizedBox();
          },
        ),
      ),
    );

    await ctr.onDeleteStaff(5, context);
    await tester.pumpAndSettle();

    expect(service.calls, isNot(contains('deleteStaff')));

    Get.closeAllSnackbars();
    await tester.pumpAndSettle();
    Get.reset();
  });
}

/// Logged-in owner/admin with id 5: drives canManage and the self-guard.
class _FakeStorageService implements IStorageService {
  @override
  Map<String, dynamic> get lastUserLoginRead =>
      {'user': {'id': 5, 'role': 'admin'}};

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeStaffService extends StaffService {
  final List<String> calls = [];
  Object? failCreateStaff;

  int countOf(String name) => calls.where((c) => c == name).length;

  @override
  Future<dynamic> getStaff() async {
    calls.add('getStaff');
    return {'data': <dynamic>[]};
  }

  @override
  Future<dynamic> createUser(Map<String, dynamic> data) async {
    calls.add('createUser');
    return {'data': {'id': 7}};
  }

  @override
  Future<dynamic> createStaff(Map<String, dynamic> data) async {
    calls.add('createStaff');
    final failure = failCreateStaff;
    if (failure != null) throw failure;
    return {'data': {'id': 7}};
  }

  @override
  Future<dynamic> updateStaff(int userId, Map<String, dynamic> data) async {
    calls.add('updateStaff');
    return {'data': {}};
  }

  @override
  Future<dynamic> deleteStaff(int userId) async {
    calls.add('deleteStaff');
    return null;
  }
}