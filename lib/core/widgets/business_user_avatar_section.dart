import 'package:avatar_stack/avatar_stack.dart';
import 'package:avatar_stack/positions.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

class BusinessUserAvatarSection extends StatelessWidget {
  final String title;
  final List<String> avatarUrls;
  final VoidCallback onTapAll;
  final int maxVisible;

  const BusinessUserAvatarSection({
    super.key,
    required this.title,
    required this.avatarUrls,
    required this.onTapAll,
    this.maxVisible = 4,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    final visibleAvatars = avatarUrls.take(maxVisible).toList();
    final surplus = avatarUrls.length - visibleAvatars.length;

    final settings = RestrictedPositions(
      maxCoverage: -0.35,
      minCoverage: -0.6,
      align: StackAlign.left,
    );

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.verticalLarge),
      padding: const EdgeInsets.all(AppSpacing.verticalMedium),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.h3),
          const SizedBox(height: AppSpacing.verticalSmall),
          SizedBox(
            height: 46,
            child: WidgetStack(
              positions: settings,
              stackedWidgets: [
                ...visibleAvatars.map(
                  (url) => GestureDetector(
                    onTap: avatarUrls.length <= maxVisible ? onTapAll : null,
                    child: CircleAvatar(
                      radius: 23,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 21,
                        backgroundImage: NetworkImage(url),
                      ),
                    ),
                  ),
                ),
                if (surplus > 0)
                  GestureDetector(
                    onTap: onTapAll,
                    behavior: HitTestBehavior.opaque,
                    child: CircleAvatar(
                      radius: 23,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        '+$surplus',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],

              /// ✅ REQUIRED PARAM (even if not used)
              buildInfoWidget: (count, BuildContext) {
                return const SizedBox.shrink();
              },
            ),
          ),
          if (avatarUrls.length <= maxVisible)
            GestureDetector(
              onTap: () => {onTapAll},
              child: const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  "View all users",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
