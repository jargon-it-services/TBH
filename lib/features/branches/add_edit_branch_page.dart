import 'dart:io';

import 'package:action_slider/action_slider.dart';
import 'package:flutter/material.dart';

import '../../core/network/apis/branches_api.dart';
import '../../core/services/DataModels/branch_detail_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/logo_picker_field.dart';
import '../../core/widgets/maps_link_field.dart';
import '../../core/widgets/pincode_lookup_field.dart';
import '../../core/widgets/segmented_toggle.dart';
import '../../core/widgets/slide_action_button.dart';
import '../auth/registration/registration_validators.dart';

/// Create/Edit Branch form.
///
/// Pass [existing] to edit an already-loaded branch (fields pre-filled,
/// Save calls `BranchesApi.updateBranch`); omit it to create a new one
/// (`BranchesApi.createBranch`). Reuses the same building blocks as
/// `AddFirmPage`/the registration flow throughout: [AppTextField],
/// [SegmentedToggle] (Branch Type and Status — the same pill-toggle
/// style as the Subscriptions page's Monthly/Annual switch),
/// [PincodeLookupField] (State/City lookup, shared
/// with Registration's pattern, read-only here), [MapsLinkField]
/// (paste-and-save a Google Maps link; coordinates are extracted
/// server-side, not on-device), [LogoPickerField]
/// (upload/replace/remove), and [SlideActionButton] for Save, per the
/// Branch module spec.
class AddEditBranchPage extends StatefulWidget {
  final BranchDetailResponse? existing;

  const AddEditBranchPage({super.key, this.existing});

  bool get isEdit => existing != null;

  @override
  State<AddEditBranchPage> createState() => _AddEditBranchPageState();
}

class _AddEditBranchPageState extends State<AddEditBranchPage> {
  static const List<String> _branchTypes = ['Male', 'Female', 'Unisex'];
  static const List<String> _statusOptions = ['Active', 'Deactive'];
  static const List<String> _weekDays = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  final _formKey = GlobalKey<FormState>();
  final _pincodeFieldKey = GlobalKey<PincodeLookupFieldState>();
  final BranchesApi _branchesApi = BranchesApi();

  late String _name = widget.existing?.name ?? '';
  late String _address1 = widget.existing?.addressLine1 ?? '';
  late String _address2 = widget.existing?.addressLine2 ?? '';
  late String _pincode = widget.existing?.pincode ?? '';
  late String _mobile = widget.existing?.mobile ?? '';
  late String _email = widget.existing?.email ?? '';

  late String _city = widget.existing?.city ?? '';
  late String _state = widget.existing?.state ?? '';
  late String _branchType = widget.existing?.branchType ?? 'Unisex';

  // Defaults to Active for a brand-new branch, per the Add New Branch
  // spec — previously this started blank, which (combined with the
  // dropdown's hint text not being a real option) was part of why a
  // fresh Add New Branch form could hit an invalid state on save.
  late String _status;
  late String _originalStatus;

  // Saved as-is; the backend extracts latitude/longitude from this
  // link on its own — see MapsLinkField's doc comment for why.
  late String _mapsLink = widget.existing?.mapsLink ?? '';

  TimeOfDay? _openingTime;
  TimeOfDay? _closingTime;

  // ------------- Weekly Off (mandatory; "No Weekly Off" is mutually
  // exclusive with picking individual days) -------------
  Set<String> _selectedWeekDays = {};
  bool _noWeeklyOff = false;

  // ------------- Logo -------------
  File? _pickedLogo;
  bool _logoRemoved = false;

  // ------------- Services -------------
  // Not editable from this form (same restriction as employees — see
  // spec: services/staff are only assigned from their own dedicated
  // flows). Preserved unmodified from the existing branch on Edit so
  // saving doesn't wipe out its current service assignments; empty for
  // a brand-new branch, same as it has no staff yet either.
  final Set<int> _selectedServiceIds = {};

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.existing?.status ?? 'Active';
    _originalStatus = widget.existing?.status ?? 'Active';

    final existing = widget.existing;

    if (existing != null) {
      _openingTime = _parseTime(existing.openingTime);
      _closingTime = _parseTime(existing.closingTime);
      _selectedServiceIds.addAll(existing.services.map((s) => s.id));
      _noWeeklyOff = existing.isNoWeeklyOff;
      _selectedWeekDays = existing.weeklyOffDays.toSet();
    }
  }

  TimeOfDay? _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime({required bool isOpening}) async {
    // Explicit unfocus: moving from a text field straight into the
    // time picker previously left the keyboard showing underneath it.
    FocusScope.of(context).unfocus();

    final initial =
        (isOpening ? _openingTime : _closingTime) ?? TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() {
      if (isOpening) {
        _openingTime = picked;
      } else {
        _closingTime = picked;
      }
    });
  }

  void _toggleWeekDay(String day) {
    setState(() {
      if (_selectedWeekDays.contains(day)) {
        _selectedWeekDays.remove(day);
      } else {
        _selectedWeekDays.add(day);
      }
      // Picking any individual day cancels "No Weekly Off" — the two
      // are mutually exclusive, per the Add New Branch spec.
      if (_selectedWeekDays.isNotEmpty) _noWeeklyOff = false;
    });
  }

  void _toggleNoWeeklyOff() {
    setState(() {
      _noWeeklyOff = !_noWeeklyOff;
      if (_noWeeklyOff) _selectedWeekDays.clear();
    });
  }

  /// Validates the non-TextFormField selections (dropdowns, State/City,
  /// hours, weekly off) that live outside the [Form] — same approach
  /// `Step1ContactInfo._validateSelections` uses for State/City.
  bool _validateSelections() {
    final stateAndCityValid =
        _pincodeFieldKey.currentState?.validateSelections() ?? false;

    final errors = <String>[];
    if (!stateAndCityValid) errors.add('state/city');
    if (_branchType.isEmpty) errors.add('branch type');
    if (_status.isEmpty) errors.add('status');
    if (!_noWeeklyOff && _selectedWeekDays.isEmpty) errors.add('weekly off');
    if (_openingTime == null) errors.add('opening time');
    if (_closingTime == null) errors.add('closing time');

    if (errors.isNotEmpty) {
      AppSnackbar.warning(context, 'Please select: ${errors.join(', ')}');
      return false;
    }

    final opening = _openingTime!.hour * 60 + _openingTime!.minute;
    final closing = _closingTime!.hour * 60 + _closingTime!.minute;
    if (closing <= opening) {
      AppSnackbar.warning(context, 'Closing time must be after opening time');
      return false;
    }

    return true;
  }

  /// Active → Inactive is a meaningful, disruptive change (staff/booking
  /// visibility), so Edit Branch confirms it before saving, per spec.
  /// Not shown for Add New Branch (nothing to "change" yet) or for any
  /// other status transition.
  Future<bool> _confirmStatusChangeIfNeeded() async {
    final goingInactive =
        widget.isEdit && _originalStatus == 'Active' && _status != 'Active';
    if (!goingInactive) return true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.pageBackground,
        title: const Text('Deactivate this branch?'),
        content: Text(
          '${_name.isEmpty ? "This branch" : _name} will be marked Deactive. '
          'It may stop appearing in all flows until reactivated.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Deactivate',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _save(ActionSliderController controller) async {
    if (_isSaving) return;

    try {
      if (!(_formKey.currentState?.validate() ?? false)) {
        AppSnackbar.warning(context, 'Please fix the highlighted fields');
        return;
      }
      if (!_validateSelections()) return;
      if (!await _confirmStatusChangeIfNeeded()) return;

      if (!mounted) return;
      setState(() => _isSaving = true);

      final payload = {
        'name': _name.trim(),
        'address_line1': _address1.trim(),
        'address_line2': _address2.trim(),
        'city': _city,
        'state': _state,
        'pincode': _pincode.trim(),
        'maps_link': _mapsLink.trim().isEmpty ? null : _mapsLink.trim(),
        'mobile': _mobile.trim(),
        'email': _email.trim(),
        'branch_type': _branchType,
        'opening_time': _formatTime(_openingTime!),
        'closing_time': _formatTime(_closingTime!),
        'weekly_off': _noWeeklyOff ? 'None' : _selectedWeekDays.join(','),
        'status': _status,
        'service_ids': _selectedServiceIds.toList(),
      };

      final response = widget.isEdit
          ? await _branchesApi.updateBranch(
              widget.existing!.id,
              payload,
              logo: _pickedLogo,
              removeLogo: _logoRemoved,
            )
          : await _branchesApi.createBranch(payload, logo: _pickedLogo);

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (response.isSuccess) {
        AppSnackbar.success(
          context,
          widget.isEdit
              ? 'Branch updated successfully'
              : 'Branch created successfully',
        );
        Navigator.pop(context, true);
      } else {
        // Covers both API failures (server said no) and network
        // failures (offline/timeout) — ApiResponse.error already
        // carries the right user-facing message for either, via
        // ApiException/isConnectivityError in the shared callApi
        // helper.
        AppSnackbar.error(
          context,
          response.error ?? 'Something went wrong. Please try again.',
        );
      }
    } catch (e) {
      // Belt-and-braces: anything unexpected that slips past the
      // validation/API layers above (e.g. a bad local file read while
      // preparing the logo) still surfaces as a clear message instead
      // of an unhandled exception.
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppSnackbar.error(
        context,
        "Something went wrong while saving. Please try again.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text(
          widget.isEdit ? 'Edit Branch' : 'Add New Branch',
          style: AppTextStyles.h2.copyWith(color: Colors.white),
        ),
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
                _sectionTitle('Branch Logo'),
                LogoPickerField(
                  title: 'Branch Logo',
                  existingUrl: widget.existing?.logo,
                  pickedFile: _pickedLogo,
                  removed: _logoRemoved,
                  allowRemove: widget.isEdit,
                  onPicked: (file) => setState(() {
                    _pickedLogo = file;
                    _logoRemoved = false;
                  }),
                  onRemoved: () => setState(() {
                    _pickedLogo = null;
                    _logoRemoved = true;
                  }),
                ),
                const SizedBox(height: AppSpacing.verticalLarge),
                _sectionTitle('Basic Information'),
                AppTextField(
                  label: 'Branch Name',
                  icon: Icons.storefront_outlined,
                  initialValue: _name,
                  onChanged: (v) => _name = v,
                  validator: (v) =>
                      RegistrationValidators.required(v, 'Branch Name'),
                ),
                AppTextField(
                  label: 'Address Line 1',
                  icon: Icons.location_on_outlined,
                  initialValue: _address1,
                  onChanged: (v) => _address1 = v,
                  validator: (v) =>
                      RegistrationValidators.required(v, 'Address'),
                ),
                AppTextField(
                  label: 'Address Line 2 (optional)',
                  icon: Icons.location_on_outlined,
                  initialValue: _address2,
                  onChanged: (v) => _address2 = v,
                ),
                PincodeLookupField(
                  key: _pincodeFieldKey,
                  initialPincode: _pincode,
                  onPincodeChanged: (v) => _pincode = v,
                  initialState: _state,
                  initialCity: _city,
                  onStateSelected: (v) => _state = v,
                  onCitySelected: (v) => _city = v,
                  pincodeValidator: RegistrationValidators.zip,
                ),
                const SizedBox(height: AppSpacing.verticalSmall),
                _sectionTitle('Location'),
                MapsLinkField(
                  initialValue: _mapsLink,
                  onChanged: (v) => _mapsLink = v,
                ),
                const SizedBox(height: AppSpacing.verticalMedium),
                _sectionTitle('Contact Information'),
                AppTextField(
                  label: 'Mobile Number',
                  icon: Icons.phone_android_outlined,
                  keyboardType: TextInputType.phone,
                  initialValue: _mobile,
                  onChanged: (v) => _mobile = v,
                  validator: RegistrationValidators.phone,
                ),
                AppTextField(
                  label: 'Email (Username)',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  initialValue: _email,
                  onChanged: (v) => _email = v,
                  validator: RegistrationValidators.email,
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppSpacing.verticalMedium,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Branch Type'),
                      const SizedBox(height: AppSpacing.verticalSmall),
                      SegmentedToggle(
                        options: _branchTypes,
                        value: _branchType.isEmpty ? null : _branchType,
                        onChanged: (val) => setState(() => _branchType = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.verticalSmall),
                _sectionTitle('Working Hours'),
                Row(
                  children: [
                    Expanded(
                      child: _timeTile(
                        label: 'Opening Time',
                        icon: Icons.login_outlined,
                        time: _openingTime,
                        onTap: () => _pickTime(isOpening: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _timeTile(
                        label: 'Closing Time',
                        icon: Icons.logout_outlined,
                        time: _closingTime,
                        onTap: () => _pickTime(isOpening: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.verticalMedium),
                _weeklyOffPicker(),
                const SizedBox(height: AppSpacing.verticalMedium),
                _sectionTitle('Status'),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppSpacing.verticalMedium,
                  ),
                  child: SegmentedToggle(
                    options: _statusOptions,
                    value: _status,
                    onChanged: (val) => setState(() => _status = val),
                  ),
                ),
                const SizedBox(height: AppSpacing.verticalLarge),
                SlideActionButton(
                  label: widget.isEdit ? 'Slide to Update' : 'Slide to Save',
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
        style: AppTextStyles.h3.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _timeTile({
    required String label,
    required IconData icon,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.verticalMedium),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: Row(
            children: [
              Icon(icon, size: AppIcons.defaultSize),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  time != null ? time.format(context) : label,
                  style: AppTextStyles.body.copyWith(
                    color: time != null ? AppColors.textPrimary : Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.access_time_outlined,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Weekly Off — mandatory multi-select of weekdays, with a dedicated
  /// "No Weekly Off" chip that's mutually exclusive with picking
  /// individual days (selecting one clears the other), per the Add New
  /// Branch spec. Kept as a feature-local chip picker since no shared
  /// multi-select chip widget exists elsewhere in the app yet.
  Widget _weeklyOffPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Weekly Off *'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._weekDays.map((day) {
              final selected = _selectedWeekDays.contains(day);
              return _chip(
                label: day,
                selected: selected,
                onTap: () => _toggleWeekDay(day),
              );
            }),
            _chip(
              label: 'No Weekly Off',
              selected: _noWeeklyOff,
              onTap: _toggleNoWeeklyOff,
              color: AppColors.secondary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color color = AppColors.primary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check, size: 14, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: selected ? Colors.white : color,
                fontWeight: selected ? FontWeight.w600 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// There is deliberately no service or employee/staff picker anywhere
  /// on this page — Add/Edit Branch must not allow assigning or
  /// removing services or employees, per spec; both only happen from
  /// their own dedicated management flows.
}
