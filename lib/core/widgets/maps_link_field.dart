import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import 'app_snackbar.dart';
import 'app_text_field.dart';

/// Branch location field: paste a Google Maps share link and it's
/// saved as-is — no fetching, no client-side redirect-following, no
/// coordinate extraction. The backend extracts latitude/longitude from
/// the saved link on its own; the app's only job here is to capture
/// the link and, on Branch Details, open it.
///
/// This replaces an earlier version that tried to resolve the link to
/// a lat/long pair on-device (following redirects, regex-scanning the
/// page). That depended on scraping behavior of Google's redirect
/// pages that turned out unreliable in practice, so the extraction
/// step moved server-side — simpler and much more robust.
class MapsLinkField extends StatefulWidget {
  const MapsLinkField({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  State<MapsLinkField> createState() => _MapsLinkFieldState();
}

class _MapsLinkFieldState extends State<MapsLinkField> {
  late String _link = widget.initialValue;

  Future<void> _openLink() async {
    FocusScope.of(context).unfocus();
    final uri = Uri.tryParse(_link.trim());
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      AppSnackbar.warning(context, 'Enter a valid Google Maps link first');
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      AppSnackbar.error(context, "Couldn't open that link");
    }
  }

  String? _validator(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null; // optional field
    final uri = Uri.tryParse(v);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      return 'Enter a valid link (starting with http:// or https://)';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: 'Google Maps Link (optional)',
          icon: Icons.link,
          keyboardType: TextInputType.url,
          initialValue: _link,
          onChanged: (v) {
            _link = v;
            widget.onChanged(v);
          },
          validator: _validator,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.verticalMedium),
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Open the branch location in Google Maps, tap Share, copy the link, and paste it here.',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
        if (_link.trim().isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _openLink,
              icon: const Icon(Icons.map_outlined, size: 18),
              label: const Text('Open in Google Maps'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.verticalSmall),
      ],
    );
  }
}
