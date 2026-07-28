import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/services/DataModels/subscription_models.dart';
import '../../../core/theme/app_fonts.dart';
import '../subscription_tokens.dart';

/// The top-of-screen "where do I stand" card: org name, current plan
/// tier, and a days-remaining ring built from `ui.remainingDays` /
/// `ui.totalDays` -- both first-class API fields, never computed here
/// from `planExpiresAt - now` (per the contract's explicit instruction
/// that Flutter must not derive this from date math itself).
class CurrentPlanCard extends StatelessWidget {
  final OrganizationSummary organization;
  final int? remainingDays;
  final int? totalDays;

  const CurrentPlanCard({
    super.key,
    required this.organization,
    required this.remainingDays,
    required this.totalDays,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = remainingDays;
    final total = totalDays;
    final hasRing = remaining != null && total != null && total > 0;
    final fraction = hasRing ? (remaining! / total!).clamp(0.0, 1.0) : null;
    final isUrgent = remaining != null && remaining <= 7;
    final ringColor =
        isUrgent ? SubscriptionTokens.danger : SubscriptionTokens.success;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.page),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: SubscriptionTokens.line),
      ),
      child: Row(
        children: [
          if (hasRing) ...[
            _DaysRing(fraction: fraction!, remaining: remaining!, color: ringColor),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  organization.name,
                  style: AppTextStyles.h3.copyWith(color: SubscriptionTokens.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${organization.plan.displayName} Plan',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: SubscriptionTokens.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${organization.userCount} users · ${organization.branchCount} branches',
                  style: AppTextStyles.caption.copyWith(color: SubscriptionTokens.sub),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DaysRing extends StatelessWidget {
  final double fraction;
  final int remaining;
  final Color color;

  const _DaysRing({
    required this.fraction,
    required this.remaining,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      width: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(64, 64),
            painter: _RingPainter(fraction: fraction, color: color),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$remaining',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: SubscriptionTokens.ink,
                  height: 1,
                ),
              ),
              Text(
                'days',
                style: AppTextStyles.caption.copyWith(color: SubscriptionTokens.sub),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double fraction;
  final Color color;

  const _RingPainter({required this.fraction, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 6.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final track = Paint()
      ..color = SubscriptionTokens.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progress = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * fraction,
      false,
      progress,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.fraction != fraction || oldDelegate.color != color;
}
