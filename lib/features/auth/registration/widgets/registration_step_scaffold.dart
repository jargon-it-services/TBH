import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/slide_action_button.dart';
import 'shake_widget.dart';

class RegistrationStepScaffold extends StatefulWidget {
  const RegistrationStepScaffold({
    super.key,
    required this.stepIndex, // 0-based
    required this.totalSteps,
    required this.title,
    required this.subtitle,
    required this.formKey,
    required this.child,
    required this.onBack,
    required this.onContinue,
    this.useSlideAction = false,
    this.actionLabel,
    this.shakeTrigger,
  });

  final int stepIndex;
  final int totalSteps;
  final String title;
  final String subtitle;
  final GlobalKey<FormState> formKey;
  final Widget child;
  final VoidCallback onBack;

  /// Called only after Form.validate() passes (and, for the slide action,
  /// only after the slider has been dragged to completion). Return true to
  /// show the brief loading collapse (used on the final "Slide to Register"
  /// step while the API call runs).
  final Future<bool> Function() onContinue;

  /// Steps 1-3 use a normal "Save & Continue" button (matches Add Firm's
  /// Save Firm button). Only the final Review step still uses the
  /// slide-to-confirm action, since it's the one that actually submits.
  final bool useSlideAction;

  /// Defaults to 'Slide to Continue' in slide mode, 'Save & Continue' in
  /// button mode — pass your own (e.g. 'Slide to Register') to override.
  final String? actionLabel;

  /// Optional — pass your own ValueNotifier<int> if the step also needs
  /// to trigger a shake for manual validation (dropdowns, pickers, files)
  /// that Form.validate() can't see. Increment `.value` to shake.
  final ValueNotifier<int>? shakeTrigger;

  @override
  State<RegistrationStepScaffold> createState() =>
      _RegistrationStepScaffoldState();
}

class _RegistrationStepScaffoldState extends State<RegistrationStepScaffold>
    with SingleTickerProviderStateMixin {
  bool isLoading = false;
  late final ValueNotifier<int> _internalShake = ValueNotifier<int>(0);

  late final AnimationController _hintController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );
  late final Animation<double> _hintScale =
      Tween<double>(begin: 1.0, end: 1.035)
          .chain(CurveTween(curve: Curves.easeInOut))
          .animate(_hintController);

  ValueNotifier<int> get _shake => widget.shakeTrigger ?? _internalShake;

  @override
  void initState() {
    super.initState();
    // The pulsing "look at me" hint only makes sense on the slide action —
    // a static button doesn't need it.
    if (widget.useSlideAction) _runHintPulse();
  }

  /// Runs a couple of subtle "look at me, drag me" pulses on the slider
  /// shortly after the step first appears, then stops for good.
  Future<void> _runHintPulse() async {
    await Future.delayed(const Duration(milliseconds: 450));
    for (var i = 0; i < 2 && mounted; i++) {
      await _hintController.forward();
      if (!mounted) return;
      await _hintController.reverse();
      await Future.delayed(const Duration(milliseconds: 180));
    }
  }

  @override
  void dispose() {
    _hintController.dispose();
    if (widget.shakeTrigger == null) _internalShake.dispose();
    super.dispose();
  }

  /// Shared by both the slide action and the button: validate the form,
  /// shake + snackbar on failure, otherwise run onContinue and show the
  /// loading collapse if it asks for one.
  Future<void> _handleContinue() async {
    if (!(widget.formKey.currentState?.validate() ?? false)) {
      _shake.value++;
      AppSnackbar.warning(context, 'Please fix the highlighted fields');
      return;
    }
    final shouldShowLoading = await widget.onContinue();
    if (shouldShowLoading && mounted) {
      setState(() => isLoading = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (widget.stepIndex + 1) / widget.totalSteps;
    final pct = (progress * 100).round();
    final size = MediaQuery.of(context).size;
    final label = widget.actionLabel ??
        (widget.useSlideAction ? 'Slide to Continue' : 'Save & Continue');

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: widget.onBack,
                      borderRadius: BorderRadius.circular(AppRadius.circle),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back,
                            size: 18, color: AppColors.primary),
                      ),
                    ),
                    Text(
                      'Step ${widget.stepIndex + 1} of ${widget.totalSteps} · $pct%',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: size.height * AppSpacing.inputGapRatio),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.small),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
                SizedBox(height: size.height * AppSpacing.contentGapRatio),
                Text(widget.title, style: AppTextStyles.h1),
                const SizedBox(height: 4),
                Text(
                  widget.subtitle,
                  style: AppTextStyles.body.copyWith(color: Colors.black54),
                ),
                SizedBox(height: size.height * AppSpacing.contentGapRatio),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        ShakeWidget(
                          trigger: _shake,
                          child: Form(key: widget.formKey, child: widget.child),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              top: AppSpacing.verticalLarge,
                              bottom: AppSpacing.verticalLarge),
                          child: Center(
                            child: widget.useSlideAction
                                ? _buildSlideAction(label)
                                : _buildContinueButton(label),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Padding(
                //   padding:
                //       const EdgeInsets.only(bottom: AppSpacing.verticalLarge),
                //   child: Center(
                //     child: widget.useSlideAction
                //         ? _buildSlideAction(label)
                //         : _buildContinueButton(label),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Slide-to-confirm action — kept only for the final Review/Submit step.
  Widget _buildSlideAction(String label) {
    return SlideActionButton(
      label: label,
      submitting: isLoading,
      pulseScale: _hintScale,
      onSlide: (controller) => _handleContinue(),
    );
  }

  /// Normal "Save & Continue" button — used for Steps 1-3, styled to
  /// match the Save Firm button from the Add Firm flow.
  Widget _buildContinueButton(String label) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
        ),
        onPressed: isLoading ? null : _handleContinue,
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
