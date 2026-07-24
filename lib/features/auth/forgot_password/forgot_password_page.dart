import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/network/apis/forgot_password_api.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/inline_action_button.dart';
import '../../../core/widgets/slide_action_button.dart';
import '../registration/registration_validators.dart';
import '../registration/widgets/password_strength_meter.dart';

/// Single-screen progressive Forgot Password flow:
/// Organization Code -> Registered Email + OTP -> New Password.
///
/// Reuses AppTextField, RegistrationValidators (same password
/// rules as Registration) and the same "Slide to X" look/animation used
/// by LoginPage's "Slide to Login", just relabelled and API-driven.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  static const int _otpValiditySeconds = 5 * 60; // 5 minutes

  final ForgotPasswordApi _api = ForgotPasswordApi();
  final GlobalKey<FormState> _passwordFormKey = GlobalKey<FormState>();

  // ---- Organization ----
  String _orgCode = '';
  bool _orgVerifying = false;
  bool _orgVerified = false;

  // ---- Email / OTP ----
  String _email = '';
  bool _sendingOtp = false;
  bool _otpSent = false;
  String _otp = '';
  bool _verifyingOtp = false;
  bool _otpVerified = false;
  int _otpFieldGen = 0; // bumps to force-clear the OTP field on resend

  // ---- Resend timer ----
  int _secondsRemaining = _otpValiditySeconds;
  Timer? _resendTimer;
  bool get _canResend => _otpSent && !_otpVerified && _secondsRemaining <= 0;

  // ---- Password ----
  String _password = '';
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _submitting = false;

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _secondsRemaining = _otpValiditySeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining <= 1) {
        setState(() => _secondsRemaining = 0);
        timer.cancel();
        return;
      }
      setState(() => _secondsRemaining--);
    });
  }

  String get _timerLabel {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _verifyOrganization() async {
    if (_orgVerifying || _orgVerified) return;

    final error =
        RegistrationValidators.required(_orgCode, 'Organization code');
    if (error != null) {
      AppSnackbar.warning(context, error);
      return;
    }

    setState(() => _orgVerifying = true);
    final result = await _api.verifyOrganization(orgCode: _orgCode.trim());
    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _orgVerifying = false;
        _orgVerified = true;
      });
    } else {
      setState(() => _orgVerifying = false);
      AppSnackbar.error(
        context,
        result.error ?? 'Could not verify organization code',
      );
    }
  }

  Future<void> _sendOtp() async {
    if (_sendingOtp || !_orgVerified) return;

    final error = RegistrationValidators.email(_email);
    if (error != null) {
      AppSnackbar.warning(context, error);
      return;
    }

    setState(() => _sendingOtp = true);
    final result =
        await _api.sendOtp(orgCode: _orgCode.trim(), email: _email.trim());
    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _sendingOtp = false;
        _otpSent = true;
        _otpVerified = false;
        _otp = '';
        _otpFieldGen++;
      });
      _startResendTimer();
      AppSnackbar.success(
        context,
        result.data?.message ?? 'OTP sent to your registered email',
      );
    } else {
      setState(() => _sendingOtp = false);
      AppSnackbar.error(context, result.error ?? 'Failed to send OTP');
    }
  }

  Future<void> _verifyOtp() async {
    if (_verifyingOtp || !_otpSent || _otpVerified) return;

    final error = RegistrationValidators.required(_otp, 'OTP');
    if (error != null) {
      AppSnackbar.warning(context, error);
      return;
    }
    if (_canResend) {
      AppSnackbar.warning(
        context,
        'This OTP has expired. Please resend a new one.',
      );
      return;
    }

    setState(() => _verifyingOtp = true);
    final result = await _api.verifyOtp(
      orgCode: _orgCode.trim(),
      email: _email.trim(),
      otp: _otp.trim(),
    );
    if (!mounted) return;

    if (result.isSuccess) {
      _resendTimer?.cancel();
      setState(() {
        _verifyingOtp = false;
        _otpVerified = true;
      });
    } else {
      setState(() => _verifyingOtp = false);
      AppSnackbar.error(context, result.error ?? 'Invalid or expired OTP');
    }
  }

  /// Returns true to trigger the slider's loading-collapse state, same
  /// contract RegistrationStepScaffold uses for its slide action.
  Future<bool> _changePassword() async {
    if (!_otpVerified) return false;

    if (!(_passwordFormKey.currentState?.validate() ?? false)) {
      AppSnackbar.warning(context, 'Please fix the highlighted fields');
      return false;
    }

    final result = await _api.resetPassword(
      orgCode: _orgCode.trim(),
      email: _email.trim(),
      otp: _otp.trim(),
      password: _password,
    );
    if (!mounted) return false;

    if (result.isSuccess) {
      AppSnackbar.success(
        context,
        result.data?.message ?? 'Password changed successfully',
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.of(context).pop();
      });
      return true;
    } else {
      AppSnackbar.error(context, result.error ?? 'Failed to change password');
      return false;
    }
  }

  Widget _verifiedBadge() => const Padding(
        padding: EdgeInsets.only(right: 4),
        child: Icon(Icons.check_circle, color: AppColors.success, size: 22),
      );

  Widget _inlineSpinner() => const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );

  Widget _buildOrgField() {
    return AppTextField(
      label: 'Organization Code',
      icon: Icons.tag,
      enabled: !_orgVerified,
      onChanged: (v) => _orgCode = v,
      suffixIcon: _orgVerified
          ? _verifiedBadge()
          : _orgVerifying
              ? _inlineSpinner()
              : InlineActionButton(
                  label: 'Verify',
                  onPressed: _verifyOrganization,
                ),
    );
  }

  Widget _buildEmailField() {
    return AppTextField(
      key: const ValueKey('forgot-password-email'),
      label: 'Registered Email Address',
      icon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      enabled: _orgVerified && !_otpSent,
      onChanged: (v) => _email = v,
      suffixIcon: _otpSent
          ? _verifiedBadge()
          : _sendingOtp
              ? _inlineSpinner()
              : InlineActionButton(
                  label: 'Send OTP',
                  onPressed: _orgVerified ? _sendOtp : null,
                ),
    );
  }

  Widget _buildOtpField() {
    return AppTextField(
      key: ValueKey('forgot-password-otp-$_otpFieldGen'),
      label: 'Enter OTP',
      icon: Icons.password_outlined,
      keyboardType: TextInputType.number,
      enabled: _otpSent && !_otpVerified,
      onChanged: (v) => _otp = v,
      suffixIcon: _otpVerified
          ? _verifiedBadge()
          : _verifyingOtp
              ? _inlineSpinner()
              : InlineActionButton(
                  label: 'Verify',
                  onPressed: _otpSent ? _verifyOtp : null,
                ),
    );
  }

  Widget _buildTimerRow() {
    if (!_otpSent || _otpVerified) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.verticalMedium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _canResend ? 'OTP expired' : 'OTP valid for $_timerLabel',
            style: AppTextStyles.caption,
          ),
          if (_canResend)
            InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: _sendingOtp ? null : _sendOtp,
              child: Text(
                'Resend OTP',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Form(
      key: _passwordFormKey,
      child: Column(
        children: [
          AppTextField(
            label: 'New Password',
            icon: Icons.key,
            enabled: _otpVerified,
            obscureText: _obscurePassword,
            onChanged: (v) => setState(() => _password = v),
            validator: _otpVerified ? RegistrationValidators.password : null,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          PasswordStrengthMeter(password: _password),
          AppTextField(
            label: 'Confirm Password',
            icon: Icons.lock_outline,
            enabled: _otpVerified,
            obscureText: _obscureConfirm,
            validator: _otpVerified
                ? (v) => RegistrationValidators.confirmPassword(v, _password)
                : null,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          Text(
            'Use 8+ characters with a mix of letters and numbers.',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  /// Same visual/animation/loading contract as LoginPage's "Slide to
  /// Login" — just relabelled and gated behind OTP verification.
  Widget _buildSlideAction() {
    final enabled = _otpVerified;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: IgnorePointer(
        ignoring: !enabled || _submitting,
        child: SlideActionButton(
          label: 'Slide to Authorize',
          expandedWidth: 280,
          submitting: _submitting,
          onSlide: (controller) async {
            if (!enabled) return;
            setState(() => _submitting = true);
            final success = await _changePassword();
            if (!success && mounted) {
              setState(() => _submitting = false);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.page),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(AppRadius.circle),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        SizedBox(
                            height: size.height * AppSpacing.contentGapRatio),
                        const Text('Reset Password', style: AppTextStyles.h1),
                        const SizedBox(height: 4),
                        Text(
                          "Verify your organization to reset your account's password",
                          style: AppTextStyles.body
                              .copyWith(color: Colors.black54),
                        ),
                        SizedBox(
                            height: size.height * AppSpacing.contentGapRatio),
                        _buildOrgField(),
                        SizedBox(
                            height: size.height * AppSpacing.inputGapRatio),
                        _buildEmailField(),
                        _buildTimerRow(),
                        _buildOtpField(),
                        SizedBox(
                            height: size.height * AppSpacing.inputGapRatio),
                        _buildPasswordSection(),
                        SizedBox(
                            height: size.height * AppSpacing.contentGapRatio),
                        Center(child: _buildSlideAction()),
                        const SizedBox(height: AppSpacing.verticalLarge),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
