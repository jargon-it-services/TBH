import 'dart:convert';

import '../models/user_role.dart';
import '../services/DataModels/login_response_model.dart';
import '../storage/secure_storage_service.dart';

/// Authentication state of the app, as understood by [SessionManager].
///
/// - [unknown]: app just started, [SessionManager.restoreSession] hasn't
///   resolved yet (used by SplashPage while it waits).
/// - [authenticated]: a valid session (token + user) is loaded in memory.
/// - [unauthenticated]: no session, or the session was cleared/expired.
enum AuthStatus { unknown, authenticated, unauthenticated }

/// Minimal in-memory representation of "who is logged in right now".
/// Mirrors what [LoginResult] carries (token, display name/role, and
/// — since the login response nesting change — the account's plan,
/// management counters, and feature-lock list), plus an optional
/// refresh token for the refresh-token flow — optional because the
/// current login response doesn't issue one yet (see
/// docs/refresh_token_backend_contract.md); everything here already
/// works correctly with it left null.
///
/// [userName] and [role] stay as top-level fields (rather than only
/// living on [userInfo]) so every existing reader —
/// `SessionManager.instance.role`, `.userName` — keeps working
/// unchanged after the login response nesting change.
class UserSession {
  final String token;
  final String userName;
  final UserRole role;
  final String? refreshToken;

  /// Seconds-to-live for [token], as returned by login's `expires_in`.
  /// Null for a session saved/restored before this field existed, or
  /// if the backend omits it.
  final int? expiresIn;

  /// Full user profile from login's `user_info` (id, email, mobile,
  /// profile image, status) — [userName]/[role] above are the subset
  /// of this that already had dedicated fields pre-migration.
  final LoginUserInfo? userInfo;

  /// The account/organization from login's `account` block.
  final LoginAccountInfo? account;

  /// The account's current plan from login's `recent_plan` block.
  final LoginRecentPlan? recentPlan;

  /// Account-wide usage counters from login's `management` block.
  final LoginManagementInfo? management;

  /// Feature keys locked under the account's current plan (e.g.
  /// `["report", "payment_slip", "pnl"]`). Empty when nothing is
  /// locked or the backend omitted the field.
  final List<String> featureLock;

  const UserSession({
    required this.token,
    required this.userName,
    required this.role,
    this.refreshToken,
    this.expiresIn,
    this.userInfo,
    this.account,
    this.recentPlan,
    this.management,
    this.featureLock = const [],
  });

  /// Convenience check for gating a feature behind the account's
  /// current plan, e.g. `SessionManager.instance.currentSession
  /// ?.isFeatureLocked('report')`.
  bool isFeatureLocked(String featureKey) => featureLock.contains(featureKey);
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

  /// Everything added by the login-response nesting change
  /// (`expires_in`, `user_info`, `account`, `recent_plan`,
  /// `management`, `feature_lock`) is persisted together as one JSON
  /// blob under this key, rather than one secure-storage key per
  /// field — keeps the storage surface from growing unbounded as the
  /// login payload gains more nested blocks over time.
  static const _extraKey = 'auth_session_extra';

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

  /// The full current session, including the login-nesting-change
  /// fields ([UserSession.userInfo], [UserSession.account],
  /// [UserSession.recentPlan], [UserSession.management],
  /// [UserSession.featureLock]). Null when there is no active session.
  UserSession? get currentSession => _session;

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
      final extraJson = await _storage.read(_extraKey);
      final extra = _decodeExtra(extraJson);

      if (token != null && token.isNotEmpty) {
        _session = UserSession(
          token: token,
          userName: userName ?? '',
          role: UserRole.fromApiValue(roleValue),
          refreshToken: refreshToken,
          expiresIn: extra.expiresIn,
          userInfo: extra.userInfo,
          account: extra.account,
          recentPlan: extra.recentPlan,
          management: extra.management,
          featureLock: extra.featureLock,
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
  ///
  /// [expiresIn], [userInfo], [account], [recentPlan], [management],
  /// and [featureLock] carry the data introduced by the login response
  /// nesting change; all are optional so callers on the old flat
  /// response shape (if any remained) would still compile.
  Future<void> saveSession({
    required String token,
    required String userName,
    required UserRole role,
    String? refreshToken,
    int? expiresIn,
    LoginUserInfo? userInfo,
    LoginAccountInfo? account,
    LoginRecentPlan? recentPlan,
    LoginManagementInfo? management,
    List<String> featureLock = const [],
  }) async {
    await _storage.write(_tokenKey, token);
    await _storage.write(_userNameKey, userName);
    await _storage.write(_roleKey, role.apiValue);
    if (refreshToken != null) {
      await _storage.write(_refreshTokenKey, refreshToken);
    }
    await _storage.write(
      _extraKey,
      _encodeExtra(
        expiresIn: expiresIn,
        userInfo: userInfo,
        account: account,
        recentPlan: recentPlan,
        management: management,
        featureLock: featureLock,
      ),
    );

    _session = UserSession(
      token: token,
      userName: userName,
      role: role,
      refreshToken: refreshToken,
      expiresIn: expiresIn,
      userInfo: userInfo,
      account: account,
      recentPlan: recentPlan,
      management: management,
      featureLock: featureLock,
    );
    _status = AuthStatus.authenticated;
    // Any future restoreSession() call after this point should reflect
    // the session we just saved, not a stale in-flight read from before login.
    _restoreFuture = Future.value(true);
  }

  /// Updates just the token (and optionally the refresh token) of an
  /// already-active session, keeping the current user name and all
  /// other session data — used by DioClient after a successful
  /// refresh-token call. Does nothing if there is no active session to
  /// update.
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
      expiresIn: _session!.expiresIn,
      userInfo: _session!.userInfo,
      account: _session!.account,
      recentPlan: _session!.recentPlan,
      management: _session!.management,
      featureLock: _session!.featureLock,
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
    await _storage.delete(_extraKey);

    _session = null;
    _status = AuthStatus.unauthenticated;
    _restoreFuture = Future.value(false);
  }

  String _encodeExtra({
    required int? expiresIn,
    required LoginUserInfo? userInfo,
    required LoginAccountInfo? account,
    required LoginRecentPlan? recentPlan,
    required LoginManagementInfo? management,
    required List<String> featureLock,
  }) {
    return jsonEncode({
      if (expiresIn != null) 'expires_in': expiresIn,
      if (userInfo != null) 'user_info': userInfo.toJson(),
      if (account != null) 'account': account.toJson(),
      if (recentPlan != null) 'recent_plan': recentPlan.toJson(),
      if (management != null) 'management': management.toJson(),
      'feature_lock': featureLock,
    });
  }

  /// Decodes the [_extraKey] blob back into typed values. Never throws
  /// — a missing, empty, or corrupt blob (e.g. a session saved before
  /// this field existed) just yields all-null/empty, so
  /// [_restoreSessionInternal] still succeeds using the older
  /// token/userName/role fields alone.
  _DecodedExtra _decodeExtra(String? raw) {
    if (raw == null || raw.isEmpty) return const _DecodedExtra();
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return _DecodedExtra(
        expiresIn: (map['expires_in'] as num?)?.toInt(),
        userInfo: map['user_info'] != null
            ? LoginUserInfo.fromJson(map['user_info'])
            : null,
        account: map['account'] != null
            ? LoginAccountInfo.fromJson(map['account'])
            : null,
        recentPlan: map['recent_plan'] != null
            ? LoginRecentPlan.fromJson(map['recent_plan'])
            : null,
        management: map['management'] != null
            ? LoginManagementInfo.fromJson(map['management'])
            : null,
        featureLock:
            (map['feature_lock'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
      );
    } catch (_) {
      return const _DecodedExtra();
    }
  }
}

/// Plain holder for the decoded [SessionManager._extraKey] blob.
class _DecodedExtra {
  final int? expiresIn;
  final LoginUserInfo? userInfo;
  final LoginAccountInfo? account;
  final LoginRecentPlan? recentPlan;
  final LoginManagementInfo? management;
  final List<String> featureLock;

  const _DecodedExtra({
    this.expiresIn,
    this.userInfo,
    this.account,
    this.recentPlan,
    this.management,
    this.featureLock = const [],
  });
}
