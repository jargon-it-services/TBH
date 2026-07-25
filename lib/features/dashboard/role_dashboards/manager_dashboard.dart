import 'package:flutter/material.dart';

import '../../../core/connectivity/connectivity_aware_refresh.dart';
import '../../../core/network/apis/dashboard_api.dart';
import '../../../core/services/DataModels/dashboard_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/widgets/shimmers/dashboard_shimmer.dart';
import 'account_admin_dashboard.dart'
    show
        DashboardAlertData,
        DashboardBodyErrorView,
        DashboardKpiData,
        DashboardPeriod,
        DashboardPeriodX,
        DashboardPeriodSelector,
        KpiSection,
        importantAlertsSection;

/// Dashboard content shown to a [UserRole.manager] user.
///
/// Deliberately a subset of [AccountAdminDashboard] / [BranchAdminDashboard]
/// — Important Alerts, Period Selector and the KPI section only, per this
/// task's role behaviour (no Business Summary, Revenue Trend or Revenue
/// Contribution for Manager). Reuses the exact same shared building
/// blocks as the admin dashboards rather than a parallel implementation.
class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard>
    with ConnectivityAwareRefresh<ManagerDashboard> {
  final DashboardApi _api = DashboardApi();

  bool _loading = true;
  String? _error;
  bool _isConnectivityError = false;
  DashboardData? _data;

  DashboardPeriod _period = DashboardPeriod.thisMonth;

  @override
  void initState() {
    super.initState();
    _load();
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
      setState(() {
        _data = result.data!.data;
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

  void _onPeriodChanged(DashboardPeriod period) {
    setState(() => _period = period);
    _load(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const DashboardShimmer();

    if (_error != null) {
      return DashboardBodyErrorView(
        message: _error!,
        isConnectivityError: _isConnectivityError,
        onRetry: _load,
      );
    }

    final data = _data;
    if (data == null) return const DashboardShimmer();

    return RefreshIndicator(
      onRefresh: () => _load(silent: true),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            importantAlertsSection(const <DashboardAlertData>[]),
            const SizedBox(height: AppSpacing.verticalSmall),
            DashboardPeriodSelector(
              value: _period,
              onChanged: _onPeriodChanged,
            ),
            const SizedBox(height: AppSpacing.verticalMedium),
            KpiSection(
              data: DashboardKpiData.fromDashboardData(data),
              period: _period,
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
          ],
        ),
      ),
    );
  }
}
