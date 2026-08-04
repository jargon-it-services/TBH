import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../navigation/notification_navigator.dart';
import '../network/env.dart';

/// OneSignal integration for the Notification Module.
///
/// Per `04_OneSignal_Integration.md`'s flow --
/// `OneSignal -> Parse Payload -> Validate -> Mark Read ->
/// NotificationNavigator -> display_mode -> Destination Resolver` --
/// this file's only job is steps 1 and 2 (receive + parse); everything
/// from "mark read" onward is delegated to [NotificationNavigator], so
/// this file contains zero navigation/destination logic of its own.
///
/// A plain static-method service (`NotificationPushService.instance...`
/// isn't needed since OneSignal's own SDK is already a singleton under
/// the hood) -- consistent with the app's existing "no DI container"
/// pattern (see `SessionManager`, `ConnectivityService`).
class NotificationPushService {
  NotificationPushService._();

  static bool _initialized = false;

  /// Optional hook so the currently-open `NotificationListPage` (if
  /// any) can silently refresh itself when a push arrives in the
  /// foreground -- "Refresh list" per the integration doc. Nothing
  /// else in the module depends on this being set.
  static VoidCallback? onForegroundNotificationReceived;

  /// Call once, early in `main()` (fire-and-forget, same treatment as
  /// `ConnectivityService`/`DeepLinkService`) -- initializes the SDK,
  /// requests permission, and wires the click/foreground listeners.
  ///
  /// Safe to call even before OneSignal is actually configured: if
  /// [Env.oneSignalAppId] is still the placeholder, or the SDK throws
  /// for any reason (e.g. platform channel not set up yet), this
  /// no-ops instead of crashing app startup.
  static Future<void> initialize() async {
    if (_initialized) return;
    if (Env.oneSignalAppId.isEmpty ||
        Env.oneSignalAppId == 'YOUR_ONESIGNAL_APP_ID') {
      debugPrint(
        'NotificationPushService: OneSignal App ID not configured -- '
        'skipping push initialization. Set Env.oneSignalAppId to enable.',
      );
      return;
    }

    try {
      OneSignal.Debug.setLogLevel(OSLogLevel.none);
      OneSignal.initialize(Env.oneSignalAppId);
      // We recommend prompting via an In-App Message in production;
      // a direct prompt is used here to match the doc's "Request
      // permission" initialization step with zero extra setup.
      await OneSignal.Notifications.requestPermission(true);

      _registerForegroundListener();
      _registerClickListener();

      _initialized = true;
    } catch (e) {
      debugPrint('NotificationPushService: initialization failed -- $e');
    }
  }

  /// "Set external user id after login" -- called from
  /// `SessionManager.saveSession`/`updateToken` so every login path
  /// (including the forced-relogin path) stays in sync automatically,
  /// without `LoginPage` needing to know push exists at all.
  static Future<void> registerExternalUserId(String userId) async {
    if (!_initialized || userId.isEmpty) return;
    try {
      OneSignal.login(userId);
    } catch (e) {
      debugPrint('NotificationPushService: login failed -- $e');
    }
  }

  /// "Remove association on logout" -- called from
  /// `SessionManager.clearSession`, covering both an explicit user
  /// logout and a forced session-expiry logout with one call, exactly
  /// like `AppNavigator.goToLoginAndClearStack` does for navigation.
  static Future<void> removeExternalUserId() async {
    if (!_initialized) return;
    try {
      OneSignal.logout();
    } catch (e) {
      debugPrint('NotificationPushService: logout failed -- $e');
    }
  }

  // ---------------- listeners ----------------

  /// Foreground: per the integration doc, show the banner (left to
  /// OneSignal's own default display -- `preventDefault()` is
  /// deliberately NOT called here, so the native in-app banner still
  /// shows itself) and let the list screen refresh/update its badge,
  /// but never auto-navigate.
  static void _registerForegroundListener() {
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      try {
        onForegroundNotificationReceived?.call();
      } catch (e) {
        debugPrint('NotificationPushService: foreground handling failed -- $e');
      }
    });
  }

  /// Background/terminated (and, since OneSignal fires this on tap
  /// regardless of app state, foreground too): parse the payload and
  /// hand off to the single navigation engine. Never navigates itself.
  static void _registerClickListener() {
    OneSignal.Notifications.addClickListener((event) {
      try {
        final data = event.notification.additionalData;
        if (data == null) {
          debugPrint('NotificationPushService: click with no additionalData');
          return;
        }
        NotificationNavigator.openFromPushPayload(
          Map<String, dynamic>.from(data),
        );
      } catch (e) {
        // A malformed payload must never crash the app -- log and
        // drop it, per "gracefully handle invalid payloads".
        debugPrint('NotificationPushService: invalid click payload -- $e');
      }
    });
  }
}
