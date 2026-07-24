import 'package:flutter/material.dart';
import '../../../features/firms/add_firm_page.dart';
import '../../../features/firms/firm_detail_page.dart';

import '../../core/connectivity/connectivity_aware_refresh.dart';
import '../../core/network/apis/firms_api.dart';
import '../../core/services/DataModels/firm_model.dart';
import '../../core/services/currency_utils.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/animated_empty_state.dart';
import '../../core/widgets/insights_cards.dart';
import '../../core/widgets/network_state_view.dart';
import '../../core/widgets/shimmers/firm_staff_service_list_shimmer.dart';

class FirmListPage extends StatefulWidget {
  const FirmListPage({super.key});

  @override
  State<FirmListPage> createState() => _FirmListPageState();
}

class _FirmListPageState extends State<FirmListPage>
    with ConnectivityAwareRefresh<FirmListPage> {
  final TextEditingController _searchController = TextEditingController();
  final FirmsApi _api = FirmsApi();

  bool _loading = true;
  String? _error;
  bool _isOffline = false;
  List<FirmModel> _firms = [];

  @override
  void initState() {
    super.initState();
    _loadFirms();
  }

  @override
  Future<void> onReconnected() => _loadFirms(silent: true);

  Future<void> _loadFirms({bool silent = false}) async {
    setState(() {
      // Only take over the whole screen with the loading shimmer when
      // there's nothing else to show yet. A silent reload (pull-to-
      // refresh has its own spinner; a reconnect-triggered retry should
      // be invisible if it succeeds) never touches this, and a manual
      // reload with data already on screen doesn't blank it out either.
      if (!silent && _firms.isEmpty) _loading = true;
      _error = null;
    });

    final response = await _api.fetchFirms();
    if (!mounted) return;

    lastLoadFailedDueToConnectivity =
        !response.isSuccess && response.isConnectivityError;

    if (response.isSuccess) {
      setState(() {
        _firms = response.data ?? [];
        _loading = false;
        _isOffline = false;
      });
    } else {
      setState(() {
        _loading = false;
        // State preservation: if firms are already showing, a failed
        // reload must not clear them — just leave the list as-is. The
        // app-wide ConnectivityBanner already tells the user they're
        // offline; a full-screen error state is only shown when there's
        // genuinely nothing else on screen to preserve.
        if (_firms.isEmpty) {
          _error =
              response.error ??
              "We couldn't load firms right now. Please try again.";
          _isOffline = response.isConnectivityError;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredFirms = _firms.where((firm) {
      return firm.name.toLowerCase().contains(
        _searchController.text.toLowerCase(),
      );
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: AppColors.primary,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Firms",
          style: AppTextStyles.h2.copyWith(color: Colors.white),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddFirmPage()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: Column(
            children: [
              _searchBar(),
              const SizedBox(height: AppSpacing.verticalLarge),
              Expanded(child: _body(filteredFirms)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(List<FirmModel> data) {
    if (_loading) {
      return const FirmStaffServiceListShimmer();
    }

    if (_error != null) {
      return NetworkStateView(
        isOffline: _isOffline,
        message: _error,
        onRetry: _loadFirms,
      );
    }

    if (data.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: AnimatedEmptyState(
            icon: Icons.storefront_outlined,
            title: "No Firms Found",
            message: "Add firms to start tracking performance and insights.",
            height: MediaQuery.of(context).size.height * 0.45,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadFirms(silent: true),
      color: AppColors.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: data.length,
        padding: const EdgeInsets.only(
          bottom: 80, // 👈 space for FAB + breathing room
        ),
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppSpacing.verticalMedium),
        itemBuilder: (context, index) {
          final firm = data[index];

          return InsightsCard(
            name: firm.name,
            description: firm.description,
            revenue: CurrencyUtils.format(firm.revenue),
            transactions: firm.transactions.toString(),
            percent: "${firm.percent.abs().toStringAsFixed(1)}%",
            positive: firm.percent >= 0,
            showTrophy: firm.percent > 10,
            onViewDetails: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FirmDetailPage(firmId: firm.id),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _searchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: "Search firms",
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: AppColors.cardBackground,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
