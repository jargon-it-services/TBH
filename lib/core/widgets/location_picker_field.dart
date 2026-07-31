import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import 'app_snackbar.dart';
import 'location_picker_page.dart';
import 'static_map_preview.dart';

/// Branch location field: current-location button, "pick on map"
/// button, and a small preview once a point is set. Both entry points
/// converge on the same `onChanged(lat, lng)` callback so the caller
/// (Add/Edit Branch) doesn't need to care which one the user used.
class LocationPickerField extends StatefulWidget {
  const LocationPickerField({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    required this.onChanged,
  });

  final double? initialLatitude;
  final double? initialLongitude;
  final void Function(double latitude, double longitude) onChanged;

  @override
  State<LocationPickerField> createState() => _LocationPickerFieldState();
}

class _LocationPickerFieldState extends State<LocationPickerField> {
  double? _lat;
  double? _lng;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _lat = widget.initialLatitude;
    _lng = widget.initialLongitude;
  }

  Future<void> _useCurrentLocation() async {
    if (_locating) return;
    setState(() => _locating = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          AppSnackbar.warning(
            context,
            'Turn on device location to use this option.',
          );
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            AppSnackbar.warning(
              context,
              'Location permission is required to use this option.',
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          AppSnackbar.error(
            context,
            'Location permission is permanently denied. Enable it from app settings.',
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
      });
      widget.onChanged(position.latitude, position.longitude);
    } catch (_) {
      if (mounted) {
        AppSnackbar.error(
          context,
          "Couldn't fetch your current location. Please try again.",
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pickOnMap() async {
    final initial =
        (_lat != null && _lng != null) ? LatLng(_lat!, _lng!) : null;
    final picked = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (_) => LocationPickerPage(initial: initial)),
    );
    if (picked == null) return;
    setState(() {
      _lat = picked.latitude;
      _lng = picked.longitude;
    });
    widget.onChanged(picked.latitude, picked.longitude);
  }

  @override
  Widget build(BuildContext context) {
    final hasPoint = _lat != null && _lng != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _locating ? null : _useCurrentLocation,
                icon: _locating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_outlined),
                label: Text(_locating ? 'Locating…' : 'Use Current Location'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickOnMap,
                icon: const Icon(Icons.map_outlined),
                label: const Text('Pick on Map'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  side: const BorderSide(color: AppColors.secondary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.verticalMedium),
        if (hasPoint) ...[
          StaticMapPreview(latitude: _lat!, longitude: _lng!, height: 150),
          const SizedBox(height: AppSpacing.verticalSmall),
          Text(
            '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
        ] else
          Container(
            padding: const EdgeInsets.all(AppSpacing.page),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No location set yet. Use current location or pick on the map.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
