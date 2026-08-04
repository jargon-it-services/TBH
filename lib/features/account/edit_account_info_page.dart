import 'dart:io';

import 'package:action_slider/action_slider.dart';
import 'package:flutter/material.dart';

import '../../core/network/apis/account_info_api.dart';
import '../../core/network/apis/pincode_api.dart';
import '../../core/services/DataModels/account_info_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/inline_action_button.dart';
import '../../core/widgets/logo_picker_field.dart';
import '../../core/widgets/slide_action_button.dart';
import '../auth/registration/registration_validators.dart';

/// Edit Account Info form.
///
/// Shows only what's actually editable — Account Photo/Logo, Phone
/// Number, Address, Pincode/ZIP (City/State auto-derive from it, shown
/// read-only right below once verified), Full Name, Designation, and
/// GSTIN. Everything else (Account Code, Account Name, Account Email,
/// ID Proof details, Login Email) lives on the Account Info screen only
/// — deliberately left off this form entirely, rather than shown
/// disabled, so there's no ambiguity about what can and can't change
/// here.
class EditAccountInfoPage extends StatefulWidget {
  final AccountInfoResponse existing;

  const EditAccountInfoPage({super.key, required this.existing});

  @override
  State<EditAccountInfoPage> createState() => _EditAccountInfoPageState();
}

class _EditAccountInfoPageState extends State<EditAccountInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final AccountInfoApi _api = AccountInfoApi();
  final PincodeApi _pincodeApi = PincodeApi();

  late String _phone = widget.existing.phone;
  late String _address = widget.existing.address;
  late String _zip = widget.existing.zip;
  late String _city = widget.existing.city;
  late String _state = widget.existing.state;
  late String _gstin = widget.existing.gstin;
  late String _ownerName = widget.existing.ownerName;
  late String _designation = widget.existing.designation;

  File? _pickedAccountPhoto;
  bool _accountPhotoRemoved = false;

  bool _verifyingZip = false;
  bool _zipVerified = false;
  String? _zipError;
  String? _lastVerifiedZip;

  bool _isSaving = false;

  Future<void> _verifyZip() async {
    if (_verifyingZip) return;

    final zip = _zip.trim();
    if (zip.isEmpty) {
      setState(() => _zipError = 'Enter a postal code to verify');
      return;
    }

    setState(() {
      _verifyingZip = true;
      _zipError = null;
    });

    final result = await _pincodeApi.verify(zip);
    if (!mounted) return;
    setState(() => _verifyingZip = false);

    if (result.isOffline) {
      setState(() {
        _zipVerified = false;
        _zipError = "You're offline — check your connection and try verifying again.";
      });
      return;
    }

    if (!result.isValid) {
      setState(() {
        _zipVerified = false;
        _zipError = "We couldn't find this postal code. Please enter a valid one.";
      });
      return;
    }

    setState(() {
      _lastVerifiedZip = zip;
      _zipVerified = true;
      _zipError = null;
      if (result.city != null && result.city!.isNotEmpty) _city = result.city!;
      if (result.state != null && result.state!.isNotEmpty) _state = result.state!;
    });
  }

  Future<void> _save(ActionSliderController controller) async {
    if (_isSaving) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      AppSnackbar.warning(context, 'Please fix the highlighted fields');
      return;
    }

    setState(() => _isSaving = true);

    final payload = {
      'phone': _phone.trim(),
      'address': _address.trim(),
      'zip': _zip.trim(),
      'city': _city,
      'state': _state,
      'gstin': _gstin.trim(),
      'owner_name': _ownerName.trim(),
      'designation': _designation.trim(),
    };

    final response = await _api.updateAccountInfo(
      payload,
      accountPhoto: _pickedAccountPhoto,
      removeAccountPhoto: _accountPhotoRemoved,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (response.isSuccess) {
      AppSnackbar.success(context, 'Account info updated successfully');
      Navigator.pop(context, true);
    } else {
      AppSnackbar.error(context, response.error ?? 'Something went wrong. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final zipUnchangedSinceVerify =
        _zipVerified && _zip.trim() == _lastVerifiedZip && _zip.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text('Edit Account Info', style: AppTextStyles.h2.copyWith(color: Colors.white)),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _editableNote(),
                const SizedBox(height: AppSpacing.verticalLarge),
                LogoPickerField(
                  title: 'Account Photo / Logo (optional)',
                  placeholderIcon: Icons.store_mall_directory_outlined,
                  existingUrl: widget.existing.accountPhotoUrl,
                  pickedFile: _pickedAccountPhoto,
                  removed: _accountPhotoRemoved,
                  allowRemove: widget.existing.hasAccountPhoto,
                  onPicked: (file) => setState(() {
                    _pickedAccountPhoto = file;
                    _accountPhotoRemoved = false;
                  }),
                  onRemoved: () => setState(() {
                    _pickedAccountPhoto = null;
                    _accountPhotoRemoved = true;
                  }),
                ),
                const SizedBox(height: AppSpacing.verticalMedium),
                AppTextField(
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  initialValue: _phone,
                  onChanged: (v) => _phone = v,
                  validator: RegistrationValidators.phone,
                ),
                AppTextField(
                  label: 'Address',
                  icon: Icons.location_on_outlined,
                  maxLines: 2,
                  initialValue: _address,
                  onChanged: (v) => _address = v,
                  validator: (v) => RegistrationValidators.required(v, 'Address'),
                ),
                AppTextField(
                  label: 'Pin Code / ZIP Code',
                  icon: Icons.pin_drop_outlined,
                  keyboardType: TextInputType.number,
                  initialValue: _zip,
                  onChanged: (v) {
                    _zip = v;
                    setState(() => _zipError = null);
                  },
                  validator: RegistrationValidators.zip,
                  suffixIcon: _verifyingZip
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : zipUnchangedSinceVerify
                          ? Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle,
                                      size: 16, color: AppColors.success),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Verified',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : InlineActionButton(label: 'Verify', onPressed: _verifyZip),
                ),
                if (_zipError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, left: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, size: 13, color: AppColors.error),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _zipError!,
                            style: AppTextStyles.caption.copyWith(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                // City/State are never picked directly — they only
                // change via the Pincode/ZIP Verify flow above. Each
                // is keyed to its own current value so the field
                // actually remounts and shows the freshly-verified
                // text — a plain `initialValue` change alone won't
                // update an already-built TextFormField.
                AppTextField(
                  key: ValueKey('account-info-city-$_city'),
                  label: 'City',
                  icon: Icons.location_city_outlined,
                  initialValue: _city,
                  enabled: false,
                  readOnly: true,
                ),
                AppTextField(
                  key: ValueKey('account-info-state-$_state'),
                  label: 'State',
                  icon: Icons.map_outlined,
                  initialValue: _state,
                  enabled: false,
                  readOnly: true,
                ),
                AppTextField(
                  label: 'GSTIN (optional)',
                  icon: Icons.receipt_long_outlined,
                  textCapitalization: TextCapitalization.characters,
                  initialValue: _gstin,
                  onChanged: (v) => _gstin = v,
                  validator: RegistrationValidators.gstin,
                ),
                const SizedBox(height: AppSpacing.verticalSmall),
                _sectionTitle('Owner Details'),
                AppTextField(
                  label: 'Full Name',
                  icon: Icons.person_outline,
                  initialValue: _ownerName,
                  onChanged: (v) => _ownerName = v,
                  validator: (v) => RegistrationValidators.name(v, 'Full Name'),
                ),
                AppTextField(
                  label: 'Designation',
                  icon: Icons.badge_outlined,
                  initialValue: _designation,
                  onChanged: (v) => _designation = v,
                  validator: (v) => RegistrationValidators.required(v, 'Designation'),
                ),
                const SizedBox(height: AppSpacing.verticalLarge),
                SlideActionButton(
                  label: 'Slide to Save',
                  submitting: _isSaving,
                  onSlide: _save,
                ),
                const SizedBox(height: AppSpacing.verticalMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Sets expectations up front: this form only ever shows fields that
  /// can change. Everything else is on the Account Info screen behind
  /// it — addresses the "which fields are editable?" ambiguity
  /// directly, rather than mixing editable and disabled fields
  /// together.
  Widget _editableNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Only the fields below can be updated. Everything else '
              '(Account Code, Account Name, Account Email, ID Proof, '
              'Login Email) is shown on the Account Info screen and '
              "can't be changed here.",
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.verticalMedium),
      child: Text(
        text,
        style: AppTextStyles.h3.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
      ),
    );
  }
}
