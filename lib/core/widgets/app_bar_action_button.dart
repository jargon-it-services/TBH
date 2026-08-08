import 'package:flutter/material.dart';

/// A circular, frosted-glass AppBar action button — the same look and
/// feel as the info icon on the Profile header (`_InfoButton` in
/// `account_page.dart`): a 40x40 translucent white circle with a
/// subtle white border, holding a white 20px icon.
///
/// Use this for every AppBar `actions` entry across the app (Edit,
/// Select, Notifications, etc.) instead of a bare `IconButton`, so
/// header actions look consistent everywhere rather than each screen
/// rolling its own style.
class AppBarActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  /// Icon color. Defaults to white, matching the primary-colored
  /// AppBar background every screen uses.
  final Color iconColor;

  /// Optional small count badge (e.g. unread notifications) shown at
  /// the top-right of the circle. Null or <= 0 hides it entirely.
  final int? badgeCount;

  /// Badge fill color — defaults to the same accent used everywhere
  /// else a "new/unread" badge shows up.
  final Color badgeColor;

  const AppBarActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.iconColor = Colors.white,
    this.badgeCount,
    this.badgeColor = const Color(0xFFE76425),
  });

  @override
  Widget build(BuildContext context) {
    final button = Padding(
      // Asymmetric on purpose: AppBar's leading back button sits ~16dp
      // in from the screen's left edge (56dp leading slot, 24dp icon,
      // centered). This widget is a tighter 40x40 circle, so a small
      // 4dp left gap plus a fuller 12dp right gap gives the trailing
      // action that same breathing room on the right edge instead of
      // its border getting flush-cut against the screen edge.
      padding: const EdgeInsets.only(left: 4, right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onPressed,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(icon, color: iconColor, size: 20),
                if (badgeCount != null && badgeCount! > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      constraints: const BoxConstraints(minWidth: 16),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Text(
                        badgeCount! > 99 ? '99+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (tooltip == null || tooltip!.isEmpty) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}
