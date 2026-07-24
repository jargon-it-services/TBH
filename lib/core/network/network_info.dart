import 'dart:io';

/// Lightweight connectivity check via DNS lookup.
///
/// NOTE: no longer used by [DioClient]'s interceptor. It previously ran
/// on every single outgoing request, pinging a hardcoded third-party
/// host ('google.com') purely to decide whether to fail fast with "No
/// Internet" before attempting the real request. That added a DNS
/// round-trip of latency to every call and depended on a host that has
/// nothing to do with this app. Dio's own `DioExceptionType.connectionError`
/// (already mapped to the same "No internet connection" message via
/// `ApiException.fromDioError`) covers the same case without either
/// downside — so the pre-flight check was removed rather than pointed
/// at a different host.
///
/// Left in place as a general-purpose utility in case a specific screen
/// wants an explicit "are we online" check outside of an API call (e.g.
/// showing a banner) — just isn't part of the default request path
/// anymore.
class NetworkInfo {
  Future<bool> get isConnected async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
