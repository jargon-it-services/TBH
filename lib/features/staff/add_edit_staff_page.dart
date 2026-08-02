import 'dart:io';

import 'package:action_slider/action_slider.dart';
import 'package:flutter/material.dart';

import '../../core/network/apis/staff_api.dart';
import '../../core/services/DataModels/branch_model.dart';
import '../../core/services/DataModels/salary_rule_model.dart';
import '../../core/services/DataModels/staff_detail_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/app_date_field.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/jargon_dropdown.dart';
import '../../core/widgets/logo_picker_field.dart';
import '../../core/widgets/segmented_toggle.dart';
import '../../core/widgets/slide_action_button.dart';
import '../auth/registration/registration_validators.dart';

/// Create/Edit Staff form.
///
/// Pass [existing] to edit an already-loaded staff member (fields
/// pre-filled, Save calls `StaffApi.updateStaff`); omit it to create a
/// new one (`StaffApi.createStaff`). Structure and building blocks
/// mirror `AddEditServicePage`/`AddEditBranchPage` throughout:
/// [AppTextField] for text/number inputs, [SegmentedToggle] for every
/// binary/small choice (Gender, Designation, Status, Allow App Login,
/// App Role — the app's existing Active/Inactive-style toggle, reused
/// rather than reinvented), [JargonDropdown] for Specialist/Branch/
/// Salary Rule (too many options for a segmented row), [AppDateField]
/// for Joining Date, [LogoPickerField] for Profile Photo and the
/// Aadhaar Card upload, and [SlideActionButton] for Save.
///
/// Branch, Salary Rule, and Specialist options all come from one
/// `StaffApi.fetchStaffFormConfig()` call rather than three separate
/// lookups. There's no Username/Password here — app login credentials
/// are never set from this form; a staff member with Allow App Login
/// enabled sets their own password via the existing Reset Password
/// flow on the login screen (see [_appAccessNote]).
///
/// Name/Mobile/Email/Aadhaar validation reuses `RegistrationValidators`
/// directly rather than duplicating those regexes — the same rules
/// Registration already enforces apply here.
class AddEditStaffPage extends StatefulWidget {
  final StaffDetailResponse? existing;

  const AddEditStaffPage({super.key, this.existing});

  bool get isEdit => existing != null;

  @override
  State<AddEditStaffPage> createState() => _AddEditStaffPageState();
}

class _AddEditStaffPageState extends State<AddEditStaffPage> {
  static const List<String> _genders = ['Male', 'Female', 'Other'];
  static const List<String> _designations = [
    'Admin',
    'Manager',
    'Employee',
    'Receptionist',
  ];
  static const List<String> _statusOptions = ['Active', 'Inactive'];
  static const List<String> _allowLoginOptions = ['Yes', 'No'];
  static const List<String> _appRoles = ['Branch Admin', 'Manager', 'Employee'];

  final _formKey = GlobalKey<FormState>();
  final StaffApi _staffApi = StaffApi();

  // ------------- Personal Information -------------
  late String _fullName = widget.existing?.fullName ?? '';
  late String _mobile = widget.existing?.mobile ?? '';
  late String _email = widget.existing?.email ?? '';
  late String _gender =
      widget.existing != null && widget.existing!.gender.isNotEmpty
      ? widget.existing!.gender
      : _genders.first;
  late String _aadhaarNumber = widget.existing?.aadhaarNumber ?? '';

  File? _pickedPhoto;
  bool _photoRemoved = false;
  File? _pickedAadhaarCard;
  bool _aadhaarCardRemoved = false;

  // ------------- Employment Details -------------
  late String _employeeCode = widget.existing?.employeeCode ?? '';
  bool _fetchingEmployeeCode = false;
  DateTime? _joiningDate;
  late String _designation =
      widget.existing != null && widget.existing!.designation.isNotEmpty
      ? widget.existing!.designation
      : _designations.first;

  // Specialist, Branch, and Salary Rule options all come from one
  // config call (see _loadFormConfig) rather than a hardcoded list —
  // _specialist starts as whatever the staff member already has (edit
  // mode) or empty until the config loads in (create mode).
  String _specialist = '';
  List<String> _specialistOptions = [];

  int? _branchId;
  String? _branchName;
  List<BranchModel> _branchOptions = [];

  int? _salaryRuleId;
  String? _salaryRuleName;
  List<SalaryRuleModel> _salaryRuleOptions = [];

  bool _loadingConfig = true;

  late String _status = widget.existing?.status ?? 'Active';
  late String _originalStatus = widget.existing?.status ?? 'Active';

  // ------------- Application Access -------------
  late String _allowAppLogin = (widget.existing?.allowAppLogin ?? false)
      ? 'Yes'
      : 'No';
  late String _appRole =
      widget.existing != null && widget.existing!.appRole.isNotEmpty
      ? widget.existing!.appRole
      : _appRoles.last;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadFormConfig();
    _joiningDate =
        widget.existing != null && widget.existing!.joiningDate.isNotEmpty
        ? DateTime.tryParse(widget.existing!.joiningDate)
        : null;
    _specialist = widget.existing?.specialist ?? '';

    _branchId = widget.existing?.branchId;
    _branchName = (widget.existing?.branchName.isNotEmpty ?? false)
        ? widget.existing!.branchName
        : null;

    _salaryRuleId = widget.existing?.salaryRuleId;
    _salaryRuleName = (widget.existing?.salaryRuleName.isNotEmpty ?? false)
        ? widget.existing!.salaryRuleName
        : null;
    if (!widget.isEdit) _fetchSuggestedEmployeeCode();
  }

  /// Single call for everything the form's dropdowns need — Branch
  /// list, Salary Rule list, and Specialist list — instead of three
  /// separate lookups.
  Future<void> _loadFormConfig() async {
    final response = await _staffApi.fetchStaffFormConfig();
    if (!mounted) return;
    final config = response.data;
    setState(() {
      _branchOptions = config?.branches ?? [];
      _salaryRuleOptions = config?.salaryRules ?? [];
      _specialistOptions = config?.specialists ?? [];
      if (_specialist.isEmpty && _specialistOptions.isNotEmpty) {
        _specialist = _specialistOptions.first;
      }
      _loadingConfig = false;
    });
  }

  /// Best-effort Employee Code suggestion for a brand-new staff member.
  /// Per the spec, if the backend doesn't support this (empty/failed
  /// response), the field is simply left blank for manual entry — this
  /// never blocks the form.
  Future<void> _fetchSuggestedEmployeeCode() async {
    setState(() => _fetchingEmployeeCode = true);
    final response = await _staffApi.fetchNextEmployeeCode();
    if (!mounted) return;
    setState(() {
      _fetchingEmployeeCode = false;
      if (response.isSuccess && (response.data?.isNotEmpty ?? false)) {
        _employeeCode = response.data!;
      }
    });
  }

  /// Validates the non-TextFormField selections (dropdowns, toggles,
  /// branch/salary rule pickers) that live outside the [Form] — same
  /// approach `AddEditServicePage._validateSelections` uses.
  bool _validateSelections() {
    final errors = <String>[];
    if (_designation.isEmpty) errors.add('designation');
    if (_specialist.isEmpty) errors.add('specialist');
    if (_branchId == null) errors.add('branch');
    if (_salaryRuleId == null) errors.add('salary rule');
    if (_joiningDate == null) errors.add('joining date');

    if (_allowAppLogin == 'Yes') {
      if (_appRole.isEmpty) errors.add('app role');
    }

    if (errors.isNotEmpty) {
      AppSnackbar.warning(context, 'Please select: ${errors.join(', ')}');
      return false;
    }
    return true;
  }

  /// Active → Inactive is a meaningful, disruptive change (the staff
  /// member may lose app access/scheduling visibility), so Edit Staff
  /// confirms it before saving — same pattern
  /// `AddEditServicePage._confirmStatusChangeIfNeeded` uses.
  Future<bool> _confirmStatusChangeIfNeeded() async {
    final goingInactive =
        widget.isEdit && _originalStatus == 'Active' && _status != 'Active';
    if (!goingInactive) return true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.pageBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        title: const Text(
          'Mark this staff member Inactive?',
          style: AppTextStyles.h3,
        ),
        content: Text(
          '${_fullName.isEmpty ? "This staff member" : _fullName} will be marked '
          'Inactive and may lose scheduling/app access until reactivated.',
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
              'Mark Inactive',
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

      final allowLogin = _allowAppLogin == 'Yes';

      final payload = {
        'full_name': _fullName.trim(),
        'mobile': _mobile.trim(),
        'email': _email.trim(),
        'gender': _gender,
        'aadhaar_number': _aadhaarNumber.trim(),
        'employee_code': _employeeCode.trim(),
        'joining_date': _joiningDate!.toIso8601String().split('T').first,
        'designation': _designation,
        'specialist': _specialist,
        'branch_id': _branchId,
        'salary_rule_id': _salaryRuleId,
        'status': _status,
        'allow_app_login': allowLogin,
        'app_role': allowLogin ? _appRole : null,
      };

      final response = widget.isEdit
          ? await _staffApi.updateStaff(
              widget.existing!.id,
              payload,
              photo: _pickedPhoto,
              aadhaarCard: _pickedAadhaarCard,
              removePhoto: _photoRemoved,
              removeAadhaarCard: _aadhaarCardRemoved,
            )
          : await _staffApi.createStaff(
              payload,
              photo: _pickedPhoto,
              aadhaarCard: _pickedAadhaarCard,
            );

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (response.isSuccess) {
        AppSnackbar.success(
          context,
          widget.isEdit
              ? 'Staff member updated successfully'
              : 'Staff member added successfully',
        );
        Navigator.pop(context, true);
      } else {
        AppSnackbar.error(
          context,
          response.error ?? 'Something went wrong. Please try again.',
        );
      }
    } catch (e) {
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
          widget.isEdit ? 'Edit Staff' : 'Add New Staff',
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
                _sectionTitle('Personal Information'),
                LogoPickerField(
                  title: 'Profile Photo',
                  placeholderIcon: Icons.person_outline,
                  existingUrl: widget.existing?.photo,
                  pickedFile: _pickedPhoto,
                  removed: _photoRemoved,
                  allowRemove: widget.isEdit,
                  onPicked: (file) => setState(() {
                    _pickedPhoto = file;
                    _photoRemoved = false;
                  }),
                  onRemoved: () => setState(() {
                    _pickedPhoto = null;
                    _photoRemoved = true;
                  }),
                ),
                const SizedBox(height: AppSpacing.verticalMedium),
                AppTextField(
                  label: 'Full Name',
                  icon: Icons.badge_outlined,
                  initialValue: _fullName,
                  onChanged: (v) => _fullName = v,
                  validator: (v) => RegistrationValidators.name(v, 'Full Name'),
                ),
                AppTextField(
                  label: 'Mobile Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  initialValue: _mobile,
                  onChanged: (v) => _mobile = v,
                  validator: RegistrationValidators.phone,
                ),
                AppTextField(
                  label: 'Email Address',
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
                      _sectionTitle('Gender'),
                      SegmentedToggle(
                        options: _genders,
                        value: _gender.isEmpty ? null : _gender,
                        onChanged: (val) => setState(() => _gender = val),
                      ),
                    ],
                  ),
                ),
                AppTextField(
                  label: 'Aadhaar Number (optional)',
                  icon: Icons.credit_card_outlined,
                  keyboardType: TextInputType.number,
                  initialValue: _aadhaarNumber,
                  onChanged: (v) => _aadhaarNumber = v,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? null
                      : RegistrationValidators.idProofNumber(v, 'Aadhaar Card'),
                ),
                LogoPickerField(
                  title: 'Aadhaar Card Upload',
                  placeholderIcon: Icons.badge_outlined,
                  existingUrl: widget.existing?.aadhaarCardUrl,
                  pickedFile: _pickedAadhaarCard,
                  removed: _aadhaarCardRemoved,
                  allowRemove: widget.isEdit,
                  onPicked: (file) => setState(() {
                    _pickedAadhaarCard = file;
                    _aadhaarCardRemoved = false;
                  }),
                  onRemoved: () => setState(() {
                    _pickedAadhaarCard = null;
                    _aadhaarCardRemoved = true;
                  }),
                ),
                const SizedBox(height: AppSpacing.verticalLarge),
                _sectionTitle('Employment Details'),
                AppTextField(
                  label: _fetchingEmployeeCode
                      ? 'Generating code…'
                      : 'Employee Code',
                  icon: Icons.tag_outlined,
                  initialValue: _employeeCode,
                  enabled: !_fetchingEmployeeCode,
                  onChanged: (v) => _employeeCode = v,
                  validator: (v) =>
                      RegistrationValidators.required(v, 'Employee Code'),
                ),
                AppDateField(
                  label: 'Joining Date',
                  icon: Icons.event_outlined,
                  value: _joiningDate,
                  onChanged: (date) => setState(() => _joiningDate = date),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Joining Date is required'
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppSpacing.verticalMedium,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Designation'),
                      SegmentedToggle(
                        options: _designations,
                        value: _designation.isEmpty ? null : _designation,
                        onChanged: (val) => setState(() => _designation = val),
                      ),
                    ],
                  ),
                ),
                _loadingConfig
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.verticalMedium,
                        ),
                        child: JargonDropdown(
                          label: 'Specialist',
                          value: _specialist.isEmpty
                              ? 'Select Specialist'
                              : _specialist,
                          icon: Icons.content_cut_outlined,
                          options: _specialistOptions,
                          showLabel: true,
                          onChanged: (v) => setState(() => _specialist = v),
                        ),
                      ),
                _branchPicker(),
                _salaryRulePicker(),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppSpacing.verticalMedium,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Status'),
                      SegmentedToggle(
                        options: _statusOptions,
                        value: _status,
                        onChanged: (val) => setState(() => _status = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.verticalSmall),
                _sectionTitle('Application Access'),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppSpacing.verticalMedium,
                  ),
                  child: SegmentedToggle(
                    options: _allowLoginOptions,
                    value: _allowAppLogin,
                    onChanged: (val) => setState(() => _allowAppLogin = val),
                  ),
                ),
                if (_allowAppLogin == 'Yes') ...[
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppSpacing.verticalMedium,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('App Role'),
                        SegmentedToggle(
                          options: _appRoles,
                          value: _appRole.isEmpty ? null : _appRole,
                          onChanged: (val) => setState(() => _appRole = val),
                        ),
                      ],
                    ),
                  ),
                  _appAccessNote(),
                ],
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

  Widget _branchPicker() {
    if (_loadingConfig) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.verticalMedium),
      child: JargonDropdown(
        label: 'Branch',
        value: _branchName ?? 'Select Branch',
        icon: Icons.store_mall_directory_outlined,
        options: _branchOptions.map((b) => b.name).toList(),
        showLabel: true,
        onChanged: (name) {
          final match = _branchOptions.firstWhere((b) => b.name == name);
          setState(() {
            _branchName = match.name;
            _branchId = match.id;
          });
        },
      ),
    );
  }

  Widget _salaryRulePicker() {
    if (_loadingConfig) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.verticalMedium),
      child: JargonDropdown(
        label: 'Salary Rule',
        value: _salaryRuleName ?? 'Select Salary Rule',
        icon: Icons.rule_folder_outlined,
        options: _salaryRuleOptions.map((r) => r.name).toList(),
        showLabel: true,
        onChanged: (name) {
          final match = _salaryRuleOptions.firstWhere((r) => r.name == name);
          setState(() {
            _salaryRuleName = match.name;
            _salaryRuleId = match.id;
          });
        },
      ),
    );
  }

  /// Shown instead of Username/Password fields when Allow App Login is
  /// Yes — this form never sets or resets a staff member's password.
  /// The staff member sets/resets their own password themselves via
  /// the existing Reset Password flow on the login screen (login
  /// identifier defaults to their Email Address).
  Widget _appAccessNote() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.verticalMedium),
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
              'No password is set from here. Ask '
              '${_fullName.trim().isEmpty ? "the staff member" : _fullName.trim()} '
              'to use the Reset Password flow on the login screen '
              '(with ${_email.trim().isEmpty ? "their email address" : _email.trim()}) '
              'to set up their password.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
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
        style: AppTextStyles.h3.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
