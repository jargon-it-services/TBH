/// Data models for the Notification Module.
///
/// Mirrors the exact conventions already used by
/// `payment_history_model.dart` / `transaction_list_model.dart`: every
/// `fromJson` falls back to a safe default instead of throwing, so a
/// null/missing/unexpected field from the backend degrades gracefully
/// in the UI rather than crashing the app -- this matters even more
/// here than elsewhere, since the whole point of this module is that
/// the backend can introduce new `destination.type` / `display_mode`
/// values at any time without an app update (see
/// `NotificationDestinationResolver`).
library notification_model;

/// How a tapped notification should be presented, per
/// `02_API_Contracts.md` / `03_Notification_Payloads.md`.
///
/// [unknown] is not a value the backend ever sends -- it's what an
/// unrecognized/missing string decodes to, so callers (see
/// `NotificationNavigator`) have an explicit, nameable case to handle
/// instead of silently misreading a typo'd/future value as `direct`.
enum NotificationDisplayMode {
  direct,
  notificationDetail,
  none,
  unknown;

  static NotificationDisplayMode fromApiValue(String? value) {
    switch (value) {
      case 'direct':
        return NotificationDisplayMode.direct;
      case 'notification_detail':
        return NotificationDisplayMode.notificationDetail;
      case 'none':
        return NotificationDisplayMode.none;
      default:
        return NotificationDisplayMode.unknown;
    }
  }
}

/// `destination.type` -- the ONLY string this whole module ever
/// switches on for navigation purposes, and only inside
/// `NotificationDestinationResolver`. Kept as a raw String (not an
/// enum) deliberately: an enum would need an app release every time
/// the backend adds a new destination type, which directly
/// contradicts the "Future Extensibility" requirement that new types
/// must work by touching only the resolver's mapping table.
typedef DestinationType = String;

/// `destination` object -- where a notification (or one of its
/// actions) points to. Never contains any Flutter/navigation
/// awareness itself; it's inert data until `NotificationDestinationResolver`
/// interprets it.
class NotificationDestination {
  final DestinationType type;
  final String? referenceId;
  final String? url;

  const NotificationDestination({
    required this.type,
    this.referenceId,
    this.url,
  });

  factory NotificationDestination.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const NotificationDestination(type: 'none');
    }
    return NotificationDestination(
      type: (json['type'] as String?)?.trim().isNotEmpty == true
          ? json['type'] as String
          : 'none',
      referenceId: json['reference_id']?.toString(),
      url: json['url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        if (referenceId != null) 'reference_id': referenceId,
        if (url != null) 'url': url,
      };
}

/// One dynamic, backend-defined button rendered on the Notification
/// Detail screen (`actions[]`). The screen never hardcodes what a
/// button says or does -- both come straight from here.
class NotificationAction {
  final String title;
  final NotificationDestination destination;

  const NotificationAction({
    required this.title,
    required this.destination,
  });

  factory NotificationAction.fromJson(Map<String, dynamic> json) {
    return NotificationAction(
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? json['title'] as String
          : 'View',
      destination: NotificationDestination.fromJson(
        json['destination'] as Map<String, dynamic>?,
      ),
    );
  }
}

/// A single notification, as returned inside `GET /notifications` /
/// pushed via OneSignal / read from Notification History.
class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String? icon;
  final String? image;
  final String priority;
  final String? category;
  final bool isRead;
  final DateTime? createdAt;
  final NotificationDisplayMode displayMode;
  final NotificationDestination destination;
  final List<NotificationAction> actions;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.icon,
    this.image,
    this.priority = 'normal',
    this.category,
    this.isRead = false,
    this.createdAt,
    required this.displayMode,
    required this.destination,
    this.actions = const [],
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] as String?) ?? '',
      message: (json['message'] as String?) ?? '',
      icon: json['icon'] as String?,
      image: json['image'] as String?,
      priority: (json['priority'] as String?) ?? 'normal',
      category: json['category'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.tryParse((json['created_at'] as String?) ?? ''),
      displayMode:
          NotificationDisplayMode.fromApiValue(json['display_mode'] as String?),
      destination: NotificationDestination.fromJson(
        json['destination'] as Map<String, dynamic>?,
      ),
      actions: (json['actions'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => NotificationAction.fromJson(e))
          .toList(),
    );
  }

  /// A copy with [isRead] flipped to true -- used for the optimistic
  /// local update `NotificationListPage`/`NotificationNavigator` apply
  /// the moment a notification is tapped/swiped, without waiting on
  /// the mark-read API round trip.
  NotificationModel markedRead() => NotificationModel(
        id: id,
        title: title,
        message: message,
        icon: icon,
        image: image,
        priority: priority,
        category: category,
        isRead: true,
        createdAt: createdAt,
        displayMode: displayMode,
        destination: destination,
        actions: actions,
      );
}

/// `GET /notifications` response envelope, matching
/// `02_API_Contracts.md` exactly (`data.unread_count`,
/// `data.total_count`, `data.notifications`).
class NotificationListResponse {
  final int unreadCount;
  final int totalCount;
  final List<NotificationModel> notifications;

  const NotificationListResponse({
    required this.unreadCount,
    required this.totalCount,
    required this.notifications,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final notifications = (data['notifications'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((e) => NotificationModel.fromJson(e))
        .toList();

    return NotificationListResponse(
      unreadCount: (data['unread_count'] as num?)?.toInt() ??
          notifications.where((n) => !n.isRead).length,
      totalCount:
          (data['total_count'] as num?)?.toInt() ?? notifications.length,
      notifications: notifications,
    );
  }
}
