import 'package:frontend/constants/enum.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:convert';

import 'package:frontend/utils/helper.dart';


final _box = GetStorage(".appsettings");
final _helper = Helper();

abstract class IStorageService {
  T? readStorage<T>(StorageKey key);
  Future<void> writeStorage(StorageKey key, dynamic value);
  Future<void> removeStorage(StorageKey key);
  Future<void> removeStorageMultiple(List<StorageKey> keys);
  //startup route
  Future<void> appStartUpWrite({required String route});
  String get appStartUpRead;

  //current user login
  Future<void> lastUserLoginWrite({required Map<String, dynamic> data});
  Future<void> lastUserLoginRemove();
  Map<String, dynamic> get lastUserLoginRead;

}

class StorageService implements IStorageService {
  ///method get storage value
  @override
  T? readStorage<T>(StorageKey key) {
    final vkey = key.toString().split('.').last; // Output: active
    if (_box.hasData(vkey)) {
      return _box.read<T>(vkey);
    }
    return null;
  }

  ///method write storage value
  @override
  Future<void> writeStorage(StorageKey key, dynamic value) async {
    final vkey = key.toString().split('.').last; // Output: active
    _box.write(vkey, value);
  }

  ///method remove storage key
  @override
  Future<void> removeStorage(StorageKey key) async {
    _removeStorage(key);
  }

  ///method remove multiple storage keys
  @override
  Future<void> removeStorageMultiple(List<StorageKey> keys) async {
    for (var k in keys) {
      await _removeStorage(k);
    }
  }
  
  ///method remove storage key
  Future<void> _removeStorage(StorageKey key) async {
    final vkey = key.toString().split('.').last; // Output: active
    _box.remove(vkey);
  }

  @override
  Future<void> appStartUpWrite({required String route}) async {
    await writeStorage(StorageKey.appStartUp, route);
  }

  @override
  String get appStartUpRead {
    String? route = readStorage<String>(StorageKey.appStartUp);
    return route ?? "";
  }

  //Last user login
  @override
  Future<void> lastUserLoginWrite({
    required Map<String, dynamic> data,
  }) async {
    var encryptData = _helper.onEncrypted(jsonEncode(data));

    await writeStorage(StorageKey.lastUserLogin, encryptData);
   
  }

  @override
  Future<void> lastUserLoginRemove() async {
    await removeStorage(StorageKey.lastUserLogin);
  }

  @override
  Map<String, dynamic> get lastUserLoginRead {
    var data = readStorage<String>(StorageKey.lastUserLogin);
    if (data != null) {
      Map<String, dynamic> result = jsonDecode(_helper.onDecrypted(data));
      return result;
    }
    return {};
  }
  
}
