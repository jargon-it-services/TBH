import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../features/auth/registration/steps/step1_contact_info.dart';
import '../../../features/auth/registration/steps/step2_owner_info.dart';
import 'registration_data.dart';
import 'registration_success_page.dart';
import 'steps/step3_account_setup.dart';
import 'steps/step4_review.dart';

/// Owns the shared RegistrationData and the PageView that hosts all 4
/// steps — mirrors how LoginPage owns its own controllers/state.
/// Business details are collected separately via the Add Firm flow.
class RegistrationFlowPage extends StatefulWidget {
  const RegistrationFlowPage({super.key});

  @override
  State<RegistrationFlowPage> createState() => _RegistrationFlowPageState();
}

class _RegistrationFlowPageState extends State<RegistrationFlowPage> {
  final _data = RegistrationData();
  final _controller = PageController();
  int _index = 0;

  /// True once the user has typed/selected anything on Step 1 — used to
  /// decide whether leaving the flow needs a confirmation at all (no
  /// point warning about "losing changes" when there's nothing to lose).
  bool get _hasUnsavedContactData =>
      _data.address.isNotEmpty ||
      _data.state.isNotEmpty ||
      _data.city.isNotEmpty ||
      _data.zip.isNotEmpty ||
      _data.phone.isNotEmpty ||
      _data.accountEmail.isNotEmpty;

  void _goTo(int i) {
    setState(() => _index = i);
    _controller.animateToPage(
      i,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  /// Shows the discard-confirmation dialog and returns true if it's safe
  /// to proceed with leaving (either nothing to lose, or user confirmed).
  Future<bool> _confirmDiscardIfNeeded() async {
    if (!_hasUnsavedContactData) return true;

    final discard = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.pageBackground,
        title: const Text('Discard registration?', style: AppTextStyles.h3),
        content: const Text(
          "You'll lose everything you've entered so far. "
          'Are you sure you want to go back?',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Keep editing',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Discard',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    return discard ?? false;
  }

  Future<void> _back() async {
    if (_index == 0) {
      if (await _confirmDiscardIfNeeded() && mounted) {
        // Explicit pop() bypasses the PopScope's canPop gate (unlike
        // maybePop(), which respects it and — since canPop is always
        // false here — would just re-trigger onPopInvoked and never
        // actually leave).
        Navigator.of(context).pop();
      }
    } else {
      _goTo(_index - 1);
    }
  }

  /// Register -> Registration Success Screen -> Login. Deliberately does
  /// NOT create a session here (see RegistrationSuccessPage's doc
  /// comment) — LoginPage remains the only place a session gets created.
  void _onRegistrationSuccess(String authToken, String? businessId) {
    // Guards against the flow page having been popped/disposed during
    // Step4Review's delayed hand-off — without this, Navigator.of(context)
    // on a deactivated element throws "Looking up a deactivated widget's
    // ancestor is unsafe."
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => RegistrationSuccessPage(businessId: businessId),
      ),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Always intercept the OS/hardware back gesture and route it through
      // _back() — same logic the in-app back arrow uses. On Steps 2-4 that
      // just steps back one page; on Step 1 it shows the discard
      // confirmation (if there's anything to lose) before actually
      // leaving. Letting canPop be true on those later steps used to skip
      // both of those and pop the whole registration flow straight away.
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _back();
      },
      child: PageView(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(), // step via buttons only
        children: [
          Step1ContactInfo(
            data: _data,
            onBack: _back,
            onContinue: () => _goTo(1),
          ),
          Step2OwnerInfo(
            data: _data,
            onBack: _back,
            onContinue: () => _goTo(2),
          ),
          Step3AccountSetup(
            data: _data,
            onBack: _back,
            onContinue: () => _goTo(3),
          ),
          Step4Review(
            data: _data,
            onBack: _back,
            onSuccess: _onRegistrationSuccess,
            onJumpToStep: _goTo,
          ),
        ],
      ),
    );
  }
}
