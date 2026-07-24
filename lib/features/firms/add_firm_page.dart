import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/apis/firms_api.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/jargon_dropdown.dart';

class AddFirmPage extends StatefulWidget {
  const AddFirmPage({super.key});

  @override
  State<AddFirmPage> createState() => _AddFirmPageState();
}

class _AddFirmPageState extends State<AddFirmPage> {
  final _firmNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _regNoCtrl = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  File? _firmLogo;
  File? _firmPhoto;

  String _companyType = "Select Company Type";
  bool _isSaving = false;

  final List<String> _companyTypes = [
    "Proprietorship",
    "Partnership",
    "LLP",
    "Private Limited",
    "Public Limited",
  ];

  @override
  void dispose() {
    _firmNameCtrl.dispose();
    _addressCtrl.dispose();
    _gstinCtrl.dispose();
    _contactCtrl.dispose();
    _emailCtrl.dispose();
    _ownerCtrl.dispose();
    _regNoCtrl.dispose();
    super.dispose();
  }

  /// ================= IMAGE PICK =================
  Future<void> _pickImage(bool isLogo) async {
    final source = await showModalBottomSheet<ImageSource?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImagePickerBottomSheet(
        title: isLogo ? "Firm Logo" : "Firm Photo",
        imageFile: isLogo ? _firmLogo : _firmPhoto,
        onRemove: () {
          setState(() {
            if (isLogo) {
              _firmLogo = null;
            } else {
              _firmPhoto = null;
            }
          });
          Navigator.pop(context);
        },
      ),
    );

    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (picked == null) return;

    setState(() {
      if (isLogo) {
        _firmLogo = File(picked.path);
      } else {
        _firmPhoto = File(picked.path);
      }
    });
  }

  /// ================= VALIDATION =================
  bool _isValid() {
    return _firmNameCtrl.text.isNotEmpty &&
        _addressCtrl.text.isNotEmpty &&
        _gstinCtrl.text.isNotEmpty &&
        _regNoCtrl.text.isNotEmpty &&
        _ownerCtrl.text.isNotEmpty &&
        _contactCtrl.text.isNotEmpty &&
        _emailCtrl.text.isNotEmpty &&
        _companyType != "Select Company Type" &&
        _firmLogo != null &&
        _firmPhoto != null;
  }

  /// ================= SAVE =================
  Future<void> _saveFirm() async {
    if (!_isValid()) {
      AppSnackbar.warning(context, "All fields and documents are mandatory");
      return;
    }

    setState(() => _isSaving = true);

    final response = await FirmsApi().createFirm(
      firmName: _firmNameCtrl.text,
      address: _addressCtrl.text,
      gstin: _gstinCtrl.text,
      regNo: _regNoCtrl.text,
      ownerName: _ownerCtrl.text,
      contact: _contactCtrl.text,
      email: _emailCtrl.text,
      companyType: _companyType,
      firmLogo: _firmLogo!,
      firmPhoto: _firmPhoto!,
    );

    setState(() => _isSaving = false);

    if (response.isSuccess) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text(
          "Add New Firm",
          style: AppTextStyles.h2.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionTitle("Firm Information"),
            _input(
              controller: _firmNameCtrl,
              label: "Firm Name",
              icon: Icons.storefront_outlined,
            ),
            _input(
              controller: _addressCtrl,
              label: "Firm Address",
              icon: Icons.location_on_outlined,
              maxLines: 2,
            ),
            _input(
              controller: _gstinCtrl,
              label: "GSTIN",
              icon: Icons.confirmation_number_outlined,
            ),
            _input(
              controller: _regNoCtrl,
              label: "Registration Number",
              icon: Icons.app_registration_outlined,
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            _sectionTitle("Owner Information"),
            _input(
              controller: _ownerCtrl,
              label: "Owner Name",
              icon: Icons.person_outline,
            ),
            _input(
              controller: _contactCtrl,
              label: "Contact Number",
              icon: Icons.phone_android_outlined,
              keyboardType: TextInputType.phone,
            ),
            _input(
              controller: _emailCtrl,
              label: "Email Address",
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            _sectionTitle("Upload Documents"),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.verticalMedium),
              child: JargonDropdown(
                label: "Firm Type",
                value: _companyType,
                icon: Icons.business_outlined,
                options: _companyTypes,
                showCard: false,
                showIconBackground: false,
                onChanged: (val) => setState(() => _companyType = val),
              ),
            ),
            _uploadTile(
              title: "Firm Logo",
              subtitle: _firmLogo == null ? "PNG / JPG up to 2MB" : "Selected",
              icon: Icons.image_outlined,
              onTap: () => _pickImage(true),
            ),
            const SizedBox(height: AppSpacing.verticalMedium),
            _uploadTile(
              title: "Firm Photo",
              subtitle: _firmPhoto == null ? "Shop / Office photo" : "Selected",
              icon: Icons.photo_camera_outlined,
              onTap: () => _pickImage(false),
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                ),
                onPressed: _isSaving ? null : _saveFirm,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Save Firm",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= SECTION TITLE =================
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.verticalMedium),
      child: Text(
        text,
        style: AppTextStyles.h3.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// ================= INPUT FIELD =================
  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.verticalMedium),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.primary.withOpacity(0.1),
          prefixIcon: Icon(icon, size: AppIcons.defaultSize),
          hintText: label,
          hintStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  /// ================= UPLOAD TILE =================
  Widget _uploadTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.medium),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.upload_file_outlined),
          ],
        ),
      ),
    );
  }
}

class _ImagePickerBottomSheet extends StatelessWidget {
  final String title;
  final File? imageFile;
  final VoidCallback onRemove;

  const _ImagePickerBottomSheet({
    required this.title,
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
            Text(title, style: AppTextStyles.h3),
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
                label: const Text(
                  "Remove Image",
                  style: TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: _AnimatedSourceTile(
                    icon: Icons.camera_alt_outlined,
                    label: "Camera",
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _AnimatedSourceTile(
                    icon: Icons.photo_library_outlined,
                    label: "Gallery",
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

class _AnimatedSourceTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AnimatedSourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_AnimatedSourceTile> createState() => _AnimatedSourceTileState();
}

class _AnimatedSourceTileState extends State<_AnimatedSourceTile> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(widget.icon, size: 28, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(widget.label, style: AppTextStyles.body),
            ],
          ),
        ),
      ),
    );
  }
}
