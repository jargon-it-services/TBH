import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

/// Full-screen "pick a point on the map" page. Pops with a [LatLng]
/// when the user taps Confirm, or `null` if they back out.
class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key, this.initial});

  /// Starting point — the branch's existing coordinates when editing,
  /// or null to start centered on India.
  final LatLng? initial;

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  // Roughly the geographic center of India — a sensible default when
  // there's no existing/current location to center on yet.
  static const _defaultCenter = LatLng(22.9734, 78.6569);

  late LatLng _picked = widget.initial ?? _defaultCenter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: Text(
          'Pick Branch Location',
          style: AppTextStyles.h2.copyWith(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _picked,
              initialZoom: widget.initial != null ? 15 : 5,
              onTap: (tapPosition, point) {
                setState(() => _picked = point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _picked,
                    width: 44,
                    height: 44,
                    child: const Icon(
                      Icons.location_on,
                      color: AppColors.secondary,
                      size: 40,
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
          Positioned(
            left: AppSpacing.page,
            right: AppSpacing.page,
            top: AppSpacing.verticalMedium,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8),
                ],
              ),
              child: Text(
                'Tap anywhere on the map to place the pin',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall,
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.page,
            right: AppSpacing.page,
            bottom: AppSpacing.verticalLarge,
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                ),
                onPressed: () => Navigator.pop(context, _picked),
                child: Text(
                  'Confirm Location (${_picked.latitude.toStringAsFixed(5)}, ${_picked.longitude.toStringAsFixed(5)})',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
