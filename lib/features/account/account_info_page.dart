import 'package:flutter/material.dart';

import '../../core/network/apis/account_info_api.dart';
import '../../core/services/DataModels/account_info_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/card_wrapper.dart';
import '../../core/widgets/info_card.dart';
import '../../core/widgets/network_state_view.dart';
import '../../core/widgets/shimmers/service_detail_shimmer.dart';
import 'edit_account_info_page.dart';

/// Account Info screen — lets an Account Admin see exactly what was
/// filled in during Registration (Account Information, Owner Details,
/// Login), all in one place. Structure mirrors `ServiceDetailPage`: a
/// headline block, a stack of [InfoCard] sections, and an Edit action.
///
/// Only Phone Number, Address, Pincode/ZIP (City/State auto-derive from
/// it), Full Name, and Designation are ever editable — handled by
/// [EditAccountInfoPage]. Every other field here is shown for context
/// only and never becomes an input.
class AccountInfoPage extends StatefulWidget {
  const AccountInfoPage({super.key});

  @override
  State<AccountInfoPage> createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends State<AccountInfoPage> {
  final AccountInfoApi _api = AccountInfoApi();

  bool _loading = true;
  bool _isOffline = false;
  String? _error;
  AccountInfoResponse? _info;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final response = await _api.fetchAccountInfo();
    if (!mounted) return;

    if (response.isSuccess) {
      setState(() {
        _info = response.data;
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
        _error = response.error ?? "We couldn't load your account info right now.";
        _isOffline = response.isConnectivityError;
      });
    }
  }

  Future<void> _openEdit() async {
    if (_info == null) return;
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditAccountInfoPage(existing: _info!)),
    );
    if (updated == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text('Account Info', style: AppTextStyles.h2.copyWith(color: Colors.white)),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_info != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              tooltip: 'Edit Account Info',
              onPressed: _openEdit,
            ),
        ],
      ),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.page),
        child: ServiceDetailShimmer(),
      );
    }

    if (_error != null || _info == null) {
      return NetworkStateView(isOffline: _isOffline, message: _error, onRetry: _load);
    }

    final info = _info!;
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          _headline(info),
          const SizedBox(height: AppSpacing.verticalLarge),
          InfoCard(
            title: 'Account Information',
            titleIcon: Icons.store_mall_directory_outlined,
            rows: [
              InfoRowData(
                icon: Icons.badge_outlined,
                label: 'Account Name',
                value: info.accountName,
              ),
              InfoRowData(
                icon: Icons.email_outlined,
                label: 'Account Email',
                value: info.accountEmail,
              ),
              InfoRowData(icon: Icons.phone_outlined, label: 'Phone Number', value: info.phone),
              InfoRowData(
                icon: Icons.location_on_outlined,
                label: 'Address',
                value: info.address,
              ),
              InfoRowData(
                icon: Icons.pin_drop_outlined,
                label: 'Pin Code / ZIP Code',
                value: info.zip,
              ),
              InfoRowData(icon: Icons.location_city_outlined, label: 'City', value: info.city),
              InfoRowData(icon: Icons.map_outlined, label: 'State', value: info.state),
            ],
          ),
          const SizedBox(height: AppSpacing.verticalMedium),
          InfoCard(
            title: 'Owner Details',
            titleIcon: Icons.person_outline,
            rows: [
              InfoRowData(icon: Icons.person_outline, label: 'Full Name', value: info.ownerName),
              InfoRowData(
                icon: Icons.badge_outlined,
                label: 'Designation',
                value: info.designation,
              ),
              InfoRowData(
                icon: Icons.badge_outlined,
                label: 'ID Proof Type',
                value: info.idProofType,
              ),
              InfoRowData(
                icon: Icons.confirmation_number_outlined,
                label: 'ID Proof Number',
                value: info.idProofNumber,
              ),
            ],
          ),
          if (info.idProofDocumentUrl != null && info.idProofDocumentUrl!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.verticalMedium),
            CardWrapper(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.image_outlined, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.iconText),
                      Text('ID Document', style: AppTextStyles.h3),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.verticalMedium),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    child: Image.network(
                      info.idProofDocumentUrl!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.verticalMedium),
          InfoCard(
            title: 'Login',
            titleIcon: Icons.lock_outline,
            rows: [
              InfoRowData(icon: Icons.alternate_email, label: 'Login Email', value: info.loginEmail),
            ],
          ),
          const SizedBox(height: AppSpacing.verticalMedium),
        ],
      ),
    );
  }

  Widget _headline(AccountInfoResponse info) {
    return CardWrapper(
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary.withOpacity(0.12),
            child: const Icon(Icons.store_mall_directory_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.horizontalMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info.accountName, style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  info.ownerName,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
