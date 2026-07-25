import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import 'shimmer_widgets.dart';

/// Loading placeholder for [DashboardStickyHeader], shown while
/// [DashboardHeaderApi.fetchHeader] is in flight. Mirrors
/// [StickyOrgHeader]'s own layout (logo + name/role row, then the
/// switcher pill) and height so the page doesn't jump once real data
/// arrives.
class DashboardHeaderShimmer extends StatelessWidget
    implements PreferredSizeWidget {
  const DashboardHeaderShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.large),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const ShimmerBox(
                    width: 42,
                    height: 42,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        ShimmerLine(width: 140, height: 16),
                        SizedBox(height: 8),
                        ShimmerLine(width: 100, height: 12),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const ShimmerCircle(size: 26),
                  const SizedBox(width: 10),
                  const ShimmerCircle(size: 36),
                ],
              ),
              const SizedBox(height: 14),
              const ShimmerBox(
                width: double.infinity,
                height: 44,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(152);
}
