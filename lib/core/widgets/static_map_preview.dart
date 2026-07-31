import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

/// Non-interactive map thumbnail with a single pin, rendered via
/// `flutter_map` against OpenStreetMap tiles.
///
/// Chosen over `google_maps_flutter` because this project's checked-in
/// source doesn't include the `android/`/`ios/` platform folders where
/// a Google Maps API key would need to be registered (AndroidManifest.xml
/// meta-data tag, Info.plist entry) — flutter_map + OpenStreetMap needs
/// no API key and works with only the Dart-level dependency added to
/// `pubspec.yaml`, so it renders correctly the moment this project is
/// dropped into a full Flutter workspace and `flutter pub get` is run.
class StaticMapPreview extends StatelessWidget {
  const StaticMapPreview({
    super.key,
    required this.latitude,
    required this.longitude,
    this.height = 160,
    this.zoom = 15,
    this.interactive = false,
  });

  final double latitude;
  final double longitude;
  final double height;
  final double zoom;

  /// When true, allows pan/zoom gestures (used inside the full-screen
  /// picker); the read-only Branch Details preview keeps this false so
  /// it doesn't fight the page's own scroll gesture.
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(latitude, longitude);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: SizedBox(
        height: height,
        child: IgnorePointer(
          ignoring: !interactive,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: point,
              initialZoom: zoom,
              interactionOptions: InteractionOptions(
                flags: interactive
                    ? InteractiveFlag.all
                    : InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: point,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: AppColors.secondary,
                      size: 36,
                    ),
                  ),
                ],
              ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
