import 'package:flutter/material.dart';

import '../../../core/services/DataModels/notification_model.dart';
import '../../../core/services/dashboard_icon_mapper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';

/// One row in the Notification List -- purely presentational. Reading
/// [notification.displayMode]/`destination`/`actions` and deciding
/// what happens on tap is the caller's job (`NotificationListPage`
/// handing off to `NotificationNavigator`); this widget only renders.
class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  Color get _priorityColor => switch (notification.priority.toLowerCase()) {
        'high' => AppColors.error,
        'low' => AppColors.textDisabled,
        _ => AppColors.secondary,
      };

  @override
  Widget build(BuildContext context) {
    final bool unread = !notification.isRead;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.large),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: unread
                ? AppColors.primary.withOpacity(0.05)
                : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(
              color: unread
                  ? AppColors.primary.withOpacity(0.25)
                  : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _leadingIcon(),
                const SizedBox(width: AppSpacing.horizontalMedium),
                Expanded(child: _content(unread)),
                if (notification.priority.toLowerCase() == 'high') ...[
                  const SizedBox(width: 6),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _priorityColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _leadingIcon() {
    if (notification.image != null && notification.image!.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Image.network(
          notification.image!,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _iconAvatar(),
        ),
      );
    }
    return _iconAvatar();
  }

  Widget _iconAvatar() {
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.primary.withOpacity(0.12),
      child: Icon(
        DashboardIconMapper.iconFromKey(
          notification.icon,
          fallback: Icons.notifications_none_rounded,
        ),
        color: AppColors.primary,
      ),
    );
  }

  Widget _content(bool unread) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (unread) ...[
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 6),
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
            Expanded(
              child: Text(
                notification.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(
                  fontWeight: unread ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          notification.message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 6),
        Text(
          relativeTimeLabel(notification.createdAt),
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}

/// "Just now" / "12m ago" / "3h ago" / "2d ago" / date -- kept as a
/// standalone top-level function (rather than pulling in a new
/// dependency like `timeago`) so the module adds no new package for
/// something this small; `intl` (already a dependency) formats the
/// eventual fallback date.
String relativeTimeLabel(DateTime? dateTime) {
  if (dateTime == null) return "";
  final local = dateTime.toLocal();
  final diff = DateTime.now().difference(local);

  if (diff.inSeconds < 60) return "Just now";
  if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
  if (diff.inHours < 24) return "${diff.inHours}h ago";
  if (diff.inDays < 7) return "${diff.inDays}d ago";

  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return "${local.day} ${months[local.month - 1]} ${local.year}";
}
