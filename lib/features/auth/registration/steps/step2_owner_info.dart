import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/widgets/jargon_dropdown.dart';
import '../registration_data.dart';
import '../registration_validators.dart';
import '../widgets/registration_step_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';

class Step2OwnerInfo extends StatefulWidget {
  const Step2OwnerInfo({
    super.key,
    required this.data,
    required this.onBack,
    required this.onContinue,
  });

  final RegistrationData data;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  State<Step2OwnerInfo> createState() => _Step2OwnerInfoState();
}

class _Step2OwnerInfoState extends State<Step2OwnerInfo>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _formKey = GlobalKey<FormState>();
  final _shakeTrigger = ValueNotifier<int>(0);
  final ImagePicker _picker = ImagePicker();
  String? _idTypeError;
  String? _documentError;

  @override
  void dispose() {
    _shakeTrigger.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    final source = await showModalBottomSheet<ImageSource?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DocumentPickerBottomSheet(
        imageFile: widget.data.idProofDocument,
        onRemove: () {
          setState(() => widget.data.idProofDocument = null);
          Navigator.pop(context);
        },
      ),
    );

    if (source == null) return;

    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;

    setState(() {
      widget.data.idProofDocument = File(picked.path);
      _documentError = null;
    });
  }

  bool _validateSelections() {
    final typeOk = widget.data.idProofType != 'Select ID Type';
    final docOk = widget.data.idProofDocument != null;
    setState(() {
      _idTypeError = typeOk ? null : 'Please select an ID proof type';
      _documentError = docOk ? null : 'Please upload a copy of the ID document';
    });
    if (!typeOk || !docOk) _shakeTrigger.value++;
    return typeOk && docOk;
  }

  /// Clearer field label per ID type, so the user knows exactly what
  /// number format is expected without needing extra helper-text UI.
  String _idNumberLabel(String idProofType) {
    switch (idProofType) {
      case 'PAN Card':
        return 'PAN Number';
      case 'Aadhaar Card':
        return 'Aadhaar Number';
      default:
        return 'ID Proof Number';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final d = widget.data;
    return RegistrationStepScaffold(
      stepIndex: 1,
      totalSteps: 4,
      title: 'Owner Details',
      subtitle: "This person will be the account's primary contact",
      formKey: _formKey,
      shakeTrigger: _shakeTrigger,
      onBack: widget.onBack,
      onContinue: () async {
        if (_validateSelections()) widget.onContinue();
        return false;
      },
      child: Column(
        children: [
          AppTextField(
            label: 'Full Name',
            icon: Icons.person_outline,
            initialValue: d.ownerName,
            onChanged: (v) => d.ownerName = v,
            validator: (v) => RegistrationValidators.name(v, 'Owner name'),
          ),
          AppTextField(
            label: 'Designation',
            icon: Icons.badge_outlined,
            initialValue: d.designation,
            onChanged: (v) => d.designation = v,
            validator: (v) => RegistrationValidators.required(v, 'Designation'),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.verticalMedium),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: _idTypeError != null
                    ? Border.all(color: AppColors.error, width: 1.2)
                    : null,
              ),
              child: JargonDropdown(
                label: 'ID Proof Type',
                value: d.idProofType,
                icon: Icons.badge_outlined,
                options: RegistrationData.idProofTypes,
                // Matches AppTextField's grey fill instead of the
                // default white card + shadow, so it doesn't stand out
                // against the surrounding text fields.
                backgroundColor: AppColors.primary.withOpacity(0.1),
                borderColor: Colors.transparent,
                boxShadow: const [],
                showIconBackground: false,
                onChanged: (v) => setState(() {
                  d.idProofType = v;
                  _idTypeError = null;
                }),
              ),
            ),
          ),
          if (_idTypeError != null) _errorText(_idTypeError!),
          AppTextField(
            label: _idNumberLabel(d.idProofType),
            icon: Icons.confirmation_number_outlined,
            initialValue: d.idProofNumber,
            keyboardType: d.idProofType == 'Aadhaar Card'
                ? TextInputType.number
                : TextInputType.text,
            onChanged: (v) => d.idProofNumber = v,
            validator: (v) =>
                RegistrationValidators.idProofNumber(v, d.idProofType),
          ),
          _uploadTile(
            file: d.idProofDocument,
            title: 'ID Document',
            subtitle: d.idProofDocument == null
                ? 'Upload a clear photo or scan'
                : 'Selected — tap to change',
            hasError: _documentError != null,
            onTap: _pickDocument,
          ),
          if (_documentError != null) _errorText(_documentError!),
        ],
      ),
    );
  }

  Widget _errorText(String text) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.verticalSmall),
        child: Row(
          children: [
            const Icon(Icons.error_outline, size: 13, color: AppColors.error),
            const SizedBox(width: 4),
            Text(
              text,
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
            ),
          ],
        ),
      );

  Widget _uploadTile({
    required File? file,
    required String title,
    required String subtitle,
    required bool hasError,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.medium),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: AppSpacing.verticalSmall),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border:
              hasError ? Border.all(color: AppColors.error, width: 1.2) : null,
        ),
        child: Row(
          children: [
            // Thumbnail preview once a document is picked, instead of
            // just the static upload icon.
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: file != null
                  ? Image.file(
                      file,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 44,
                      height: 44,
                      color: AppColors.primary.withOpacity(0.12),
                      child: const Icon(Icons.upload_file_outlined,
                          color: AppColors.primary, size: 22),
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
                    subtitle,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (file != null)
              const Icon(Icons.check_circle, color: AppColors.success, size: 20)
            else
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _DocumentPickerBottomSheet extends StatelessWidget {
  final File? imageFile;
  final VoidCallback onRemove;

  const _DocumentPickerBottomSheet({
    required this.imageFile,
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
            Text('ID Document', style: AppTextStyles.h3),
            const SizedBox(height: 16),
            if (imageFile != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  imageFile!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label:
                    const Text('Remove', style: TextStyle(color: Colors.red)),
              ),
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
