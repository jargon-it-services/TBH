import 'package:flutter/material.dart';

import '../../core/network/apis/login_api.dart';
import '../../core/session/session_manager.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/slide_action_button.dart';
import 'forgot_password/forgot_password_page.dart';
import 'registration/registration_flow_page.dart';
import 'registration/registration_validators.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final LoginApi _loginApi = LoginApi();

  String _organizationCode = '';
  String _email = '';
  String _password = '';
  bool _obscurePassword = true;

  bool bioMetricSupported = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    checkAndProcess();
    // Runs after the first frame so ModalRoute.of(context) is available.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _showSessionExpiredIfNeeded());
  }

  checkAndProcess() async {}

  /// If we landed here via a forced logout (DioClient giving up after a
  /// failed token refresh — see AppNavigator.goToLoginAndClearStack),
  /// tell the user why instead of silently dropping them back to
  /// Login. An explicit, user-initiated logout (AccountPage) passes no
  /// such argument, so this stays silent in that case — no explanation
  /// needed for something the user just did themselves.
  void _showSessionExpiredIfNeeded() {
    if (!mounted) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['sessionExpired'] == true) {
      AppSnackbar.error(context, 'Session expired. Please log in again.');
    }
  }

  void _goToForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    /// MAIN CONTENT
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.page),
                        child: Column(
                          children: <Widget>[
                            SizedBox(height: size.height * 0.10),

                            /// LOGO
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.circle),
                              child: Image.asset(
                                'assets/logo.png',
                                fit: BoxFit.cover,
                                height: 120,
                              ),
                            ),

                            SizedBox(
                                height:
                                    size.height * AppSpacing.contentGapRatio),

                            /// TITLE
                            const Text(
                              "Welcome back",
                              style: AppTextStyles.h1,
                            ),
                            Text(
                              "Sign in to your workspace",
                              style: AppTextStyles.body
                                  .copyWith(color: Colors.black54),
                            ),
                            SizedBox(
                                height:
                                    size.height * AppSpacing.contentGapRatio),

                            /// INPUTS
                            Form(
                              key: _formKey,
                              child: Column(
                                children: <Widget>[
                                  AppTextField(
                                    label: 'Your organisation code',
                                    icon: Icons.tag,
                                    onChanged: (v) => _organizationCode = v,
                                    validator: (v) =>
                                        RegistrationValidators.required(
                                            v, 'Organization code'),
                                  ),
                                  AppTextField(
                                    label: 'Registered email address',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    onChanged: (v) => _email = v,
                                    validator: RegistrationValidators.email,
                                  ),
                                  AppTextField(
                                    label: 'Password',
                                    icon: Icons.key,
                                    obscureText: _obscurePassword,
                                    onChanged: (v) => _password = v,
                                    validator: (v) =>
                                        RegistrationValidators.required(
                                            v, 'Password'),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() =>
                                          _obscurePassword =
                                              !_obscurePassword),
                                    ),
                                  ),

                                  /// FORGOT PASSWORD
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      InkWell(
                                        splashColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        hoverColor: Colors.transparent,
                                        onTap: _goToForgotPassword,
                                        child: Text(
                                          "Forgot Password?",
                                          style: AppTextStyles.body.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.secondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(
                                height: size.height * AppSpacing.inputGapRatio),

                            /// SLIDE TO LOGIN
                            SlideActionButton(
                              label: 'Slide to Login',
                              expandedWidth: 280,
                              submitting: isLoading,
                              onSlide: (controller) async {
                                // Guard against duplicate submissions: if a
                                // login request is already in flight, ignore
                                // this slide instead of firing a second one.
                                if (isLoading) return;

                                if (!(_formKey.currentState?.validate() ??
                                    false)) {
                                  AppSnackbar.warning(
                                    context,
                                    'Please fix the highlighted fields',
                                  );
                                  return;
                                }
                                setState(() => isLoading = true);

                                final response = await _loginApi.login(
                                  organizationCode: _organizationCode,
                                  email: _email,
                                  password: _password,
                                );

                                if (!mounted) return;

                                if (!response.isSuccess) {
                                  setState(() => isLoading = false);
                                  AppSnackbar.error(
                                    context,
                                    response.error ?? 'Login failed',
                                  );
                                  return;
                                }

                                try {
                                  await SessionManager.instance.saveSession(
                                    token: response.data!.authToken,
                                    userName: response.data!.userName,
                                    role: response.data!.role,
                                    refreshToken: response.data!.refreshToken,
                                  );
                                } catch (_) {
                                  if (!mounted) return;
                                  setState(() => isLoading = false);
                                  AppSnackbar.error(
                                    context,
                                    'Could not save your session. Please try again.',
                                  );
                                  return;
                                }

                                if (!mounted) return;
                                setState(() => isLoading = false);
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/home',
                                  (route) => false,
                                );
                              },
                            ),

                            SizedBox(height: size.height * 0.05),

                            /// REGISTER LINK
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: AppTextStyles.body
                                      .copyWith(color: Colors.black87),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const RegistrationFlowPage(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    "Register Now",
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: size.height * 0.05),
                          ],
                        ),
                      ),
                    ),

                    /// FOOTER
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.page),
                      color: Colors.grey.shade50,
                      child: Column(
                        children: [
                          Text(
                            "Terms & Conditions | App Version 1.0.0",
                            style: AppTextStyles.bodySmall
                                .copyWith(color: Colors.grey),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Powered & Managed by ",
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: Colors.grey),
                              ),
                              SizedBox(
                                height: 30,
                                child: AnimatedOpacity(
                                  opacity: 0.7,
                                  duration: const Duration(milliseconds: 300),
                                  child: Image.asset(
                                    'assets/images/jargon_nbg.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            "©2026 THE BEAUTY HUB. All rights reserved.",
                            style: AppTextStyles.bodySmall
                                .copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
