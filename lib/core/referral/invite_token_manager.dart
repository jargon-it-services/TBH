import '../storage/secure_storage_service.dart';

/// Persists the opaque invite token (and ONLY the invite token — never
/// an account code, referral code, user id, business id, or any other
/// personal information) across app restarts, from the moment an
/// invite link is opened until registration is confirmed successful.
///
/// Backed by [SecureStorageService] — the same secure, encrypted,
/// on-device storage [SessionManager] already uses for the auth token
/// — rather than introducing a second storage mechanism.
///
/// Deliberately minimal: this class only knows how to save/read/check/
/// clear a single opaque string. It has no opinion on *when* those
/// things should happen — that's [DeepLinkService] (saves it) and
/// [RegistrationApi] (reads it, then clears it once registration is
/// confirmed successful, or once the backend confirms the invite was
/// invalid/expired/revoked).
class InviteTokenManager {
  static const _inviteTokenKey = 'invite_token';

  final SecureStorageService _storage = SecureStorageService();

  /// Stores the invite token, overwriting any previously stored value
  /// (e.g. if the user opens a second, different invite link before
  /// registering).
  Future<void> saveToken(String token) {
    return _storage.write(_inviteTokenKey, token);
  }

  /// Returns the currently stored invite token, or null if none exists.
  Future<String?> getToken() {
    return _storage.read(_inviteTokenKey);
  }

  /// True if an invite token is currently stored.
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Deletes the stored invite token. Called once registration is
  /// confirmed successful, or once the backend confirms the token was
  /// invalid/expired/revoked — never before either of those is known.
  Future<void> clearToken() {
    return _storage.delete(_inviteTokenKey);
  }
}
