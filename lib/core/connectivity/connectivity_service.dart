import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../network/network_info.dart';

/// Single source of truth for "is the device online right now", shared
/// across every screen — the same singleton pattern already used by
/// `SessionManager`/`OnboardingManager`, so this doesn't introduce a new
/// architectural style.
///
/// Two signals are combined on purpose:
/// - `connectivity_plus` tells us WHEN something changed (attached to /
///   detached from a network) — fast and event-driven, no per-request
///   polling anywhere.
/// - [NetworkInfo] (already in the codebase, previously used inside
///   DioClient's interceptor) confirms that network actually reaches the
///   internet. `connectivity_plus` alone can't do this — e.g. connected
///   to a Wi-Fi network with no real internet (a hotel captive portal)
///   still reports "wifi" as connected.
///
/// A sparse backup poll (every 15s, while the app is running) runs
/// alongside the event stream as a safety net for the rare cases an OS
/// doesn't fire a change event promptly — this is a background heartbeat,
/// not something that runs per API call, so it doesn't add latency or
/// volume to actual requests.
class ConnectivityService {
  ConnectivityService._internal();

  static final ConnectivityService instance =
      ConnectivityService._internal();

  static const _backupPollInterval = Duration(seconds: 15);

  final NetworkInfo _networkInfo = NetworkInfo();
  final StreamController<bool> _statusController =
      StreamController<bool>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _osSubscription;
  Timer? _backupTimer;
  bool _isOnline = true;
  bool _initialized = false;

  /// Broadcasts only on actual state *changes* (online -> offline or the
  /// reverse) — never fires repeatedly for an unchanged state, so
  /// listeners (the global banner, screen-level auto-refresh) can't
  /// double-fire for the same event.
  Stream<bool> get onStatusChange => _statusController.stream;

  /// Cached, synchronous — reading this never makes a network call. This
  /// is what `DioClient` checks before every request.
  bool get isOnline => _isOnline;

  /// Starts monitoring. Call once, at app startup (see main.dart). Safe
  /// to call more than once — later calls are no-ops.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _isOnline = await _networkInfo.isConnected;

    _osSubscription =
        Connectivity().onConnectivityChanged.listen((_) => _recheck());

    _backupTimer = Timer.periodic(_backupPollInterval, (_) => _recheck());
  }

  /// Forces an immediate real check — e.g. for a manual "Retry" button —
  /// instead of waiting for the next event/poll. Returns the (possibly
  /// updated) online state.
  Future<bool> checkNow() async {
    await _recheck();
    return _isOnline;
  }

  Future<void> _recheck() async {
    final online = await _networkInfo.isConnected;
    if (online == _isOnline) return; // no change -> no broadcast
    _isOnline = online;
    _statusController.add(_isOnline);
  }

  /// Not called anywhere today (this service lives for the app's whole
  /// lifetime), but provided for completeness / testability.
  void dispose() {
    _osSubscription?.cancel();
    _backupTimer?.cancel();
    _statusController.close();
  }
}
