import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';

/// "Export PDF" / "Export Excel" action row. Purely presentational —
/// [onExportPdf]/[onExportExcel] own the actual export call and
/// launching the resulting file URL; this just renders the two
/// outlined buttons and a small in-progress state per button so a slow
/// export doesn't look like a dead tap.
class PnlExportButtons extends StatelessWidget {
  final bool isExportingPdf;
  final bool isExportingExcel;
  final VoidCallback onExportPdf;
  final VoidCallback onExportExcel;

  const PnlExportButtons({
    super.key,
    required this.isExportingPdf,
    required this.isExportingExcel,
    required this.onExportPdf,
    required this.onExportExcel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ExportButton(
            icon: Icons.picture_as_pdf_outlined,
            label: 'Export PDF',
            isLoading: isExportingPdf,
            onTap: isExportingPdf ? null : onExportPdf,
          ),
        ),
        const SizedBox(width: AppSpacing.horizontalMedium),
        Expanded(
          child: _ExportButton(
            icon: Icons.grid_on_outlined,
            label: 'Export Excel',
            isLoading: isExportingExcel,
            onTap: isExportingExcel ? null : onExportExcel,
          ),
        ),
      ],
    );
  }
}

class _ExportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;

  const _ExportButton({
    required this.icon,
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
