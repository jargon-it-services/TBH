import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../features/firms/firm_detail_page.dart';
import '../../../features/firms/firms_list_page.dart';

import '../../core/connectivity/connectivity_service.dart';
import '../../core/network/apis/dashboard_api.dart';
import '../../core/services/DataModels/dashboard_models.dart';
import '../../core/services/currency_utils.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/alert_slider.dart';
import '../../core/widgets/business_summary_card.dart';
import '../../core/widgets/insights_cards.dart';
import '../../core/widgets/jargon_dropdown.dart';
import '../../core/widgets/no_internet_page.dart';
import '../../core/widgets/revenue_trend_chart.dart';
import '../../core/widgets/shimmers/dashboard_shimmer.dart';
import '../subscriptions/razorpay_service.dart';
import '../subscriptions/subscription_controller.dart';
import '../subscriptions/subscription_plans_page.dart';

/// ===============================
/// IMPORTANT DASHBOARD ALERTS
/// ===============================
enum AlertType { info, warning, error, success }

class DashboardAlert {
  final AlertType type;
  final String title;
  final String message;
  final String? ctaLabel;
  final VoidCallback? onCtaTap;

  DashboardAlert({
    required this.type,
    required this.title,
    required this.message,
    this.ctaLabel,
    this.onCtaTap,
  });
}

Color _alertBg(AlertType type) {
  switch (type) {
    case AlertType.error:
      return AppColors.error.withOpacity(0.08);
    case AlertType.warning:
      return AppColors.warning.withOpacity(0.10);
    case AlertType.success:
      return AppColors.success.withOpacity(0.08);
    case AlertType.info:
    default:
      return AppColors.primary.withOpacity(0.08);
  }
}

Color _alertColor(AlertType type) {
  switch (type) {
    case AlertType.error:
      return AppColors.error;
    case AlertType.warning:
      return AppColors.warning;
    case AlertType.success:
      return AppColors.success;
    case AlertType.info:
    default:
      return AppColors.primary;
  }
}

IconData _alertIcon(AlertType type) {
  switch (type) {
    case AlertType.error:
      return Icons.error_outline;
    case AlertType.warning:
      return Icons.warning_amber_rounded;
    case AlertType.success:
      return Icons.check_circle_outline;
    case AlertType.info:
    default:
      return Icons.info_outline;
  }
}

class DashboardAlertCard extends StatelessWidget {
  final DashboardAlert alert;

  const DashboardAlertCard({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = _alertColor(alert.type);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.page),
      decoration: BoxDecoration(
        color: _alertBg(alert.type),
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_alertIcon(alert.type), color: color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(alert.message, style: AppTextStyles.bodySmall),
                if (alert.ctaLabel != null && alert.onCtaTap != null) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: alert.onCtaTap,
                    child: Text(alert.ctaLabel!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardAdmin extends StatefulWidget {
  const DashboardAdmin({super.key});

  @override
  State<DashboardAdmin> createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin> {
  final DashboardApi _api = DashboardApi();

  final RazorpayService _razorpayService = RazorpayService();
  final SubscriptionController _subscriptionController =
      SubscriptionController();

  bool _loading = true;
  String? _error;
  bool _isConnectivityError = false;
  StreamSubscription<bool>? _connectivitySubscription;

  List<FirmModel> firms = [];
  List<StaffModel> staffs = [];
  List<String> periods = [];
  List<ServiceModel> services = [];

  // 🔽 Firm selector (UI only – wired for the new dropdown)
  List<String> firmsNames = ["All Firms"];

  final PageController _firmController = PageController(viewportFraction: 0.9);
  final PageController _staffController = PageController(viewportFraction: 0.9);
  int _currentFirmIndex = 0;
  int _currentStaffIndex = 0;

  // 🔽 Firm selector (UI only – wired for the new dropdown)
  String selectedFirm = "All Firms";
  String selectedPeriod = "Monthly";

  List<TrendPoint> revenueTrend = [];
  bool hasPrevTrend = false;
  bool hasNextTrend = false;
  String? prevCursor;
  String? nextCursor;
  bool _loadingTrend = false;

  int totalFirmsCount = 0;
  int totalStaffCount = 0;
  int totalServicesCount = 0;

  final List<Color> _pieColors = [
    const Color(0xFF4CAF50),
    const Color(0xFF2196F3),
    const Color(0xFFFF9800),
    const Color(0xFFE91E63),
    const Color(0xFF9C27B0),
    const Color(0xFF00BCD4),
    const Color(0xFF8BC34A),
    const Color(0xFFFF5722),
  ];

  Color _getPieColor(int index) {
    return _pieColors[index % _pieColors.length];
  }

  double get totalRevenue => firms.fold(0.0, (sum, s) => sum + s.revenue);

  double get totalTransactions =>
      firms.fold(0.0, (sum, s) => sum + s.transactions);

  FirmModel? get topFirm => firms.isEmpty
      ? null
      : firms.reduce((a, b) => a.revenue > b.revenue ? a : b);

  List<StaffModel> get underPerformingStaff =>
      staffs.where((s) => !s.positive || s.revenue == 0).toList();

  ServiceModel? get topService => services.isEmpty
      ? null
      : services.reduce((a, b) => a.revenue > b.revenue ? a : b);

  @override
  void initState() {
    super.initState();
    _loadDashboard();

    // Back-online auto-refresh: only re-fetch if the last attempt
    // actually failed (i.e. there's stale/missing data to recover).
    // Reconnecting while the dashboard is already showing valid data
    // should NOT trigger another fetch — that would spend an API call
    // for no benefit, which matters given the Free Tier constraint.
    _connectivitySubscription = ConnectivityService.instance.onStatusChange
        .listen((isOnline) {
          if (isOnline && _error != null && mounted) {
            _loadDashboard();
          }
        });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
      _isConnectivityError = false;
    });

    final result = await _api.fetchAdminDashboard();
    if (!mounted) return;

    if (result.isSuccess) {
      final data = result.data!.data;
      final trend = data.overviewTrend;
      final meta = data.meta;

      setState(() {
        revenueTrend = trend?.points ?? [];
        hasPrevTrend = trend?.prevCursor != null;
        hasNextTrend = trend?.nextCursor != null;
        prevCursor = trend?.prevCursor;
        nextCursor = trend?.nextCursor;

        totalFirmsCount = meta.counts.totalFirms;
        totalStaffCount = meta.counts.totalStaff;
        totalServicesCount = meta.counts.totalServices;

        firms = data.firms;
        staffs = data.staff;
        services = data.services;
        periods = data.meta.periods;
        firmsNames = ["All Firms", ...firms.map((e) => e.name)];

        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
        _error = result.error;
        _isConnectivityError = result.isConnectivityError;
      });
    }
  }

  Future<void> _loadTrend({String? cursor, required bool isNext}) async {
    if (_loadingTrend) return;
    setState(() => _loadingTrend = true);

    final result = await _api.fetchRevenueTrend(
      period: selectedPeriod,
      cursor: cursor,
      isNext: isNext,
    );
    if (!mounted) return;

    if (result.isSuccess) {
      final trend = result.data!;
      setState(() {
        revenueTrend = trend.points;
        hasPrevTrend = trend.prevCursor != null;
        hasNextTrend = trend.nextCursor != null;
        prevCursor = trend.prevCursor;
        nextCursor = trend.nextCursor;
      });
    }

    setState(() => _loadingTrend = false);
  }

  Widget _revenueTrendChart() {
    return RevenueTrendChart(
      revenueTrend: revenueTrend
          .map((e) => RevenueTrendData(label: e.label, value: e.value))
          .toList(),
      hasPrevTrend: hasPrevTrend,
      hasNextTrend: hasNextTrend,
      loading: _loadingTrend,
      prevCursor: prevCursor,
      nextCursor: nextCursor,
      onLoadTrend: ({String? cursor, bool isNext = false}) {
        _loadTrend(cursor: cursor, isNext: isNext);
      },
      periodLabel: periodLabel,
    );
  }

  Widget errorView() {
    if (_isConnectivityError) {
      return NoInternetPage(onRetry: _loadDashboard);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: AppSpacing.verticalSmall),
            Text(
              _error ??
                  "Oops! We couldn't load the dashboard. Please try again.",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.verticalMedium),
            ElevatedButton.icon(
              onPressed: _loadDashboard,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text("Retry", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String periodLabel(String period) {
    switch (period.toLowerCase()) {
      case "daily":
        return "day";
      case "weekly":
        return "week";
      case "monthly":
        return "month";
      case "yearly":
        return "year";
      default:
        return period.toLowerCase();
    }
  }

  Widget _businessSummaryCard() {
    return BusinessSummaryCard(
      periodLabel: periodLabel(selectedPeriod),
      items: [
        SummaryItem(
          title: "Total Revenue",
          value: CurrencyUtils.format(totalRevenue),
          icon: Icons.currency_rupee,
        ),
        SummaryItem(
          title: "Total Transactions",
          value: totalTransactions.toStringAsFixed(0),
          icon: Icons.receipt_long,
        ),
        if (topFirm != null)
          SummaryItem(
            title: "Top Firm",
            value:
                "${topFirm!.name} (${CurrencyUtils.format(topFirm!.revenue)})",
            icon: Icons.storefront,
            onTap: () {
              // Navigate to firm details
            },
          ),
        if (topService != null)
          SummaryItem(
            title: "Top Service",
            value:
                "${topService!.name} (${CurrencyUtils.format(topService!.revenue)})",
            icon: Icons.design_services_outlined,
            onTap: () {
              // Navigate to service details
            },
          ),
      ],
    );
  }

  Widget _summaryRow(
    String title,
    String value,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    final rowContent = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),

        /// Title
        Expanded(
          flex: 3,
          child: Text(
            title,
            style: AppTextStyles.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        /// Value
        Expanded(
          flex: 4,
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 3,
            softWrap: true,
            overflow: TextOverflow.visible,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
          ),
        ),

        if (onTap != null) ...[
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right,
            size: 18,
            color: AppColors.textSecondary,
          ),
        ],
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.small),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: rowContent,
            )
          : rowContent,
    );
  }

  Widget _revenueContributionChart() {
    if (firms.isEmpty || totalRevenue == 0) {
      return const AnimatedEmptyState(
        icon: Icons.pie_chart_outline,
        title: "No Revenue Split Available",
        message: "Revenue contribution will appear once sales are recorded.",
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.page),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart, color: AppColors.primary),
              SizedBox(width: AppSpacing.horizontalSmall),
              Text("Revenue Contribution", style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: AppSpacing.verticalSmall),
          Text(
            "This represents the current ${periodLabel(selectedPeriod)}'s contribution.",
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 35),

          /// PIE CHART
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 45,
                sectionsSpace: 2,
                sections: List.generate(firms.length, (index) {
                  final firm = firms[index];

                  return PieChartSectionData(
                    value: firm.revenue,
                    color: _getPieColor(index),
                    radius: 55,
                    showTitle: false, // ❌ no labels on chart
                  );
                }),
              ),
            ),
          ),

          const SizedBox(height: 16),

          /// LEGEND
          Column(
            children: List.generate(firms.length, (index) {
              final firm = firms[index];
              final percent = (firm.revenue / totalRevenue) * 100;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      height: 10,
                      width: 10,
                      decoration: BoxDecoration(
                        color: _getPieColor(index),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        firm.name,
                        style: AppTextStyles.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      "${percent.toStringAsFixed(1)}%",
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _quickActionsRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.verticalMedium),
      child: Row(
        children: [
          _quickActionItem(
            icon: Icons.people_outline,
            emptyIcon: Icons.person_add_alt_1,
            label: "Staff",
            emptyLabel: "Add Staff",
            count: staffs.length,
            onTap: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (_) => const StaffScreen()),
              // );
            },
          ),
          _quickActionItem(
            icon: Icons.storefront_outlined,
            emptyIcon: Icons.add_business,
            label: "Firms",
            emptyLabel: "Add Firm",
            count: firms.length,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FirmListPage()),
              );
            },
          ),
          _quickActionItem(
            icon: Icons.content_cut_outlined,
            emptyIcon: Icons.add_circle_outline,
            label: "Services",
            emptyLabel: "Add Service",
            count: services.length, // replace when API ready
            onTap: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (_) => const ServicesScreen()),
              // );
            },
          ),
        ],
      ),
    );
  }

  Widget _quickActionItem({
    required IconData icon,
    required IconData emptyIcon,
    required String label,
    required String emptyLabel,
    int? count,
    required VoidCallback onTap,
  }) {
    final bool isEmpty = (count ?? 0) == 0;

    String? badgeText;
    if (count != null && count > 0) {
      badgeText = count > 99 ? "99+" : count.toString();
    }

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Icon(
                    isEmpty ? emptyIcon : icon,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),

                /// 🔴 Badge (1–99 / 99+)
                if (badgeText != null)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badgeText,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isEmpty ? emptyLabel : label,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔔 IMPORTANT SYSTEM ALERTS (Later from API)
  List<DashboardAlert> get dashboardAlerts => [
    DashboardAlert(
      type: AlertType.warning,
      title: "Trial Ending Soon",
      message:
          "Your trial will end in 2 days. Subscribe now to avoid interruption.",
      ctaLabel: "Subscribe Now",
      onCtaTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SubscriptionPlansPage()),
        );
      },
    ),
    DashboardAlert(
      type: AlertType.error,
      title: "Subscription Expired",
      message:
          "Your subscription has expired. Please renew to continue using services.",
      ctaLabel: "Renew Subscription",
      onCtaTap: () {},
    ),
  ];

  Widget _importantAlertsSection() {
    return AlertSlider<DashboardAlert>(
      alerts: dashboardAlerts,
      itemBuilder: (_, alert) => DashboardAlertCard(alert: alert),
    );
  }

  /// ============================================
  /// 🔽 NEW: Top filter bar — Firm + Period selectors
  /// ============================================
  Widget _topFilterBar() {
    return Container(
      child: Row(
        children: [
          Expanded(
            child: JargonDropdown(
              label: "Select Firm",
              value: selectedFirm,
              icon: Icons.storefront_outlined,
              options: firmsNames,
              onChanged: (val) => setState(() => selectedFirm = val),
            ),
          ),
          const SizedBox(width: AppSpacing.horizontalSmall),
          const SizedBox(width: AppSpacing.horizontalSmall),
          Expanded(
            child: JargonDropdown(
              label: "Select Period",
              value: selectedPeriod,
              icon: Icons.calendar_today_rounded,
              options: periods,
              onChanged: (val) => setState(() => selectedPeriod = val),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget dashboardContent() {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _importantAlertsSection(),

            const SizedBox(height: AppSpacing.verticalLarge),

            _quickActionsRow(),
            const SizedBox(height: AppSpacing.verticalMedium),

            /// 🔽 Firm + Period filters now live together at the very top
            _topFilterBar(),

            _revenueTrendChart(),
            _businessSummaryCard(),
            _revenueContributionChart(),
            const SizedBox(height: AppSpacing.verticalSmall),
            _insightsSection(
              title: "Firm Insights",
              items: firms,
              isStaff: false,
              totalCount: totalFirmsCount,
              showTrophy: true,
            ),

            const SizedBox(height: AppSpacing.verticalLarge),
            const SizedBox(height: AppSpacing.verticalSmall),
            _insightsSection(
              title: "Individual Staff Insights",
              items: staffs,
              isStaff: true,
              totalCount: totalStaffCount,
              showTrophy: true,
            ),

            const SizedBox(height: AppSpacing.verticalLarge),

            _insightsSection(
              title: "Service Insights",
              items: services,
              isStaff: false,
              totalCount: totalServicesCount,
              showTrophy: true,
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            const SizedBox(height: AppSpacing.verticalLarge),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: AppColors.primary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(AppRadius.large),
          ),
        ),
        centerTitle: true,
        title: Text(
          "Dashboard",
          style: AppTextStyles.h2.copyWith(color: Colors.white),
        ),

        /// 🔔 Notification Icon
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              // TODO: Navigate to Notifications screen
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const DashboardShimmer()
            : (_error != null ? errorView() : dashboardContent()),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 0.0),
        child: FloatingActionButton(
          onPressed: () {},
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _insightsSection({
    required String title,
    required List items,
    required bool isStaff,
    required int totalCount,
    required bool showTrophy,
  }) {
    /// 🚫 No data
    if (items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(title, showViewAll: false),
          const SizedBox(height: AppSpacing.verticalSmall),
          AnimatedEmptyState(
            icon: isStaff ? Icons.people_outline : Icons.storefront_outlined,
            title: isStaff ? "No Data Available" : "No Data Available",
            message: isStaff
                ? "Add staff to start tracking performance."
                : "Add items to start tracking insights.",
            ctaLabel: isStaff ? "Add Staff" : "Add",
            onCtaTap: () {},
            height: 180,
          ),
        ],
      );
    }

    final bool allZeroRevenue = items.every((e) => e.revenue == 0);
    final bool showViewAll = totalCount > 3;

    final visibleItems = items.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(title, showViewAll: showViewAll),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(AppSpacing.horizontalSmall),
          child: Text(
            allZeroRevenue
                ? "No revenue recorded for the selected ${periodLabel(selectedPeriod)}."
                : "The top three insights for the current ${periodLabel(selectedPeriod)} are listed below. Click “View All” to view additional insights, if applicable.",
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.verticalMedium),

        /// 🟢 Vertical cards
        ListView.separated(
          itemCount: visibleItems.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppSpacing.verticalLarge),
          itemBuilder: (context, index) {
            final item = visibleItems[index];

            final String description = isStaff
                ? item.firmName
                : item is FirmModel
                ? item.description
                : item.firmName;

            return InsightsCard(
              name: item.name,
              description: description,
              revenue: CurrencyUtils.format(item.revenue),
              transactions: item.transactions.toString(),
              percent: "${item.percent.abs().toStringAsFixed(1)}%",
              positive: item.percent >= 0,
              onViewDetails: () {
                if (isStaff) {
                  print("Krush");
                  // Navigate to Staff Detail Page
                } else if (item is FirmModel) {
                  // Navigate to Firm Detail Page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FirmDetailPage(firmId: item.id),
                    ),
                  );
                } else if (item is ServiceModel) {
                  print("Krush 2");
                  // Navigate to Service Detail Page
                }
              },
              showTrophy: showTrophy,
            );
          },
        ),
      ],
    );
  }
}

Widget _sectionHeader(String title, {required bool showViewAll}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(
        children: [
          const Icon(Icons.auto_graph, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(title, style: AppTextStyles.h3),
        ],
      ),
      if (showViewAll)
        TextButton(
          onPressed: () {
            // TODO: Navigate to full list screen
          },
          child: const Text(
            "View All",
            style: TextStyle(color: AppColors.primary),
          ),
        ),
    ],
  );
}

/// ------------------------------
/// Insights Card
/// ------------------------------

class AnimatedEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? ctaLabel;
  final VoidCallback? onCtaTap;
  final double height;

  const AnimatedEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.ctaLabel,
    this.onCtaTap,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.page,
              AppSpacing.page,
              AppSpacing.verticalMedium, // 👈 prevents overflow
            ),
            child: Column(
              children: [
                /// Illustration Circle
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.08),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 28),
                ),
                const SizedBox(height: 10),

                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
