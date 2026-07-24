import 'dart:async';

import 'package:flutter/material.dart';

import '../connectivity/connectivity_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

/// Wraps [child] and overlays a slim top banner whenever connectivity
/// changes: "You're offline" (stays up the whole time offline), then a
/// brief "You're back online" toast when connectivity is restored
/// (auto-hides after 2s).
///
/// Lives once at the app root (see main.dart) instead of being added to
/// individual screens — which is also exactly what guarantees there's
/// never more than one of these on screen at a time, regardless of how
/// many screens/requests are affected by the same connectivity change.
class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({super.key, required this.child});

  final Widget child;

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  StreamSubscription<bool>? _subscription;
  bool _isOnline = true;
  bool _showBackOnlineToast = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _isOnline = ConnectivityService.instance.isOnline;
    _subscription =
        ConnectivityService.instance.onStatusChange.listen(_onStatusChange);
  }

  void _onStatusChange(bool isOnline) {
    if (!mounted) return;
    setState(() {
      _isOnline = isOnline;
      _showBackOnlineToast = isOnline; // only true right as it flips back
    });

    if (isOnline) {
      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showBackOnlineToast = false);
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showOfflineBar = !_isOnline;
    final showOnlineToast = _isOnline && _showBackOnlineToast;

    return Stack(
      children: [
        widget.child,
        if (showOfflineBar || showOnlineToast)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: showOfflineBar
                    ? const _Banner(
                        key: ValueKey('offline'),
                        color: AppColors.error,
                        icon: Icons.wifi_off,
                        label: "You're offline",
                      )
                    : const _Banner(
                        key: ValueKey('online'),
                        color: AppColors.success,
                        icon: Icons.wifi,
                        label: "You're back online",
                      ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    super.key,
    required this.color,
    required this.icon,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      // Transparent Material ancestor: this banner renders inside
      // MaterialApp's `builder`, above the Navigator's own per-route
      // Scaffold/Material. Without a Material ancestor here, Flutter
      // falls back to its default debug TextStyle for any style
      // property the Text doesn't explicitly set -- which includes an
      // underline decoration, rendered in yellow. That's the exact
      // "yellow underline" bug; a transparent Material fixes it at the
      // root without changing this banner's own colors/layout at all.
      type: MaterialType.transparency,
      child: Container(
        width: double.infinity,
        color: color,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                // Explicit, defensive second guard against the same
                // fallback-style issue -- harmless no-op once the
                // Material ancestor above is in place.
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
