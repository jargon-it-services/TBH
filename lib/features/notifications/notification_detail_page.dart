import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/navigation/notification_destination_resolver.dart';
import '../../core/services/DataModels/notification_model.dart';
import '../../core/services/dashboard_icon_mapper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/card_wrapper.dart';
import '../../core/widgets/info_card.dart';

/// The single, generic Notification Detail screen.
///
/// Per the module's core design principle, this widget has NO idea
/// what a "payment" or "subscription" notification is -- every visual
/// element (icon, title, message, optional image, info rows, and the
/// action buttons at the bottom) is derived purely from the
/// [NotificationModel] it's given. Tapping any action button just
/// hands its `destination` to [NotificationDestinationResolver]; this
/// screen never inspects `destination.type` itself.
///
/// Always receives a fully-populated [notification] -- the caller
/// (`NotificationNavigator`) is responsible for fetching full detail
/// first (e.g. via `NotificationApi.fetchNotificationById`) when only
/// a slim push payload is available, so this screen stays a pure
/// presentation layer with no fetch-by-id logic of its own.
class NotificationDetailPage extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailPage({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: Text(
          "Notification",
          style: AppTextStyles.h2.copyWith(color: Colors.white),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(AppRadius.large),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            _headerCard(context),
            if (notification.image != null &&
                notification.image!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.verticalMedium),
              _imageCard(),
            ],
            if (_hasInfoSection) ...[
              const SizedBox(height: AppSpacing.verticalMedium),
              _infoSection(),
            ],
            if (notification.actions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.verticalLarge),
              ..._actionButtons(context),
            ],
            const SizedBox(height: AppSpacing.verticalLarge),
          ],
        ),
      ),
    );
  }

  // ---------------- header: icon + title + message + date ----------------
  Widget _headerCard(BuildContext context) {
    return CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.10),
              ),
              child: Icon(
                DashboardIconMapper.iconFromKey(
                  notification.icon,
                  fallback: Icons.notifications_none_rounded,
                ),
                color: AppColors.primary,
                size: 34,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.verticalMedium),
          Text(
            notification.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.h2,
          ),
          const SizedBox(height: 8),
          Text(
            notification.message,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.verticalMedium),
          Center(
            child: Text(
              _formattedDateTime(notification.createdAt),
              style: AppTextStyles.caption,
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageCard() {
    return CardWrapper(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            notification.image!,
            fit: BoxFit.cover,
            // Never let a broken/expired image URL crash or blank out
            // the whole detail screen -- degrade to a neutral
            // placeholder instead (per "gracefully handle" invalid
            // content).
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.divider,
              alignment: Alignment.center,
              child: const Icon(
                Icons.image_not_supported_outlined,
                color: AppColors.textSecondary,
              ),
            ),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                color: AppColors.divider,
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  bool get _hasInfoSection =>
      (notification.category != null &&
          notification.category!.trim().isNotEmpty) ||
      notification.priority.trim().isNotEmpty ||
      (notification.destination.referenceId != null &&
          notification.destination.referenceId!.trim().isNotEmpty);

  // ---------------- dynamic information section ----------------
  // Purely descriptive metadata -- never branches on destination.type,
  // just displays whatever fields the backend included.
  Widget _infoSection() {
    final rows = <InfoRowData>[
      if (notification.category != null &&
          notification.category!.trim().isNotEmpty)
        InfoRowData(
          icon: Icons.category_outlined,
          label: "Category",
          value: _titleCase(notification.category!),
        ),
      InfoRowData(
        icon: Icons.flag_outlined,
        label: "Priority",
        value: _titleCase(notification.priority),
      ),
      if (notification.destination.referenceId != null &&
          notification.destination.referenceId!.trim().isNotEmpty)
        InfoRowData(
          icon: Icons.confirmation_number_outlined,
          label: "Reference",
          value: notification.destination.referenceId!,
        ),
    ];

    return InfoCard(
      title: "Details",
      titleIcon: Icons.info_outline,
      rows: rows,
    );
  }

  // ---------------- dynamic action buttons ----------------
  // Zero, one, or many -- entirely driven by notification.actions.
  // Every button does the exact same thing on tap: hand its own
  // destination to the resolver. No button here is ever special-cased.
  List<Widget> _actionButtons(BuildContext context) {
    final widgets = <Widget>[];
    for (var i = 0; i < notification.actions.length; i++) {
      final action = notification.actions[i];
      final isPrimary = i == 0;
      widgets.add(
        SizedBox(
          width: double.infinity,
          child: isPrimary
              ? ElevatedButton(
                  style: AppButtonStyles.primary,
                  onPressed: () =>
                      NotificationDestinationResolver.resolve(
                    context,
                    action.destination,
                  ),
                  child: Text(action.title),
                )
              : OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                    ),
                  ),
                  onPressed: () =>
                      NotificationDestinationResolver.resolve(
                    context,
                    action.destination,
                  ),
                  child: Text(action.title),
                ),
        ),
      );
      if (i != notification.actions.length - 1) {
        widgets.add(const SizedBox(height: AppSpacing.verticalSmall));
      }
    }
    return widgets;
  }

  String _formattedDateTime(DateTime? dateTime) {
    if (dateTime == null) return "";
    return DateFormat("dd MMM yyyy, hh:mm a").format(dateTime.toLocal());
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
