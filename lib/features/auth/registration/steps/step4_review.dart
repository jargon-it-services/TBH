import 'package:flutter/material.dart';

import '../../../../core/network/apis/registration_api.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../registration_data.dart';
import '../widgets/registration_step_scaffold.dart';

class Step4Review extends StatefulWidget {
  const Step4Review({
    super.key,
    required this.data,
    required this.onBack,
    required this.onSuccess,
    required this.onJumpToStep,
  });

  final RegistrationData data;
  final VoidCallback onBack;

  /// Called with the auth token and (if the API returned one) the
  /// business/organization id once registration succeeds.
  final void Function(String authToken, String? businessId) onSuccess;

  /// Jumps straight to the given step index (0 = Contact, 1 = Owner,
  /// 2 = Account) instead of the user hitting Back repeatedly.
  final void Function(int stepIndex) onJumpToStep;

  @override
  State<Step4Review> createState() => _Step4ReviewState();
}

class _Step4ReviewState extends State<Step4Review>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _formKey = GlobalKey<FormState>();
  final RegistrationApi _api = RegistrationApi();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final d = widget.data;
    return RegistrationStepScaffold(
      stepIndex: 3,
      totalSteps: 4,
      title: 'Review & Submit',
      subtitle: 'Double check before we create your account',
      formKey: _formKey,
      onBack: widget.onBack,
      useSlideAction: true,
      actionLabel: 'Slide to Register',
      onContinue: () async {
        // Returning true tells the scaffold to show the loading collapse
        // (same as LoginPage) while the API call is in flight.
        final response = await RegistrationApi().registerBusiness(
          address: d.address,
          city: d.city,
          state: d.state,
          zip: d.zip,
          phone: d.phone,
          businessEmail: d.accountEmail,
          ownerName: d.ownerName,
          designation: d.designation,
          idProofType: d.idProofType,
          idProofNumber: d.idProofNumber,
          idProofDocument: d.idProofDocument!,
          loginEmail: d.loginEmail,
          password: d.password,
        );

        if (response.isSuccess) {
          final authToken = response.data!.authToken;
          final businessId = response.data!.businessId;
          // Same "hold on the loading state for a beat" feel as the
          // Slide to Login button on the login screen, before we hand
          // off to Dashboard.
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) widget.onSuccess(authToken, businessId);
          });
          return true;
        } else {
          if (mounted) {
            AppSnackbar.error(context, response.error ?? 'Registration failed');
          }
          return false;
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReviewSection(
            title: 'Account Information',
            onEdit: () => widget.onJumpToStep(0),
            rows: {
              'Account Name': d.accountName,
              'Address': d.address,
              'City / State': '${d.city}, ${d.state}',
              'ZIP': d.zip,
              'Phone': d.phone,
              'Account Email': d.accountEmail,
            },
          ),
          _ReviewSection(
            title: 'Owner',
            onEdit: () => widget.onJumpToStep(1),
            rows: {
              'Name': d.ownerName,
              'Designation': d.designation,
              'ID Type': d.idProofType,
              'ID Number': d.idProofNumber,
            },
          ),
          _ReviewSection(
            title: 'Account Setup',
            onEdit: () => widget.onJumpToStep(2),
            rows: {
              'Login Email': d.loginEmail,
              'Password': '••••••••',
            },
          ),
        ],
      ),
    );
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.title,
    required this.rows,
    required this.onEdit,
  });

  final String title;
  final Map<String, String> rows;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.verticalMedium),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.h3),
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(AppRadius.small),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_outlined,
                          size: 14, color: AppColors.secondary),
                      const SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...rows.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key, style: AppTextStyles.bodySmall),
                  Flexible(
                    child: Text(
                      e.value.isEmpty ? '—' : e.value,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
