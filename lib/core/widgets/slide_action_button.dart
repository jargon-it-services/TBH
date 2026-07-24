import 'package:action_slider/action_slider.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

/// Common "Slide to X" action button.
///
/// Extracted from the original "Slide to Login" implementation on
/// [LoginPage] and shared as-is (same visuals, animation, gesture
/// handling and loading-collapse behavior) with ForgotPasswordPage's
/// "Slide to Authorize" and RegistrationStepScaffold's
/// "Slide to Continue" / "Slide to Register" actions.
///
/// This widget only owns the visual shell (the animated width/shape
/// transition, the slider itself, and the loading spinner). Enabled/
/// disabled gating, form validation, and submission logic stay with
/// each caller, exactly as they worked before extraction.
class SlideActionButton extends StatelessWidget {
  const SlideActionButton({
    super.key,
    required this.label,
    required this.onSlide,
    this.submitting = false,
    this.pulseScale,
    this.expandedWidth,
  });

  /// Text shown on the slider (e.g. "Slide to Login").
  final String label;

  /// Called once the slider is dragged to completion. Return/await as
  /// needed; the caller is responsible for flipping [submitting] via
  /// its own state and rebuilding.
  final Future<void> Function(ActionSliderController controller) onSlide;

  /// When true, the slider collapses into a circular loading spinner
  /// (same "shrink to a dot" transition used on Login/Forgot
  /// Password/Registration Review).
  final bool submitting;

  /// Optional pulsing "look at me" hint animation (used by the
  /// Registration Review step). Left null elsewhere, matching the
  /// original behavior where only that step pulsed.
  final Animation<double>? pulseScale;

  /// Fixed width to use while expanded (e.g. 280 on Login/Forgot
  /// Password). If null, the slider expands to fill the available
  /// width instead (used on the full-bleed Registration Review step).
  final double? expandedWidth;

  Widget _loadingCollapse() => Container(
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(AppRadius.circle),
        ),
        child: const Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );

  Widget _slider() {
    final slider = ActionSlider.standard(
      sliderBehavior: SliderBehavior.stretch,
      rolling: false,
      backgroundColor: AppColors.primary,
      toggleColor: AppColors.secondary,
      icon: const Icon(
        Icons.arrow_forward_ios_outlined,
        color: Colors.white,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      action: onSlide,
    );

    return pulseScale != null
        ? ScaleTransition(scale: pulseScale!, child: slider)
        : slider;
  }

  Widget _animatedContainer(double width) => AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        width: width,
        height: 65,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            submitting ? AppRadius.circle : AppRadius.medium,
          ),
        ),
        child: submitting ? _loadingCollapse() : _slider(),
      );

  @override
  Widget build(BuildContext context) {
    if (expandedWidth != null) {
      return _animatedContainer(submitting ? 70 : expandedWidth!);
    }

    // AnimatedContainer can't interpolate width between double.infinity
    // (unbounded) and a finite value like 70 — that combination throws
    // "Cannot interpolate between finite constraints and unbounded
    // constraints" the moment submitting flips to true. LayoutBuilder
    // gives us the parent's actual finite width instead, so both ends
    // of the animation are real numbers.
    return LayoutBuilder(
      builder: (context, constraints) {
        final fullWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width - (AppSpacing.page * 2);
        return _animatedContainer(submitting ? 70 : fullWidth);
      },
    );
  }
}
