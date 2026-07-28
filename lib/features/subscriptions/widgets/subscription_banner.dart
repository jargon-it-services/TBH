import 'package:flutter/material.dart';

import '../../../core/services/DataModels/subscription_models.dart';
import '../../../core/theme/app_fonts.dart';
import '../subscription_tokens.dart';

/// Renders [SubscriptionBannerData] -- shown whenever
/// `ui.showBanner == true`. Colors/icon are derived from `banner.type`
/// (`"info" | "warning" | "danger"`), matching the same three-way
/// severity convention already used for dashboard alerts, just with
/// this screen's own approved token values.
class SubscriptionBanner extends StatelessWidget {
  final SubscriptionBannerData banner;

  const SubscriptionBanner({super.key, required this.banner});

  ({Color fg, Color bg, IconData icon}) _styleFor(String type) {
    switch (type) {
      case 'danger':
        return (
          fg: SubscriptionTokens.danger,
          bg: SubscriptionTokens.dangerBg,
          icon: Icons.error_outline,
        );
      case 'warning':
        return (
          fg: const Color(0xFFB27B00),
          bg: SubscriptionTokens.warnBg,
          icon: Icons.warning_amber_rounded,
        );
      case 'info':
      default:
        return (
          fg: SubscriptionTokens.primary,
          bg: SubscriptionTokens.infoBg,
          icon: Icons.info_outline,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(banner.type);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.page),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: style.fg.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(style.icon, color: style.fg, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  banner.title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: style.fg,
                  ),
                ),
                if (banner.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    banner.description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: SubscriptionTokens.sub,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
