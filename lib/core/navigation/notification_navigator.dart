import 'package:flutter/material.dart';

import '../../features/notifications/notification_detail_page.dart';
import '../network/apis/notification_api.dart';
import '../services/DataModels/notification_model.dart';
import 'app_navigator.dart';
import 'notification_destination_resolver.dart';

/// The ONE navigation engine every notification entry point goes
/// through: Notification History (list tap), OneSignal push
/// (foreground/background/terminated), and future Local
/// Notifications / Deep Links.
///
/// Owns exactly the flow described in every module doc:
///   mark read -> check display_mode -> direct: resolve destination
///   directly, OR notification_detail (and any unrecognized mode, as a
///   safe fallback): open the generic Notification Detail screen.
///
/// Also owns duplicate-tap / duplicate-open prevention, since the same
/// notification can otherwise be "opened" twice in quick succession
/// (e.g. a double-tap on a list row, or OneSignal's foreground +
/// click handlers both firing for the same push) -- see
/// `04_OneSignal_Integration.md`'s "Track last notification id,
/// Debounce taps, Lock navigator".
class NotificationNavigator {
  NotificationNavigator._();

  static final NotificationApi _api = NotificationApi();

  // ---- lock / duplicate-tap guards ----
  static bool _isNavigating = false;
  static int? _lastHandledId;
  static DateTime? _lastHandledAt;
  static const Duration _duplicateWindow = Duration(seconds: 2);

  /// Entry point for anywhere that already holds a full
  /// [NotificationModel] -- primarily `NotificationListPage`, but also
  /// used once a push/deep-link payload has been resolved to a full
  /// model by [openFromPushPayload] below.
  ///
  /// [onMarkedRead] lets the caller (the list screen) apply its own
  /// optimistic UI update (dot removed, bold title cleared, unread
  /// count decremented) the instant a tap is registered, without
  /// waiting on the mark-read API call.
  static Future<void> open(
    BuildContext context,
    NotificationModel notification, {
    VoidCallback? onMarkedRead,
  }) async {
    if (_isLockedOrDuplicate(notification.id)) return;
    _lock(notification.id);

    try {
      _markReadBestEffort(notification, onMarkedRead);
      await _route(context, notification);
    } finally {
      _isNavigating = false;
    }
  }

  /// Entry point for OneSignal / future deep links, which only ever
  /// hand over the slim payload shape from `04_OneSignal_Integration.md`
  /// (`notification_id`, `display_mode`, `destination`) -- never the
  /// full title/message/actions. Null-safe throughout: a malformed or
  /// unexpected payload never throws, it just silently no-ops (there is
  /// no screen to show a user-facing error on, since this typically
  /// runs before any UI is guaranteed to be ready -- e.g. cold start).
  static Future<void> openFromPushPayload(Map<String, dynamic> payload) async {
    final context = AppNavigator.key.currentContext;
    if (context == null) return;

    final id = (payload['notification_id'] as num?)?.toInt();
    if (id == null) return;

    if (_isLockedOrDuplicate(id)) return;
    _lock(id);

    try {
      final displayMode = NotificationDisplayMode.fromApiValue(
        payload['display_mode'] as String?,
      );
      final destination = NotificationDestination.fromJson(
        payload['destination'] as Map<String, dynamic>?,
      );

      // Fire-and-forget mark-read by id -- the list screen (if open)
      // will pick up the true unread count on its next
      // fetch/pull-to-refresh; nothing here depends on the result.
      _api.markRead(id);

      if (displayMode == NotificationDisplayMode.direct) {
        await NotificationDestinationResolver.resolve(context, destination);
        return;
      }

      // notification_detail (or an unrecognized mode) -- the slim push
      // payload has no title/message/actions, so fetch the full
      // notification before showing the generic detail screen.
      final response = await _api.fetchNotificationById(id);
      final full = response.isSuccess && response.data != null
          ? response.data!.markedRead()
          : NotificationModel(
              id: id,
              title: "Notification",
              message: "",
              displayMode: displayMode,
              destination: destination,
              isRead: true,
            );

      if (!context.mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NotificationDetailPage(notification: full),
        ),
      );
    } finally {
      _isNavigating = false;
    }
  }

  // ---------------- internal ----------------

  static Future<void> _route(
    BuildContext context,
    NotificationModel notification,
  ) async {
    switch (notification.displayMode) {
      case NotificationDisplayMode.direct:
        await NotificationDestinationResolver.resolve(
          context,
          notification.destination,
        );
        return;

      case NotificationDisplayMode.notificationDetail:
      case NotificationDisplayMode.none:
      case NotificationDisplayMode.unknown:
        // `none`/`unknown` fall back to the generic detail screen
        // rather than doing nothing -- the user always sees
        // *something* for a notification they tapped, per "gracefully
        // handle unknown display modes".
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NotificationDetailPage(
              notification: notification.markedRead(),
            ),
          ),
        );
        return;
    }
  }

  static void _markReadBestEffort(
    NotificationModel notification,
    VoidCallback? onMarkedRead,
  ) {
    if (notification.isRead) return;
    // Optimistic local update first -- the UI must not wait on the
    // network for something this small.
    onMarkedRead?.call();
    // Best-effort; a failure here is intentionally swallowed (never
    // surfaced/never crashes) per "gracefully handle failed
    // mark-as-read API". A future pull-to-refresh reconciles state
    // with the backend regardless.
    _api.markRead(notification.id);
  }

  static bool _isLockedOrDuplicate(int id) {
    if (_isNavigating) return true;
    if (_lastHandledId == id && _lastHandledAt != null) {
      if (DateTime.now().difference(_lastHandledAt!) < _duplicateWindow) {
        return true;
      }
    }
    return false;
  }

  static void _lock(int id) {
    _isNavigating = true;
    _lastHandledId = id;
    _lastHandledAt = DateTime.now();
  }
}
