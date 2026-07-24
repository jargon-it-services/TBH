import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/app_version/app_version_service.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/onboarding/onboarding_manager.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart'; // new theme
import '../../../features/app_version/force_update_page.dart';
import '../../../features/app_version/maintenance_page.dart';
import '../../../features/app_version/optional_update_dialog.dart';
import '../../../features/introduction/introduction_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _logoController;
  String _version = "";

  // Both kicked off immediately so they're already resolved (or close
  // to it) by the time _minimumSplashDuration elapses. restoreSession()
  // and isOnboardingCompleted() each dedupe/cache their own concurrent
  // calls, so this is cheap even if something else touches them later.
  late final Future<bool> _sessionRestoreFuture;
  late final Future<bool> _onboardingCompletedFuture;

  // Also started immediately in initState (not created inline inside
  // _proceedWhenReady()) so both run concurrently with the futures
  // above instead of adding their own sequential wait on top of them.
  late final Future<AppVersionCheckResult> _versionCheckFuture;
  late final Future<bool> _minimumSplashFuture;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _loadVersion();
    _sessionRestoreFuture = SessionManager.instance.restoreSession();
    _onboardingCompletedFuture = OnboardingManager.instance
        .isOnboardingCompleted();
    _versionCheckFuture = AppVersionService.instance.checkVersion();
    _minimumSplashFuture = Future.delayed(_minimumSplashDuration, () => true);

    Future.delayed(const Duration(milliseconds: 300), () {
      _logoController.forward();
      Future.delayed(const Duration(seconds: 7), () async {
        _proceedWhenReady();
      });
    });
  }

  /// Waits for both the real async work (session restore + onboarding
  /// check — usually near-instant local storage reads) and a minimum
  /// on-screen duration for the splash/logo animation to feel
  /// intentional, then navigates — whichever of the two takes longer.
  ///
  /// Previously this waited a fixed 7 seconds regardless of how fast
  /// the actual checks resolved, adding several seconds of unnecessary
  /// wait to every single cold start. [_minimumSplashDuration] is the
  /// new floor — tune it if the animation needs more/less room, but it
  /// should stay well under the old fixed delay.
  static const _minimumSplashDuration = Duration(milliseconds: 2000);

  Future<void> _proceedWhenReady() async {
    // Checked first: maintenance/force-update must block the existing
    // onboarding/session flow below entirely (that's the "prevent
    // navigation into the app" requirement) — this is the only new
    // control-flow branch added to this method; everything below it is
    // the app's existing logic, untouched.
    final versionCheck = await _versionCheckFuture;
    if (!mounted) return;

    if (versionCheck.status == AppVersionCheckStatus.maintenance) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              MaintenancePage(message: versionCheck.result?.message),
        ),
      );
      return;
    }

    if (versionCheck.status == AppVersionCheckStatus.forceUpdate) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ForceUpdatePage(result: versionCheck.result!),
        ),
      );
      return;
    }

    final results = await Future.wait<bool>([
      _onboardingCompletedFuture,
      _sessionRestoreFuture,
      _minimumSplashFuture,
    ]);
    if (!mounted) return;

    final onboardingCompleted = results[0];
    final isLoggedIn = results[1];

    if (!onboardingCompleted) {
      // Show onboarding only once: this is the only path that leads to
      // IntroductionPage. Every future launch, once onboarding_completed
      // is true, skips straight to the Authentication Flow below.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const IntroductionPage()),
      );
    } else {
      /// Authentication Flow: token exists -> Home, no token -> Login.
      /// An existing-but-expired token is handled by the existing
      /// refresh-token flow in DioClient the moment the app makes its
      /// first protected request — reused here, not reimplemented.
      AppNavigator.pushReplacementPostAuth(context, isLoggedIn: isLoggedIn);
    }

    if (versionCheck.status == AppVersionCheckStatus.optionalUpdate) {
      // Non-blocking: shown after the app has already navigated to
      // wherever it was going, via the global navigator context (see
      // OptionalUpdateDialog) since this page is gone by the time it
      // fires.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        OptionalUpdateDialog.maybeShow(versionCheck.result!);
      });
    }
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _version = "App Version ${info.version}";
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.white],
            begin: Alignment.center,
            end: Alignment.topRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Spacer(),

              /// Logo
              ScaleTransition(
                scale: Tween(begin: 0.0, end: 0.7).animate(
                  CurvedAnimation(
                    parent: _logoController,
                    curve: Curves.easeInOut,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.circle),
                  child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                ),
              ),
              const Spacer(),

              /// Animated text / version
              Column(
                children: [
                  SizedBox(
                    height: 30,
                    child: AnimatedTextKit(
                      repeatForever: true,
                      animatedTexts: [
                        RotateAnimatedText(
                          _version.isEmpty ? 'Loading version...' : _version,
                          duration: const Duration(milliseconds: 1000),
                          textStyle: AppTextStyles.body.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        RotateAnimatedText(
                          '#Proudlyभारतीय 🇮🇳',
                          duration: const Duration(milliseconds: 1000),
                          textStyle: AppTextStyles.body.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        RotateAnimatedText(
                          'Almost there! Preparing your experience...',
                          duration: const Duration(milliseconds: 1000),
                          textStyle: AppTextStyles.body.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        RotateAnimatedText(
                          "Everything's ready. Let's go!",
                          duration: const Duration(milliseconds: 1000),
                          textStyle: AppTextStyles.body.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.verticalMedium),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
