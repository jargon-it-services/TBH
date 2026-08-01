import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

/// Small "map view" card for a branch's saved location — deliberately
/// not backed by any tile server or map SDK (no `flutter_map`/
/// OpenStreetMap, no Google Maps SDK/API key).
///
/// The backend is the source of truth for where a Google Maps link
/// actually points (coordinate extraction happens server-side, not on
/// the client) — the app just stores and opens the link the user
/// pasted. So this draws a lightweight, self-contained "map-style"
/// card locally — no network request, no key, no tile-server usage
/// policy exposure — with "Open in Google Maps" as the actual live-map
/// experience via [url_launcher] against [mapsUrl].
class StaticMapPreview extends StatelessWidget {
  const StaticMapPreview({
    super.key,
    required this.mapsUrl,
    this.height = 150,
  });

  /// The URL to open — either the branch's saved Google Maps link
  /// as-is, or (for older branches saved before this field existed) a
  /// `google.com/maps/search` URL built from saved lat/long.
  final String mapsUrl;
  final double height;

  Future<void> _open() async {
    final uri = Uri.tryParse(mapsUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _MapGridPainter()),
            Center(
              child: Icon(Icons.location_on,
                  color: AppColors.secondary, size: 40),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  onTap: _open,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.map_outlined,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Open in Google Maps',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Subtle grid pattern so the preview reads as "a map" at a glance,
/// drawn once locally with no network dependency at all.
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = AppColors.primary.withOpacity(0.07);
    canvas.drawRect(Offset.zero & size, bg);

    final line = Paint()
      ..color = AppColors.primary.withOpacity(0.12)
      ..strokeWidth = 1;

    const gap = 24.0;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
