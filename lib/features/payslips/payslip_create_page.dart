import 'package:action_slider/action_slider.dart';
import 'package:flutter/material.dart';

import '../../core/network/apis/branches_api.dart';
import '../../core/network/apis/payslip_api.dart';
import '../../core/network/apis/staff_api.dart';
import '../../core/services/DataModels/branch_model.dart';
import '../../core/services/DataModels/staff_list_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/jargon_dropdown.dart';
import '../../core/widgets/multi_select_field.dart';
import '../../core/widgets/segmented_toggle.dart';
import '../../core/widgets/shimmers/salary_rule_list_shimmer.dart';
import '../../core/widgets/slide_action_button.dart';

/// Create Payslip form (module spec §7-§10). Building blocks mirror
/// `AddEditSalaryRulePage` throughout: [SegmentedToggle] for the
/// Yes/No "generate for all employees" choice, [SlideActionButton] for
/// the primary action. Branch and Employee pickers reuse
/// [MultiSelectField] — the same multi-select component the Service
/// module already uses for Branch Assignment — instead of introducing
/// a new selection widget, per the module spec's "reuse existing
/// components" constraint.
///
/// Branch/Employee options are fetched directly from the existing
/// `BranchesApi`/`StaffApi` catalogs (same ones Reports and Staff
/// Management already call) rather than a new form-config endpoint.
class PayslipCreatePage extends StatefulWidget {
  const PayslipCreatePage({super.key});

  @override
  State<PayslipCreatePage> createState() => _PayslipCreatePageState();
}

class _PayslipCreatePageState extends State<PayslipCreatePage> {
  static const List<String> _yesNo = ['Yes', 'No'];
  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  final PayslipApi _api = PayslipApi();
  final BranchesApi _branchesApi = BranchesApi();
  final StaffApi _staffApi = StaffApi();

  bool _loadingOptions = true;
  String? _loadError;

  List<BranchModel> _branches = [];
  List<StaffListItem> _staff = [];

  Set<int> _selectedBranchIds = {};
  String _generateForAll = 'Yes';
  Set<int> _selectedEmployeeIds = {};

  late List<_MonthYearOption> _monthYearOptions = _buildMonthYearOptions();
  late _MonthYearOption _selectedMonthYear = _monthYearOptions.firstWhere(
    (o) => o.month == DateTime.now().month && o.year == DateTime.now().year,
    orElse: () => _monthYearOptions.first,
  );

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  List<_MonthYearOption> _buildMonthYearOptions() {
    final now = DateTime.now();
    final options = <_MonthYearOption>[];
    // 6 months back through 6 months ahead — plenty of range for
    // running payroll a little late or generating it in advance.
    for (var offset = -6; offset <= 6; offset++) {
      final date = DateTime(now.year, now.month + offset, 1);
      options.add(_MonthYearOption(date.month, date.year, '${_monthNames[date.month - 1]} ${date.year}'));
    }
    return options;
  }

  Future<void> _loadOptions() async {
    setState(() {
      _loadingOptions = true;
      _loadError = null;
    });

    // Sequential (rather than Future.wait) — see PayslipListPage's
    // `_loadAll` for why differently-typed ApiResponse<T>s aren't
    // combined into one Future.wait call here.
    final branchResponse = await _branchesApi.fetchBranches();
    final staffResponse = await _staffApi.fetchStaffList();

    if (!mounted) return;

    if (branchResponse.isSuccess && staffResponse.isSuccess) {
      setState(() {
        _branches = branchResponse.data ?? [];
        _staff = staffResponse.data ?? [];
        _loadingOptions = false;
      });
    } else {
      setState(() {
        _loadingOptions = false;
        _loadError = branchResponse.error ?? staffResponse.error ?? "We couldn't load form options right now.";
      });
    }
  }

  bool get _forAllEmployees => _generateForAll == 'Yes';

  // ---------------- VALIDATION + SUBMIT ----------------

  bool _validate() {
    if (!_forAllEmployees && _selectedEmployeeIds.isEmpty) {
      AppSnackbar.warning(context, 'Please select at least one employee');
      return false;
    }
    return true;
  }

  Future<void> _generate(ActionSliderController controller) async {
    if (_isSaving) return;
    if (!_validate()) return;

    setState(() => _isSaving = true);

    final payload = {
      // Empty branch selection means "All branches" (§7.1) — same
      // "empty = any" convention MultiSelectField already uses on the
      // List screen's branch filter.
      'branch_ids': _selectedBranchIds.toList(),
      'generate_for_all_employees': _forAllEmployees,
      'employee_ids': _forAllEmployees ? <int>[] : _selectedEmployeeIds.toList(),
      'month': _selectedMonthYear.month,
      'year': _selectedMonthYear.year,
    };

    final response = await _api.generatePayslip(payload);
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (response.isSuccess) {
      AppSnackbar.success(context, 'Payslip generation started successfully');
      Navigator.pop(context, true);
    } else {
      AppSnackbar.error(context, response.error ?? 'Something went wrong. Please try again.');
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: Text('Generate Payslip', style: AppTextStyles.h2.copyWith(color: Colors.white)),
      ),
      body: SafeArea(
        child: _loadingOptions
            ? const Padding(
                padding: EdgeInsets.all(AppSpacing.page),
                child: SalaryRuleListShimmer(),
              )
            : _loadError != null
                ? _buildError()
                : _buildForm(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_loadError ?? 'Something went wrong', style: AppTextStyles.body, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.verticalMedium),
            ElevatedButton(onPressed: _loadOptions, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionTitle('Branch'),
            MultiSelectField(
              label: 'Branch',
              icon: Icons.storefront_outlined,
              options: _branches.map((b) => MultiSelectOption(id: b.id, label: b.name)).toList(),
              selectedIds: _selectedBranchIds,
              onChanged: (ids) => setState(() => _selectedBranchIds = ids),
              emptyHint: 'All branches',
              sheetTitle: 'Select Branch(es)',
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            _sectionTitle('Generate payslip for all employees?'),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.verticalMedium),
              child: SegmentedToggle(
                options: _yesNo,
                value: _generateForAll,
                onChanged: (val) => setState(() => _generateForAll = val),
              ),
            ),
            if (!_forAllEmployees) ...[
              MultiSelectField(
                label: 'Employees',
                icon: Icons.people_outline,
                options: _staff.map((s) => MultiSelectOption(id: s.id, label: s.fullName)).toList(),
                selectedIds: _selectedEmployeeIds,
                onChanged: (ids) => setState(() => _selectedEmployeeIds = ids),
                emptyHint: 'Tap to select employee(s)',
                sheetTitle: 'Select Employee(s)',
              ),
              const SizedBox(height: AppSpacing.verticalLarge),
            ],
            _sectionTitle('Month / Year'),
            JargonDropdown(
              label: 'Month / Year',
              value: _selectedMonthYear.label,
              icon: Icons.calendar_month_outlined,
              options: _monthYearOptions.map((o) => o.label).toList(),
              onChanged: (label) {
                final match = _monthYearOptions.where((o) => o.label == label);
                if (match.isNotEmpty) setState(() => _selectedMonthYear = match.first);
              },
            ),
            const SizedBox(height: AppSpacing.verticalLarge * 1.5),
            SlideActionButton(
              label: 'Slide to Generate',
              submitting: _isSaving,
              onSlide: _generate,
            ),
            const SizedBox(height: AppSpacing.verticalMedium),
          ],
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

class _MonthYearOption {
  final int month;
  final int year;
  final String label;

  _MonthYearOption(this.month, this.year, this.label);
}
