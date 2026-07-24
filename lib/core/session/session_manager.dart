import '../models/user_role.dart';
import '../storage/secure_storage_service.dart';

/// Authentication state of the app, as understood by [SessionManager].
///
/// - [unknown]: app just started, [SessionManager.restoreSession] hasn't
///   resolved yet (used by SplashPage while it waits).
/// - [authenticated]: a valid session (token + user) is loaded in memory.
/// - [unauthenticated]: no session, or the session was cleared/expired.
enum AuthStatus { unknown, authenticated, unauthenticated }

/// Minimal in-memory representation of "who is logged in right now".
/// Mirrors what [LoginResult] already carries (token + display name),
/// plus an optional refresh token for the refresh-token flow — optional
/// because the current login response doesn't issue one yet (see
/// docs/refresh_token_backend_contract.md); everything here already
/// works correctly with it left null.
class UserSession {
  final String token;
  final String userName;
  final UserRole role;
  final String? refreshToken;

  const UserSession({
    required this.token,
    required this.userName,
    required this.role,
    this.refreshToken,
  });
}

/// Single source of truth for the current auth session.
///
/// This is the piece that was missing from the existing architecture:
/// even now that `DioClient` is a singleton shared by every `*_api.dart`
/// file, there was nowhere for a token to live that all of them could
/// read/write consistently. `SessionManager` fills that gap as a plain
/// singleton (`SessionManager.instance`) — the smallest change
/// consistent with the app's existing "no DI container" pattern.
///
/// Responsibilities:
/// - Save a session (after login) to secure storage + memory.
/// - Restore a session (on app start) from secure storage into memory.
/// - Clear a session (e.g. on a 401 from DioClient).
/// - Expose the current token/user/status to whoever needs it
///   (DioClient, LoginPage, SplashPage), without any of them needing to
///   know how/where it's persisted.
class SessionManager {
  SessionManager._internal();

  static final SessionManager instance = SessionManager._internal();

  static const _tokenKey = 'auth_token';
  static const _userNameKey = 'auth_user_name';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _roleKey = 'auth_user_role';

  final SecureStorageService _storage = SecureStorageService();

  UserSession? _session;
  AuthStatus _status = AuthStatus.unknown;

  // Guards against restoreSession() being kicked off more than once
  // concurrently (e.g. if something else calls it while SplashPage's
  // restore is still in flight) — every caller awaits the same Future
  // instead of racing separate reads of secure storage.
  Future<bool>? _restoreFuture;

  AuthStatus get status => _status;

  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Current bearer token, if any. Read by [DioClient] on every request.
  String? get token => _session?.token;

  /// Current user's display name, if any.
  String? get userName => _session?.userName;

  /// Current user's role. Defaults to [UserRole.employee] (the
  /// least-privileged role) when there is no active session, so
  /// reading this before a session exists fails safe rather than
  /// throwing.
  UserRole get role => _session?.role ?? UserRole.employee;

  /// Current refresh token, if any. Read by DioClient's refresh-token
  /// flow. Will be null until a backend refresh endpoint exists and
  /// login starts returning one — see docs/refresh_token_backend_contract.md.
  String? get refreshToken => _session?.refreshToken;

  /// Reads any persisted session from secure storage into memory and
  /// updates [status] accordingly. Safe to call multiple times — later
  /// calls await the same in-flight restore rather than re-reading
  /// storage. Returns whether a valid session was found.
  Future<bool> restoreSession() {
    return _restoreFuture ??= _restoreSessionInternal();
  }

  Future<bool> _restoreSessionInternal() async {
    try {
      final token = await _storage.read(_tokenKey);
      final userName = await _storage.read(_userNameKey);
      final refreshToken = await _storage.read(_refreshTokenKey);
      final roleValue = await _storage.read(_roleKey);

      if (token != null && token.isNotEmpty) {
        _session = UserSession(
          token: token,
          userName: userName ?? '',
          role: UserRole.fromApiValue(roleValue),
          refreshToken: refreshToken,
        );
        _status = AuthStatus.authenticated;
      } else {
        _session = null;
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      // If secure storage can't be read (corrupt entry, platform error,
      // etc.) fail safe into "logged out" rather than leaving the app in
      // an indeterminate state.
      _session = null;
      _status = AuthStatus.unauthenticated;
    }
    return isAuthenticated;
  }

  /// Persists a newly-created session (post-login) to secure storage and
  /// makes it immediately available in memory. [refreshToken] is
  /// optional since the current login response doesn't issue one yet.
  Future<void> saveSession({
    required String token,
    required String userName,
    required UserRole role,
    String? refreshToken,
  }) async {
    await _storage.write(_tokenKey, token);
    await _storage.write(_userNameKey, userName);
    await _storage.write(_roleKey, role.apiValue);
    if (refreshToken != null) {
      await _storage.write(_refreshTokenKey, refreshToken);
    }

    _session = UserSession(
      token: token,
      userName: userName,
      role: role,
      refreshToken: refreshToken,
    );
    _status = AuthStatus.authenticated;
    // Any future restoreSession() call after this point should reflect
    // the session we just saved, not a stale in-flight read from before login.
    _restoreFuture = Future.value(true);
  }

  /// Updates just the token (and optionally the refresh token) of an
  /// already-active session, keeping the current user name — used by
  /// DioClient after a successful refresh-token call. Does nothing if
  /// there is no active session to update.
  Future<void> updateToken({
    required String token,
    String? refreshToken,
  }) async {
    if (_session == null) return;

    await _storage.write(_tokenKey, token);
    if (refreshToken != null) {
      await _storage.write(_refreshTokenKey, refreshToken);
    }

    _session = UserSession(
      token: token,
      userName: _session!.userName,
      role: _session!.role,
      refreshToken: refreshToken ?? _session!.refreshToken,
    );
    _status = AuthStatus.authenticated;
  }

  /// Clears the session from both memory and secure storage. Called on
  /// logout (future work) and when the refresh-token flow ultimately
  /// fails (401 → refresh fails → clear session → caller navigates to
  /// Login).
  Future<void> clearSession() async {
    await _storage.delete(_tokenKey);
    await _storage.delete(_userNameKey);
    await _storage.delete(_refreshTokenKey);
    await _storage.delete(_roleKey);

    _session = null;
    _status = AuthStatus.unauthenticated;
    _restoreFuture = Future.value(false);
  }
}
