import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

/// Upload / Replace / Remove control for a single image (a branch's
/// logo, in this app so far).
///
/// The picking UX (bottom sheet with Camera/Gallery tiles, remove
/// button when an image is present) is the same one `AddFirmPage`
/// already built for Firm Logo/Photo — generalized here into a shared
/// widget rather than copy-pasted a third time. `AddFirmPage` itself is
/// left untouched (it works today and isn't part of the Branch module
/// scope), but this is the version new code should build on.
class LogoPickerField extends StatelessWidget {
  const LogoPickerField({
    super.key,
    required this.title,
    this.existingUrl,
    this.pickedFile,
    this.removed = false,
    required this.onPicked,
    required this.onRemoved,
    this.allowRemove = true,
  });

  final String title;

  /// URL of an already-uploaded logo (edit mode). Ignored once
  /// [pickedFile] is set or [removed] is true.
  final String? existingUrl;

  /// A newly picked local file, not yet uploaded.
  final File? pickedFile;

  /// True once the user has explicitly removed the logo (distinct from
  /// "never had one") so the tile can show "No logo" instead of falling
  /// back to [existingUrl].
  final bool removed;

  final ValueChanged<File> onPicked;
  final VoidCallback onRemoved;

  /// Edit forms only show Remove when the API actually supports it —
  /// Add New Branch has nothing to remove yet, so this stays false
  /// there.
  final bool allowRemove;

  bool get _hasImage =>
      !removed && (pickedFile != null || (existingUrl?.isNotEmpty ?? false));

  Future<void> _openPicker(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _LogoPickerBottomSheet(
        title: title,
        pickedFile: pickedFile,
        existingUrl: removed ? null : existingUrl,
        allowRemove: allowRemove && _hasImage,
        onRemove: () {
          Navigator.pop(context);
          onRemoved();
        },
      ),
    );

    if (source == null) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
    );
    if (picked != null) onPicked(File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.medium),
      onTap: () => _openPicker(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.small),
              child: SizedBox(
                width: 48,
                height: 48,
                child: pickedFile != null
                    ? Image.file(pickedFile!, fit: BoxFit.cover)
                    : (_hasImage
                        ? Image.network(existingUrl!, fit: BoxFit.cover)
                        : Container(
                            color: AppColors.primary.withOpacity(0.15),
                            child: const Icon(Icons.storefront_outlined,
                                color: AppColors.primary),
                          )),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body),
                  const SizedBox(height: 4),
                  Text(
                    _hasImage ? 'Tap to replace' : 'PNG / JPG up to 2MB',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (_hasImage && allowRemove)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                tooltip: 'Remove logo',
                onPressed: onRemoved,
              )
            else
              const Icon(Icons.upload_file_outlined,
                  color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _LogoPickerBottomSheet extends StatelessWidget {
  final String title;
  final File? pickedFile;
  final String? existingUrl;
  final bool allowRemove;
  final VoidCallback onRemove;

  const _LogoPickerBottomSheet({
    required this.title,
    required this.pickedFile,
    required this.existingUrl,
    required this.allowRemove,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.h3),
            const SizedBox(height: 16),
            if (pickedFile != null || existingUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: pickedFile != null
                    ? Image.file(pickedFile!,
                        height: 120, width: double.infinity, fit: BoxFit.cover)
                    : Image.network(existingUrl!,
                        height: 120, width: double.infinity, fit: BoxFit.cover),
              ),
              if (allowRemove) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('Remove Logo',
                      style: TextStyle(color: Colors.red)),
                ),
              ],
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: _SourceTile(
                    icon: Icons.camera_alt_outlined,
                    label: 'Camera',
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SourceTile(
                    icon: Icons.photo_library_outlined,
                    label: 'Gallery',
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(label, style: AppTextStyles.body),
          ],
        ),
      ),
    );
  }
}
