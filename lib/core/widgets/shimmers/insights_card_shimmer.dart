import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';

class InsightsCardShimmer extends StatelessWidget {
  final bool showTrophy;

  const InsightsCardShimmer({
    super.key,
    this.showTrophy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.page),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          /// 🏆 Background Trophy (optional)
          if (showTrophy)
            Positioned.fill(
              child: Center(
                child: Icon(
                  Icons.emoji_events_rounded,
                  size: 110,
                  color: AppColors.secondary.withOpacity(0.05),
                ),
              ),
            ),

          /// 🔄 Shimmer Content
          Shimmer.fromColors(
            baseColor: AppColors.border,
            highlightColor: AppColors.border.withOpacity(0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _line(width: 140, height: 16),
                          const SizedBox(height: 6),
                          _line(width: 90, height: 10),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _circle(size: 18),
                        const SizedBox(width: 6),
                        _line(width: 32, height: 14),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.verticalMedium),

                /// Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _statBlock(),
                    _statBlock(),
                  ],
                ),

                const SizedBox(height: AppSpacing.verticalSmall),

                /// View Details
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _line(width: 70, height: 14),
                      const SizedBox(width: 6),
                      _circle(size: 25),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ---------- Helpers ----------

  Widget _line({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  Widget _circle({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.border,
      ),
    );
  }

  Widget _statBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _line(width: 60, height: 10),
        const SizedBox(height: 6),
        _line(width: 80, height: 14),
      ],
    );
  }
}
