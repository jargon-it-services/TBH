import 'dart:async';

import 'package:flutter/widgets.dart';

import 'connectivity_service.dart';

/// Mix into any `State` to get automatic "retry when back online" for
/// free — but only when it actually makes sense to.
///
/// This implements Option C from the connectivity review: reload
/// automatically ONLY IF the screen's most recent load attempt failed
/// specifically because of no internet connection. A screen that
/// already has valid data on screen, or that failed for an unrelated
/// reason (a 500, a bad response), is left alone. Auto-refreshing every
/// screen on every reconnect (Option A) would be wasteful for screens
/// that already loaded fine, and could yank a screen out from under a
/// user who's mid-interaction with it for no reason.
///
/// Usage — a screen just needs to record whether its last failure was
/// connectivity-related, and say what "retry" means for it:
///
/// ```dart
/// class _MyPageState extends State<MyPage> with ConnectivityAwareRefresh {
///   Future<void> _load() async {
///     final response = await _api.fetch();
///     lastLoadFailedDueToConnectivity =
///         !response.isSuccess && response.isConnectivityError;
///     ...
///   }
///
///   @override
///   Future<void> onReconnected() => _load();
/// }
/// ```
mixin ConnectivityAwareRefresh<T extends StatefulWidget> on State<T> {
  StreamSubscription<bool>? _connectivitySubscription;

  /// Set this after every load attempt: true only when that attempt
  /// failed specifically due to [ApiResponse.isConnectivityError] being
  /// true. Left false after a successful load, or a failure for any
  /// other reason — those cases must never trigger an auto-retry here.
  bool lastLoadFailedDueToConnectivity = false;

  /// Called when connectivity comes back AND the last load failed due
  /// to connectivity. Implementations should just re-run whatever
  /// method the screen already uses to load its data (the same one
  /// `initState` and the Retry button call) — no new loading logic
  /// needed here.
  Future<void> onReconnected();

  @override
  void initState() {
    super.initState();
    _connectivitySubscription = ConnectivityService.instance.onStatusChange
        .listen((isOnline) {
          if (isOnline && lastLoadFailedDueToConnectivity) {
            lastLoadFailedDueToConnectivity = false;
            onReconnected();
          }
        });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
