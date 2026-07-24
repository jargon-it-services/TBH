import 'package:flutter/material.dart';

import '../../../../core/theme/app_fonts.dart';
import '../registration_data.dart';
import '../registration_validators.dart';
import '../widgets/password_strength_meter.dart';
import '../widgets/registration_step_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';

class Step3AccountSetup extends StatefulWidget {
  const Step3AccountSetup({
    super.key,
    required this.data,
    required this.onBack,
    required this.onContinue,
  });

  final RegistrationData data;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  State<Step3AccountSetup> createState() => _Step3AccountSetupState();
}

class _Step3AccountSetupState extends State<Step3AccountSetup>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _formKey = GlobalKey<FormState>();
  final _shakeTrigger = ValueNotifier<int>(0);
  String _confirmPassword = '';
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _shakeTrigger.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final d = widget.data;
    // Login Email always mirrors the Account Email collected in Step 1 —
    // keep it in sync and lock the field so it can't drift from that.
    d.loginEmail = d.accountEmail;

    return RegistrationStepScaffold(
      stepIndex: 2,
      totalSteps: 4,
      title: 'Account Setup',
      subtitle: "You'll use this to log in to the portal",
      formKey: _formKey,
      shakeTrigger: _shakeTrigger,
      onBack: widget.onBack,
      onContinue: () async {
        widget.onContinue();
        return false;
      },
      child: Column(
        children: [
          AppTextField(
            // Re-keyed on the value so the field re-mounts (and shows the
            // latest Account Email) if the user goes back and changes it.
            key: ValueKey('loginEmail-${d.loginEmail}'),
            label: 'Login Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            initialValue: d.loginEmail,
            enabled: false,
            validator: RegistrationValidators.email,
          ),
          AppTextField(
            label: 'Password',
            icon: Icons.key,
            obscureText: _obscurePassword,
            initialValue: d.password,
            onChanged: (v) => setState(() => d.password = v),
            validator: RegistrationValidators.password,
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
          PasswordStrengthMeter(password: d.password),
          AppTextField(
            label: 'Confirm Password',
            icon: Icons.lock_outline,
            obscureText: _obscureConfirm,
            onChanged: (v) => _confirmPassword = v,
            validator: (v) =>
                RegistrationValidators.confirmPassword(v, d.password),
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
}
