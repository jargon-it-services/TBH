import 'dart:math';

import 'package:action_slider/action_slider.dart';
import 'package:flutter/material.dart';

import '../../core/network/api_response.dart';
import '../../core/network/apis/transaction_api.dart';
import '../../core/services/DataModels/transaction_details_model.dart';
import '../../core/services/DataModels/transaction_entry_models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/jargon_dropdown.dart';
import '../../core/widgets/network_state_view.dart';
import '../../core/widgets/segmented_toggle.dart';
import '../../core/widgets/slide_action_button.dart';
import 'transaction_details_page.dart';
import 'widgets/selected_service_card.dart';
import 'widgets/service_picker_sheet.dart';

/// POS-style Transaction Entry — one screen, two flows:
///
/// - **Create** (default): [existingTransactionId]/[existingDetails]
///   both null. On success, resets in place (see [_resetInPlace]) so a
///   staff member can process the next transaction immediately — per
///   the spec, this screen intentionally does NOT navigate to the list
///   after a create.
/// - **Edit**: pass [existingTransactionId] (and, when available,
///   [existingDetails] — the object `TransactionDetailsPage` already
///   fetched, so this screen doesn't re-fetch it) to pre-fill and
///   switch every save action to `PUT` instead of `POST`. On success,
///   navigates back to `TransactionDetailsPage` (an edit is a one-off
///   correction, not a rapid-fire flow).
///
/// Note on edit pre-fill: `TransactionDetails` (the existing read model
/// `TransactionDetailsPage` already uses) was built for *display*, not
/// as an editable draft — it has no `customer_name`/`customer_mobile`
/// and no numeric `branch_id` (only a display `firm{id,name,location}`
/// object with a String id in a different id-space than the
/// create/update contract's integer `branch_id`). Rather than guessing
/// a mapping, Edit pre-fills everything that *does* map cleanly
/// (services + qty, staff, payment mode, remark, transaction type) and
/// falls back to the same role-based Branch/Staff resolution Create
/// uses for the rest — correct for every role except Account Admin
/// editing a transaction originally logged at a different branch, who
/// will need to reselect it. Flagged here rather than silently
/// papered over.
class TransactionEntryPage extends StatefulWidget {
  final String? existingTransactionId;
  final TransactionDetails? existingDetails;

  const TransactionEntryPage({
    super.key,
    this.existingTransactionId,
    this.existingDetails,
  });

  bool get isEdit => existingTransactionId != null;

  @override
  State<TransactionEntryPage> createState() => _TransactionEntryPageState();
}

class _TransactionEntryPageState extends State<TransactionEntryPage> {
  final TransactionApi _api = TransactionApi();
  final _rng = Random.secure();

  bool _loadingBootstrap = true;
  String? _bootstrapError;
  bool _bootstrapOffline = false;
  TransactionBootstrapData? _bootstrap;

  late String _transactionType;

  // ---- Service mode ----
  List<SelectedServiceLine> _selectedServices = [];

  // ---- Expense mode ----
  int? _expenseId;
  String? _expenseName;
  String _expenseAmount = '';

  // ---- Customer (optional unless Pay Later) ----
  bool _customerExpanded = false;
  String _customerName = '';
  String _customerMobile = '';
  String? _customerNameError;
  String? _customerMobileError;

  // ---- Branch / Staff (role-based) ----
  int? _branchId;
  String? _branchName;
  bool _branchEditable = false;
  int? _staffId;
  String? _staffName;
  bool _staffEditable = false;

  // ---- Payment ----
  late String _paymentMode;

  // ---- More options ----
  bool _moreOptionsExpanded = false;
  String _remark = '';

  // ---- Timestamps & double-submit protection ----
  late DateTime _startTime;
  late String _idempotencyKey;

  bool _savingPaid = false;
  bool _savingPending = false;

  /// Bumped on every in-place reset after a successful create, and used
  /// as a Key on the field-bearing subtree below — [AppTextField] wraps
  /// an uncontrolled `TextFormField` that only reads `initialValue`
  /// once, so clearing local String state alone wouldn't refresh
  /// already-built fields; remounting the subtree does. Same fix as
  /// the Account Info City/State bug.
  int _resetGeneration = 0;

  bool get _isSaving => _savingPaid || _savingPending;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _idempotencyKey = _generateUuidV4();
    _loadBootstrap();
  }

  String _generateUuidV4() {
    final bytes = List<int>.generate(16, (_) => _rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;
    String hex(int start, int end) =>
        bytes.sublist(start, end).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }

  Future<void> _loadBootstrap() async {
    setState(() {
      _loadingBootstrap = true;
      _bootstrapError = null;
    });

    final response = await _api.fetchBootstrap();
    if (!mounted) return;

    if (!response.isSuccess || response.data == null) {
      setState(() {
        _loadingBootstrap = false;
        _bootstrapError = response.error ?? "We couldn't load transaction data right now.";
        _bootstrapOffline = response.isConnectivityError;
      });
      return;
    }

    final data = response.data!;
    setState(() {
      _bootstrap = data;
      _transactionType = widget.existingDetails?.type ?? data.lastTransactionType ?? 'service';
      _paymentMode = widget.existingDetails?.paymentMode ?? data.lastPaymentMode ?? 'cash';
      _resolveBranchAndStaff(data);
      if (widget.existingDetails != null) _prefillFromExisting(widget.existingDetails!, data);
      _loadingBootstrap = false;
    });
  }

  /// Employee/Manager/Branch Admin are always pinned to their own
  /// logged-in branch (read-only for Employee, changeable — but
  /// defaulted — for the other two); only Account Admin picks freely.
  /// Staff follows the identical rule. Matches the module spec's role
  /// table exactly; the app never hardcodes which roles get which
  /// behavior beyond these five string comparisons against whatever
  /// `user_role` the backend actually sends.
  void _resolveBranchAndStaff(TransactionBootstrapData data) {
    final role = data.userRole;
    final isAccountAdmin = role == 'account_admin';

    _branchEditable = isAccountAdmin;
    if (!isAccountAdmin) {
      _branchId = data.loggedInBranchId;
      final match = data.branches.where((b) => b.id == data.loggedInBranchId);
      _branchName = match.isNotEmpty ? match.first.name : null;
    }

    _staffEditable = role == 'manager' || role == 'branch_admin' || isAccountAdmin;
    if (role != 'account_admin') {
      // Employee/Manager/Branch Admin all *default* to the logged-in
      // user; only Employee can't then change it (handled by
      // _staffEditable, not by skipping the default here).
      _staffId = data.loggedInUserId;
      final match = data.staff.where((s) => s.id == data.loggedInUserId);
      _staffName = match.isNotEmpty ? match.first.name : null;
    }
  }

  void _prefillFromExisting(TransactionDetails existing, TransactionBootstrapData data) {
    _remark = existing.remark ?? '';

    final staffMatch = data.staff.where((s) => s.name == existing.staff.name);
    if (staffMatch.isNotEmpty) {
      _staffId = staffMatch.first.id;
      _staffName = staffMatch.first.name;
    }

    if (existing.type == 'service') {
      _selectedServices = existing.priceBreakdown.services.map((item) {
        final bootstrapMatch = data.services.where((s) => s.name == item.title);
        final unitPrice = bootstrapMatch.isNotEmpty
            ? bootstrapMatch.first.price
            : (item.quantity > 0 ? item.netAmount / item.quantity : item.netAmount).toDouble();
        final serviceId = bootstrapMatch.isNotEmpty ? bootstrapMatch.first.id : item.id;
        return SelectedServiceLine(
          serviceId: serviceId,
          name: item.title,
          price: unitPrice,
          qty: item.quantity,
        );
      }).toList();
    } else {
      _expenseName = existing.category;
      final expenseMatch = data.expenses.where((e) => e.name == existing.category);
      if (expenseMatch.isNotEmpty) _expenseId = expenseMatch.first.id;
      _expenseAmount = existing.priceBreakdown.summary.total.toStringAsFixed(0);
    }
  }

  double get _grandTotal {
    if (_transactionType == 'service') {
      return _selectedServices.fold(0.0, (sum, s) => sum + s.lineTotal);
    }
    return double.tryParse(_expenseAmount.trim()) ?? 0;
  }

  // ================= SERVICE SELECTION =================

  void _addOrIncrementService(BootstrapService service) {
    setState(() {
      final idx = _selectedServices.indexWhere((s) => s.serviceId == service.id);
      if (idx >= 0) {
        _selectedServices[idx].qty += 1;
      } else {
        _selectedServices.add(
          SelectedServiceLine(serviceId: service.id, name: service.name, price: service.price),
        );
      }
    });
  }

  Future<void> _openMoreServices() async {
    if (_bootstrap == null) return;
    final picked = await ServicePickerSheet.show(context, services: _bootstrap!.services);
    if (picked != null) _addOrIncrementService(picked);
  }

  // ================= VALIDATION =================

  String? _validateCommon() {
    if (_transactionType == 'service') {
      if (_selectedServices.isEmpty) return 'Select at least one service';
    } else {
      if (_expenseId == null) return 'Select an expense';
      if ((double.tryParse(_expenseAmount.trim()) ?? 0) <= 0) {
        return 'Enter a valid amount';
      }
    }
    if (_branchId == null) return 'Select a branch';
    if (_staffId == null) return 'Select a staff member';
    return null;
  }

  bool _validateCustomerForPayLater() {
    final nameError = _customerName.trim().isEmpty ? 'Required for Pay Later' : null;
    final mobile = _customerMobile.trim();
    final mobileError = mobile.isEmpty
        ? 'Required for Pay Later'
        : (!RegExp(r'^[0-9]{10}$').hasMatch(mobile) ? 'Enter a valid 10-digit number' : null);

    setState(() {
      _customerNameError = nameError;
      _customerMobileError = mobileError;
      if (nameError != null || mobileError != null) _customerExpanded = true;
    });

    return nameError == null && mobileError == null;
  }

  // ================= SAVE =================

  Future<void> _performSave(String status) async {
    if (_isSaving) return;

    final commonError = _validateCommon();
    if (commonError != null) {
      AppSnackbar.warning(context, commonError);
      return;
    }
    if (status == 'pending' && !_validateCustomerForPayLater()) {
      AppSnackbar.warning(
        context,
        'Customer Name and Mobile Number are required for Pay Later',
      );
      return;
    }

    setState(() {
      if (status == 'paid') {
        _savingPaid = true;
      } else {
        _savingPending = true;
      }
    });

    final endTime = DateTime.now();
    final duration = endTime.difference(_startTime).inMinutes;
    final payload = _buildPayload(status: status, endTime: endTime, duration: duration);

    final ApiResponse<TransactionSaveResult> response = widget.isEdit
        ? await _api.updateTransaction(widget.existingTransactionId!, payload)
        : await _api.createTransaction(payload);

    if (!mounted) return;
    setState(() {
      _savingPaid = false;
      _savingPending = false;
    });

    if (response.isSuccess && response.data != null) {
      _handleSaveSuccess(response.data!);
    } else {
      _handleSaveFailure(response, status);
    }
  }

  Map<String, dynamic> _buildPayload({
    required String status,
    required DateTime endTime,
    required int duration,
  }) {
    final hasCustomer = _customerExpanded &&
        (_customerName.trim().isNotEmpty || _customerMobile.trim().isNotEmpty);

    return {
      if (!widget.isEdit) 'idempotency_key': _idempotencyKey,
      'transaction_type': _transactionType,
      'branch_id': _branchId,
      'staff_id': _staffId,
      'customer_name': hasCustomer && _customerName.trim().isNotEmpty
          ? _customerName.trim()
          : null,
      'customer_mobile': hasCustomer && _customerMobile.trim().isNotEmpty
          ? _customerMobile.trim()
          : null,
      'payment_mode': _paymentMode,
      'status': status,
      'transaction_datetime': _startTime.toUtc().toIso8601String(),
      'start_datetime': _startTime.toUtc().toIso8601String(),
      'end_datetime': endTime.toUtc().toIso8601String(),
      'duration_minutes': duration,
      'remark': _remark.trim().isEmpty ? null : _remark.trim(),
      if (_transactionType == 'service')
        'services': _selectedServices
            .map((s) => {'service_id': s.serviceId, 'qty': s.qty})
            .toList()
      else ...{
        'expense_id': _expenseId,
        'amount': double.tryParse(_expenseAmount.trim()) ?? 0,
      },
    };
  }

  void _handleSaveSuccess(TransactionSaveResult result) {
    if (widget.isEdit) {
      AppSnackbar.success(context, 'Transaction updated successfully');
      Navigator.pop(context, true);
      return;
    }

    final amountLabel = '₹${result.grandTotal.toStringAsFixed(0)}';
    final message = result.status == 'paid'
        ? '$amountLabel · Paid'
        : '$amountLabel · Pending'
            '${result.customerName != null ? ' — ${result.customerName}, ${result.customerMobile ?? ''}' : ''}';

    AppSnackbar.success(
      context,
      message,
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'View',
        textColor: Colors.white,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TransactionDetailsPage(transactionId: result.id)),
        ),
      ),
    );

    _resetInPlace();
  }

  void _handleSaveFailure(ApiResponse<TransactionSaveResult> response, String status) {
    // 409 = the edit window closed server-side since this screen
    // opened (see TransactionApi.updateTransaction) — distinct from a
    // network/validation failure: retrying the identical request will
    // never succeed, so no Retry action is offered for this one. Data
    // stays on screen either way — nothing is ever discarded.
    if (response.statusCode == 409) {
      AppSnackbar.error(
        context,
        response.error ?? 'This transaction can no longer be edited.',
        duration: const Duration(seconds: 6),
      );
      return;
    }

    AppSnackbar.show(
      context,
      response.error ?? 'Something went wrong. Please try again.',
      type: AppSnackbarType.error,
      duration: const Duration(seconds: 6),
      action: SnackBarAction(
        label: 'Retry',
        textColor: Colors.white,
        onPressed: () => _performSave(status),
      ),
    );
  }

  /// Only fields spec'd to actually reset — Branch/Staff (role
  /// defaults) and Payment Mode (already spec'd to remember the
  /// last-used value) deliberately survive a reset, since they rarely
  /// change customer-to-customer.
  void _resetInPlace() {
    setState(() {
      _selectedServices = [];
      _expenseId = null;
      _expenseName = null;
      _expenseAmount = '';
      _customerExpanded = false;
      _customerName = '';
      _customerMobile = '';
      _customerNameError = null;
      _customerMobileError = null;
      _remark = '';
      _moreOptionsExpanded = false;
      _startTime = DateTime.now();
      _idempotencyKey = _generateUuidV4();
      _resetGeneration++;
    });
  }

  // ================= BACK-OUT CONFIRMATION =================

  bool get _hasUnsavedData =>
      _selectedServices.isNotEmpty ||
      _expenseAmount.trim().isNotEmpty ||
      _customerName.trim().isNotEmpty ||
      _customerMobile.trim().isNotEmpty ||
      _remark.trim().isNotEmpty;

  Future<bool> _confirmDiscard() async {
    if (!_hasUnsavedData) return true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.pageBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.large)),
        title: const Text('Discard this transaction?', style: AppTextStyles.h3),
        content: const Text(
          "You'll lose everything entered on this screen. This transaction was never saved.",
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep Editing')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _confirmDiscard,
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        appBar: AppBar(
          title: Text(
            widget.isEdit ? 'Edit Transaction' : 'New Transaction',
            style: AppTextStyles.h2.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.primary,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              if (await _confirmDiscard()) {
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ),
        body: SafeArea(child: _body()),
      ),
    );
  }

  Widget _body() {
    if (_loadingBootstrap) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_bootstrapError != null || _bootstrap == null) {
      return NetworkStateView(
        isOffline: _bootstrapOffline,
        message: _bootstrapError,
        onRetry: _loadBootstrap,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        key: ValueKey('entry-form-$_resetGeneration'),
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedToggle(
              options: const ['Service', 'Expense'],
              value: _transactionType == 'service' ? 'Service' : 'Expense',
              onChanged: (v) =>
                  setState(() => _transactionType = v == 'Service' ? 'service' : 'expense'),
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            if (_transactionType == 'service') ..._serviceSection() else ..._expenseSection(),
            const SizedBox(height: AppSpacing.verticalLarge),
            _grandTotalCard(),
            const SizedBox(height: AppSpacing.verticalLarge),
            _sectionTitle('Payment'),
            SegmentedToggle(
              options: const ['Cash', 'UPI', 'Card'],
              value: _paymentModeLabel(_paymentMode),
              onChanged: (v) => setState(() => _paymentMode = v.toLowerCase()),
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            _branchAndStaffSection(),
            const SizedBox(height: AppSpacing.verticalLarge),
            _customerSection(),
            const SizedBox(height: AppSpacing.verticalLarge),
            _moreOptionsSection(),
            const SizedBox(height: AppSpacing.verticalLarge),
            _saveSliders(),
            const SizedBox(height: AppSpacing.verticalMedium),
          ],
        ),
      ),
    );
  }

  String _paymentModeLabel(String mode) => switch (mode) {
        'upi' => 'UPI',
        'card' => 'Card',
        _ => 'Cash',
      };

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.verticalMedium),
      child: Text(
        text,
        style: AppTextStyles.h3.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
      ),
    );
  }

  // ---------------- SERVICE SECTION ----------------

  List<Widget> _serviceSection() {
    final frequent = _bootstrap!.services.where((s) => s.frequent).toList();
    return [
      _sectionTitle('Frequently Used Services'),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ...frequent.map((s) => _serviceChip(s)),
          ActionChip(
            avatar: const Icon(Icons.add, size: 16, color: AppColors.primary),
            label: const Text('More'),
            onPressed: _openMoreServices,
            backgroundColor: AppColors.primary.withOpacity(0.08),
            side: BorderSide.none,
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.verticalLarge),
      _sectionTitle('Selected Services'),
      if (_selectedServices.isEmpty)
        Text(
          'No services selected yet — tap a chip above to add one.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        )
      else
        ..._selectedServices.map(
          (line) => SelectedServiceCard(
            name: line.name,
            unitPrice: line.price,
            qty: line.qty,
            lineTotal: line.lineTotal,
            onIncrement: () => setState(() => line.qty += 1),
            onDecrement: () => setState(() => line.qty -= 1),
            onRemove: () => setState(
              () => _selectedServices.removeWhere((s) => s.serviceId == line.serviceId),
            ),
          ),
        ),
    ];
  }

  Widget _serviceChip(BootstrapService service) {
    final selected = _selectedServices.any((s) => s.serviceId == service.id);
    return ActionChip(
      label: Text(service.name),
      onPressed: () => _addOrIncrementService(service),
      backgroundColor: selected ? AppColors.primary.withOpacity(0.15) : AppColors.cardBackground,
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      labelStyle: AppTextStyles.bodySmall.copyWith(
        color: selected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
      ),
    );
  }

  // ---------------- EXPENSE SECTION ----------------

  List<Widget> _expenseSection() {
    return [
      _sectionTitle('Expense'),
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.verticalMedium),
        child: JargonDropdown(
          label: 'Expense',
          value: _expenseName ?? 'Select Expense',
          icon: Icons.receipt_long_outlined,
          options: _bootstrap!.expenses.map((e) => e.name).toList(),
          showLabel: true,
          onChanged: (name) {
            final match = _bootstrap!.expenses.firstWhere((e) => e.name == name);
            setState(() {
              _expenseId = match.id;
              _expenseName = match.name;
            });
          },
        ),
      ),
      AppTextField(
        label: 'Amount (₹)',
        icon: Icons.currency_rupee,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        initialValue: _expenseAmount,
        onChanged: (v) => setState(() => _expenseAmount = v),
      ),
    ];
  }

  // ---------------- GRAND TOTAL ----------------

  Widget _grandTotalCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Row(
        children: [
          Text('Grand Total', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(
            '₹${_grandTotal.toStringAsFixed(0)}',
            style: AppTextStyles.h3.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  // ---------------- BRANCH / STAFF ----------------

  Widget _branchAndStaffSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Branch & Staff'),
        _branchEditable
            ? Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.verticalMedium),
                child: JargonDropdown(
                  label: 'Branch',
                  value: _branchName ?? 'Select Branch',
                  icon: Icons.store_mall_directory_outlined,
                  options: _bootstrap!.branches.map((b) => b.name).toList(),
                  showLabel: true,
                  onChanged: (name) {
                    final match = _bootstrap!.branches.firstWhere((b) => b.name == name);
                    setState(() {
                      _branchId = match.id;
                      _branchName = match.name;
                    });
                  },
                ),
              )
            : AppTextField(
                label: 'Branch',
                icon: Icons.store_mall_directory_outlined,
                initialValue: _branchName ?? '',
                enabled: false,
                readOnly: true,
              ),
        _staffEditable
            ? JargonDropdown(
                label: 'Staff',
                value: _staffName ?? 'Select Staff',
                icon: Icons.badge_outlined,
                options: _bootstrap!.staff.map((s) => s.name).toList(),
                showLabel: true,
                onChanged: (name) {
                  final match = _bootstrap!.staff.firstWhere((s) => s.name == name);
                  setState(() {
                    _staffId = match.id;
                    _staffName = match.name;
                  });
                },
              )
            : AppTextField(
                label: 'Staff',
                icon: Icons.badge_outlined,
                initialValue: _staffName ?? '',
                enabled: false,
                readOnly: true,
              ),
      ],
    );
  }

  // ---------------- CUSTOMER ----------------

  Widget _customerSection() {
    if (!_customerExpanded) {
      return OutlinedButton.icon(
        onPressed: () => setState(() => _customerExpanded = true),
        icon: const Icon(Icons.person_add_alt_outlined, size: 18),
        label: const Text('Add Customer'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _sectionTitle('Customer (optional)')),
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
              onPressed: () => setState(() {
                _customerExpanded = false;
                _customerName = '';
                _customerMobile = '';
                _customerNameError = null;
                _customerMobileError = null;
              }),
            ),
          ],
        ),
        AppTextField(
          label: 'Customer Name',
          icon: Icons.person_outline,
          initialValue: _customerName,
          onChanged: (v) => setState(() {
            _customerName = v;
            _customerNameError = null;
          }),
        ),
        if (_customerNameError != null) _inlineError(_customerNameError!),
        AppTextField(
          label: 'Mobile Number',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          initialValue: _customerMobile,
          onChanged: (v) => setState(() {
            _customerMobile = v;
            _customerMobileError = null;
          }),
        ),
        if (_customerMobileError != null) _inlineError(_customerMobileError!),
      ],
    );
  }

  Widget _inlineError(String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4, top: 0),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 13, color: AppColors.error),
          const SizedBox(width: 4),
          Expanded(
            child: Text(message, style: AppTextStyles.caption.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  // ---------------- MORE OPTIONS ----------------

  Widget _moreOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _moreOptionsExpanded = !_moreOptionsExpanded),
          child: Row(
            children: [
              Text('More Options', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              Icon(
                _moreOptionsExpanded ? Icons.expand_less : Icons.expand_more,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
        if (_moreOptionsExpanded) ...[
          const SizedBox(height: AppSpacing.verticalMedium),
          AppTextField(
            label: 'Remark (optional)',
            icon: Icons.notes_outlined,
            maxLines: 3,
            initialValue: _remark,
            onChanged: (v) => _remark = v,
          ),
        ],
      ],
    );
  }

  // ---------------- SAVE SLIDERS ----------------

  Widget _saveSliders() {
    return Column(
      children: [
        _slideRow(
          label: 'Slide to confirm · Paid',
          submitting: _savingPaid,
          disabled: _savingPending,
          onSlide: (_) => _performSave('paid'),
        ),
        const SizedBox(height: AppSpacing.verticalMedium),
        _slideRow(
          label: 'Slide to confirm · Pay later',
          submitting: _savingPending,
          disabled: _savingPaid,
          onSlide: (_) => _performSave('pending'),
        ),
      ],
    );
  }

  Widget _slideRow({
    required String label,
    required bool submitting,
    required bool disabled,
    required Future<void> Function(ActionSliderController) onSlide,
  }) {
    final slider = SlideActionButton(label: label, submitting: submitting, onSlide: onSlide);
    if (!disabled) return slider;
    return IgnorePointer(child: Opacity(opacity: 0.5, child: slider));
  }
}
