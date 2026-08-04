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
import '../../core/widgets/slide_action_button.dart';
import '../auth/registration/registration_validators.dart';

/// Edit Account Info form.
///
/// Only five fields are ever editable — Phone Number, Address,
/// Pincode/ZIP (City/State auto-derive from it, exactly like
/// Registration's `Step1ContactInfo`), Full Name, and Designation.
/// Every other Account Info field (Account Name, Account Email, ID
/// Proof Type/Number/Document, Login Email) is shown as a disabled
/// [AppTextField] instead — visible for context, but never an input —
/// same disabled-field convention already used for Service's Type
/// field and Staff's read-only fields elsewhere in the app.
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
  late String _ownerName = widget.existing.ownerName;
  late String _designation = widget.existing.designation;

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
      'owner_name': _ownerName.trim(),
      'designation': _designation.trim(),
    };

    final response = await _api.updateAccountInfo(payload);
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
                _sectionTitle('Account Information'),
                AppTextField(
                  label: 'Account Name',
                  icon: Icons.badge_outlined,
                  initialValue: widget.existing.accountName,
                  enabled: false,
                  readOnly: true,
                ),
                AppTextField(
                  label: 'Account Email',
                  icon: Icons.email_outlined,
                  initialValue: widget.existing.accountEmail,
                  enabled: false,
                  readOnly: true,
                ),
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
                    if (_zipError != null) setState(() => _zipError = null);
                    if (_zip.trim() != _lastVerifiedZip) setState(() {});
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
                // City/State are never picked directly — same as
                // Registration's Step1ContactInfo, they only ever
                // change via the Pincode/ZIP Verify flow above.
                AppTextField(
                  label: 'City',
                  icon: Icons.location_city_outlined,
                  initialValue: _city,
                  enabled: false,
                  readOnly: true,
                ),
                AppTextField(
                  label: 'State',
                  icon: Icons.map_outlined,
                  initialValue: _state,
                  enabled: false,
                  readOnly: true,
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
                AppTextField(
                  label: 'ID Proof Type',
                  icon: Icons.badge_outlined,
                  initialValue: widget.existing.idProofType,
                  enabled: false,
                  readOnly: true,
                ),
                AppTextField(
                  label: 'ID Proof Number',
                  icon: Icons.confirmation_number_outlined,
                  initialValue: widget.existing.idProofNumber,
                  enabled: false,
                  readOnly: true,
                ),
                const SizedBox(height: AppSpacing.verticalSmall),
                _sectionTitle('Login'),
                AppTextField(
                  label: 'Login Email',
                  icon: Icons.alternate_email,
                  initialValue: widget.existing.loginEmail,
                  enabled: false,
                  readOnly: true,
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
