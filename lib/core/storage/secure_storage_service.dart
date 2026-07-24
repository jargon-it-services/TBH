import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around [FlutterSecureStorage].
///
/// This is the ONLY place in the app allowed to touch secure storage
/// directly — everything else (e.g. [SessionManager]) goes through this
/// service instead of importing `flutter_secure_storage` itself. Kept
/// deliberately generic (string key/value in, string/null out) so it can
/// be reused for anything else that needs secure, encrypted, on-device
/// storage later (not just the auth token), the same way [NetworkInfo]
/// is a small reusable primitive rather than something auth-specific.
///
/// Backed by Keychain on iOS/macOS and EncryptedSharedPreferences /
/// Android Keystore-backed ciphers on Android — never plain
/// SharedPreferences, so this must be used instead of `shared_preferences`
/// for anything sensitive (tokens, credentials, etc.).
class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> write(String key, String value) {
    return _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) {
    return _storage.read(key: key);
  }

  Future<void> delete(String key) {
    return _storage.delete(key: key);
  }
}
