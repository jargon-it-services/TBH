import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/jargon_dropdown.dart';
import '../../core/widgets/revenue_trend_chart.dart' as chart;
import '../../core/network/apis/firms_api.dart';
import '../../core/services/DataModels/firm_detail_model.dart' as model;
import '../../core/widgets/business_summary_card.dart';
import '../../core/widgets/info_card.dart';
import '../../core/widgets/insights_cards.dart';
import '../../core/widgets/shimmers/firm_detail_shimmer.dart';

class FirmDetailPage extends StatefulWidget {
  final int firmId;

  const FirmDetailPage({super.key, required this.firmId});

  @override
  State<FirmDetailPage> createState() => _FirmDetailPageState();
}

class _FirmDetailPageState extends State<FirmDetailPage> {
  bool _loading = true;
  String? _error;
  final FirmsApi _api = FirmsApi();

  model.FirmDetailResponse? _data;
  String _selectedPeriod = "Monthly";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final response = await _api.fetchFirmDetail(widget.firmId);

    if (response.isSuccess && response.data != null) {
      setState(() {
        _data = response.data!;
        _selectedPeriod = _data!.overviewTrend.period;
        _loading = false;
      });
    } else {
      setState(() {
        _error = response.error ?? "Failed to load firm details";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Firm Details',
          style: AppTextStyles.h2.copyWith(color: Colors.white),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const FirmDetailShimmer();

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: AppTextStyles.body),
            const SizedBox(height: AppSpacing.verticalMedium),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final meta = _data!.meta;
    final trend = _data!.overviewTrend;

    // Calculate summary data dynamically
    final totalRevenue =
        _data!.firms.fold<double>(0, (sum, f) => sum + (f.revenue.toDouble()));
    final totalTransactions =
        _data!.firms.fold<int>(0, (sum, f) => sum + f.transactions);
    final topService = _data!.services.isNotEmpty
        ? _data!.services.reduce((a, b) => a.revenue > b.revenue ? a : b).name
        : "-";
    final topStaff = _data!.staff.isNotEmpty
        ? _data!.staff.reduce((a, b) => a.revenue > b.revenue ? a : b).name
        : "-";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.page),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _overviewCard(meta.firmInfo),
          const SizedBox(height: AppSpacing.verticalLarge),

          /// PERIOD DROPDOWN
          JargonDropdown(
            label: "Select Period",
            icon: Icons.calendar_today_rounded,
            value: _selectedPeriod,
            options: meta.periods,
            onChanged: (val) => setState(() => _selectedPeriod = val),
          ),

          const SizedBox(height: AppSpacing.verticalLarge),

          /// HEADER CARD
          InsightsCard(
              name: meta.firmInfo.name,
              description: meta.firmInfo.description,
              revenue: meta.firmInfo.revenue.toString(),
              transactions: meta.firmInfo.transactions.toString(),
              percent: "${meta.firmInfo.percent}%",
              positive: meta.firmInfo.percent >= 0,
              showTrophy: false,
              showViewDetailsButton: false),

          const SizedBox(height: AppSpacing.verticalLarge),

          /// TREND CHART
          chart.RevenueTrendChart(
            revenueTrend: trend.points
                .map((p) => chart.RevenueTrendData(
                      label: p.label,
                      value: p.value.toDouble(),
                    ))
                .toList(),
            hasPrevTrend: trend.prevCursor != null,
            hasNextTrend: trend.nextCursor != null,
            prevCursor: trend.prevCursor,
            nextCursor: trend.nextCursor,
            onLoadTrend: ({cursor, isNext = true}) {},
            periodLabel: (_) => trend.range,
          ),

          // const SizedBox(height: AppSpacing.verticalLarge),

          BusinessSummaryCard(
            periodLabel: _selectedPeriod,
            items: [
              SummaryItem(
                title: "Total Revenue",
                value: totalRevenue.toStringAsFixed(0),
                icon: Icons.currency_rupee,
              ),
              SummaryItem(
                title: "Transactions",
                value: totalTransactions.toString(),
                icon: Icons.receipt_long,
              ),
              SummaryItem(
                title: "Top Service",
                value: topService,
                icon: Icons.design_services_outlined,
              ),
              SummaryItem(
                title: "Top Staff",
                value: topStaff,
                icon: Icons.person,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.verticalLarge),

          /// STAFF
          Text("Top Staff", style: AppTextStyles.h3),
          const SizedBox(height: AppSpacing.verticalMedium),
          ..._data!.staff.map(_buildInsight).toList(),

          const SizedBox(height: AppSpacing.verticalLarge),

          /// SERVICES
          Text("Top Services", style: AppTextStyles.h3),
          const SizedBox(height: AppSpacing.verticalMedium),
          ..._data!.services.map(_buildInsight).toList(),
        ],
      ),
    );
  }

  Widget _overviewCard(model.FirmInfo info) {
    return InfoCard(
      title: "Firm Information",
      titleIcon: Icons.storefront_outlined,
      isAccordion: true,
      initiallyExpanded: false,
      rows: [
        InfoRowData(icon: Icons.tag, label: "GSTIN", value: info.gstin),
        InfoRowData(
            icon: Icons.app_registration,
            label: "Registration No",
            value: info.regNo),
        InfoRowData(
            icon: Icons.email_outlined, label: "Email", value: info.email),
        InfoRowData(
            icon: Icons.phone_iphone_outlined,
            label: "Contact",
            value: info.contact),
      ],
    );
  }

  Widget _buildInsight(model.InsightItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.verticalMedium),
      child: InsightsCard(
        name: item.name,
        description: item.firmName ?? '',
        revenue: item.revenue.toString(),
        transactions: item.transactions.toString(),
        percent: "${item.percent}%",
        positive: item.percent >= 0,
      ),
    );
  }
}
