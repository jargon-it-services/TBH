import 'package:flutter/material.dart';

import '../../core/connectivity/connectivity_aware_refresh.dart';
import '../../core/models/user_role.dart';
import '../../core/network/apis/dashboard_api.dart';
import '../../core/services/DataModels/dashboard_models.dart';
import '../../core/session/session_manager.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/shimmers/dashboard_shimmer.dart';
import 'dashboard_dynamic_body.dart';
import 'dashboard_registry.dart';
import 'widgets/dashboard_shared_widgets.dart';
import 'widgets/dashboard_sticky_header.dart';
import 'widgets/merged_dashboard_header.dart';

/// The "Dashboard" bottom-nav tab.
///
/// Branches once, by role:
///  - Super Admin keeps the pre-existing, untouched flow: its own
///    header fetch inside [DashboardStickyHeader], plus its own
///    (placeholder) body content from [DashboardRegistry]. Nothing
///    about that path changed by this merge.
///  - Every other role (Account Admin, Branch Admin, Manager,
///    Employee) now shares a single merged `/dashboard` fetch, owned
///    here: its `dashboard_header` slice feeds [MergedDashboardHeader]
///    and its remaining sections feed [DashboardDynamicBody] -- one
///    request driving both the header and the body, instead of the
///    two independent fetches each used to make.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with ConnectivityAwareRefresh<DashboardPage> {
  final DashboardApi _api = DashboardApi();

  bool _loading = true;
  String? _error;
  bool _isConnectivityError = false;
  DashboardData? _data;
  String? _selectedPeriodKey;

  UserRole get _role => SessionManager.instance.role;
  bool get _isSuperAdmin => _role == UserRole.superAdmin;

  @override
  void initState() {
    super.initState();
    // Super Admin doesn't use the merged endpoint at all -- its own
    // DashboardStickyHeader does its own independent fetch, untouched.
    if (!_isSuperAdmin) _load();
  }

  @override
  Future<void> onReconnected() => _load(silent: true);

  Future<void> _load({bool silent = false}) async {
    setState(() {
      if (!silent && _data == null) _loading = true;
      _error = null;
    });

    final result = await _api.fetchAdminDashboard();
    if (!mounted) return;

    lastLoadFailedDueToConnectivity =
        !result.isSuccess && result.isConnectivityError;

    if (result.isSuccess && result.data != null) {
      final data = result.data!.data;
      setState(() {
        _data = data;
        // Keep whatever period the user already has selected across a
        // silent refresh; only default from the response the very
        // first time.
        _selectedPeriodKey ??= data.meta.selectedPeriod.isNotEmpty
            ? data.meta.selectedPeriod
            : (data.meta.periods.isNotEmpty
                ? data.meta.periods.first.key
                : null);
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
        if (_data == null) {
          _error = result.error ?? "Oops! We couldn't load the dashboard.";
          _isConnectivityError = result.isConnectivityError;
        }
      });
    }
  }

  void _onPeriodChanged(String periodKey) {
    setState(() => _selectedPeriodKey = periodKey);
    _load(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuperAdmin) {
      // Fully unchanged: Super Admin keeps its own separate header
      // fetch and dashboard content, untouched by this merge.
      return Scaffold(
        backgroundColor: AppColors.pageBackground,
        appBar: const DashboardStickyHeader(),
        body: SafeArea(child: DashboardRegistry.contentFor(context)),
      );
    }

    final data = _data;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: MergedDashboardHeader(
        headerData: data?.dashboardHeader,
        loading: _loading,
        error: _error,
        isOffline: _isConnectivityError,
        onRetry: _load,
      ),
      body: SafeArea(child: _buildBody(data)),
    );
  }

  Widget _buildBody(DashboardData? data) {
    if (_loading && data == null) return const DashboardShimmer();

    if (_error != null && data == null) {
      return DashboardBodyErrorView(
        message: _error!,
        isConnectivityError: _isConnectivityError,
        onRetry: _load,
      );
    }

    if (data == null) return const DashboardShimmer();

    return DashboardDynamicBody(
      data: data,
      selectedPeriodKey: _selectedPeriodKey ?? data.meta.selectedPeriod,
      onPeriodChanged: _onPeriodChanged,
      onRefresh: () => _load(silent: true),
    );
  }
}
