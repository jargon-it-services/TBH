import 'package:dio/dio.dart';

import '../connectivity/connectivity_service.dart';
import '../navigation/app_navigator.dart';
import '../session/session_manager.dart';
import 'api_exceptions.dart';
import 'apis/refresh_token_api.dart';
import 'env.dart';

/// Outcome of an attempted token refresh — see [DioClient._refreshToken].
///
/// Distinguishing these matters: only [invalid] is a genuine "this
/// session is over" signal. [networkError] means the refresh attempt
/// itself couldn't complete (timeout, no connectivity, 5xx, malformed
/// response) — that says nothing about whether the refresh token is
/// still good, so it must NOT force a logout.
enum _RefreshOutcome { success, invalid, networkError }

class DioClient {
  // Singleton: every `*_api.dart` file does `final DioClient _client =
  // DioClient();`. Making this a factory returning one shared instance
  // (instead of a plain constructor building a new Dio + interceptor
  // chain every time) means they all share one Dio instance for free —
  // no call site elsewhere needs to change for this.
  static final DioClient _instance = DioClient._internal();

  factory DioClient() => _instance;

  late final Dio _dio;

  /// Endpoints that must NOT get an Authorization header, and whose 401s
  /// (e.g. wrong credentials) must NOT be treated as "session expired".
  /// Matched via [_matchesPath], so sub-paths (e.g.
  /// '/forgot-password/verify-otp') stay covered by their parent entry
  /// ('/forgot-password') automatically.
  ///
  /// This is the single place that decides public vs. protected — no
  /// `*_api.dart` file needs to know or say anything about auth.
  static const List<String> _publicPaths = [
    '/auth/login',
    '/auth/refresh',
    '/register',
    '/forgot-password',
    // Called from SplashPage before any session necessarily exists, and
    // has nothing to do with auth — a failure here must never be
    // misread as "session expired" by the 401 handling below.
    '/app/version',
  ];

  /// Protected endpoints that DO get the Authorization header, but whose
  /// own 401 must NOT trigger the refresh/auto-logout machinery below.
  /// Currently just logout: the caller (AccountPage) already runs its
  /// own explicit "clear session, navigate to Login" sequence regardless
  /// of how this call resolves, so having the interceptor *also* react
  /// to a 401 from this specific call would race two independent
  /// "log the user out and navigate" sequences against each other.
  static const List<String> _skipSessionHandlingPaths = [
    '/auth/logout',
  ];

  /// Matches [path] against [prefixes] at a path-segment boundary — an
  /// exact match, or a match followed immediately by '/'. Plain
  /// `startsWith` would let e.g. '/auth/loginx' incorrectly match
  /// '/auth/login'; this guards against that class of bug as more
  /// entries get added over time.
  static bool _matchesPath(String path, List<String> prefixes) {
    return prefixes.any((p) => path == p || path.startsWith('$p/'));
  }

  static bool _isPublic(String path) => _matchesPath(path, _publicPaths);

  static bool _skipsSessionHandling(String path) =>
      _matchesPath(path, _skipSessionHandlingPaths);

  // Shared across every call site, coalescing a burst of concurrent
  // 401s into exactly one in-flight refresh attempt instead of one per
  // caller. (Kept `static` rather than instance-level even though
  // DioClient is now a singleton — no behavior difference either way,
  // just avoids relying on the singleton-ness for correctness here.)
  static Future<_RefreshOutcome>? _refreshFuture;

  DioClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        responseType: ResponseType.json,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          /// 1️⃣ Attach token — skipped for public (unauthenticated) APIs.
          /// (Connectivity is checked in get()/post() below, before this
          /// interceptor even runs, using ConnectivityService's cached
          /// flag — not a fresh DNS lookup on every request.)
          if (!_isPublic(options.path)) {
            final token = await _getToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }

          handler.next(options);
        },
        onError: (e, handler) async {
          /// 2️⃣ Token expired/invalid — only meaningful for protected
          /// requests that aren't explicitly exempted. A 401 from a
          /// public endpoint (e.g. wrong password on login) is a normal
          /// auth failure, not a session event; a 401 from logout itself
          /// is handled entirely by the caller (see
          /// _skipSessionHandlingPaths above).
          final path = e.requestOptions.path;
          final alreadyRetried = e.requestOptions.extra['_isRetry'] == true;

          if (e.response?.statusCode == 401 &&
              !_isPublic(path) &&
              !_skipsSessionHandling(path)) {
            // Loop guard: a request that has already been retried once
            // (post-refresh) must not trigger a second refresh attempt
            // if it 401s again — that would refresh → retry → 401 →
            // refresh → retry → ... forever. This is the resource
            // server rejecting an already-freshly-refreshed token,
            // which is a genuine auth failure (unlike a refresh call
            // itself failing over the network — see below), so this
            // path still logs out unconditionally.
            if (alreadyRetried) {
              await _logoutUser(sessionExpired: true);
              return handler.next(e);
            }

            final outcome = await _handleUnauthorized();

            switch (outcome) {
              case _RefreshOutcome.success:
                try {
                  final retried = await _retry(e.requestOptions);
                  return handler.resolve(retried);
                } catch (_) {
                  // Retry failed too — fall through and surface the
                  // original error below.
                }
                break;
              case _RefreshOutcome.invalid:
                // The refresh token itself was explicitly rejected
                // (401 from /auth/refresh) — this really is "the
                // session is over".
                await _logoutUser(sessionExpired: true);
                break;
              case _RefreshOutcome.networkError:
                // The refresh attempt couldn't complete (timeout, no
                // connectivity, 5xx, malformed response) — that's not
                // a verdict on the session, so don't log the user out.
                // Just let the original request's error surface below
                // so the caller can show a normal, retry-able error.
                break;
            }
          }
          handler.next(e);
        },
      ),
    );
  }

  Future<String?> _getToken() async {
    return SessionManager.instance.token;
  }

  /// Coalesces concurrent 401s (across every call site, since this is
  /// backed by a static field) into a single refresh attempt.
  Future<_RefreshOutcome> _handleUnauthorized() {
    return _refreshFuture ??= _refreshToken().whenComplete(() {
      _refreshFuture = null;
    });
  }

  /// Calls the refresh-token endpoint and, on success, stores the new
  /// JWT (and rotated refresh token, if the backend sends one) via
  /// SessionManager.
  ///
  /// Returns [_RefreshOutcome.invalid] only when there's definitively no
  /// way forward — no refresh token to use, or the server explicitly
  /// rejected it (401). Any other failure (timeout, no connectivity,
  /// 5xx, malformed response) returns [_RefreshOutcome.networkError]
  /// instead, so a transient problem during the refresh call itself
  /// can never force a logout — see docs/refresh_token_backend_contract.md.
  Future<_RefreshOutcome> _refreshToken() async {
    final refreshToken = SessionManager.instance.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      // Nothing to refresh with at all — this is a genuine dead end,
      // not a network problem.
      return _RefreshOutcome.invalid;
    }

    final response =
        await RefreshTokenApi().refresh(refreshToken: refreshToken);

    if (response.isSuccess && response.data != null) {
      await SessionManager.instance.updateToken(
        token: response.data!.authToken,
        refreshToken: response.data!.refreshToken,
      );
      return _RefreshOutcome.success;
    }

    // Only an explicit 401 from the refresh endpoint means the refresh
    // token was rejected. Everything else — timeout, connectivity loss,
    // 5xx, a response that failed to parse — is a transient failure of
    // the refresh attempt, not proof the session is invalid.
    if (response.statusCode == 401) {
      return _RefreshOutcome.invalid;
    }
    return _RefreshOutcome.networkError;
  }

  /// Re-issues a request that failed with 401, after a successful token
  /// refresh, using the (now current) Authorization header. Marked
  /// `_isRetry` so the onError handler above never attempts a second
  /// refresh for the same original request (see the infinite-loop guard
  /// there).
  Future<Response> _retry(RequestOptions requestOptions) async {
    final token = await _getToken();
    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        if (token != null) 'Authorization': 'Bearer $token',
      },
      extra: {...requestOptions.extra, '_isRetry': true},
    );
    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  Future<void> _logoutUser({bool sessionExpired = false}) async {
    await SessionManager.instance.clearSession();
    AppNavigator.goToLoginAndClearStack(sessionExpired: sessionExpired);
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    _ensureOnlineOrThrow();
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
  }) async {
    _ensureOnlineOrThrow();
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Fails fast, before touching Dio/the network at all, if the device
  /// is known to be offline. Reads a cached, synchronous flag —
  /// [ConnectivityService.isOnline] — so this adds no latency to any
  /// request; it's the opposite of the old per-request DNS lookup this
  /// replaced. A request can still hit `DioExceptionType.connectionError`
  /// mid-flight (e.g. connectivity drops after this check passes); that
  /// case is handled by [ApiException.fromDioError] instead, and is
  /// still correctly flagged `isConnectivityError`.
  void _ensureOnlineOrThrow() {
    if (!ConnectivityService.instance.isOnline) {
      throw ApiException('No internet connection', null, true);
    }
  }
}
