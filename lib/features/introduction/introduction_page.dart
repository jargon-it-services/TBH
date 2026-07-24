import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:lottie/lottie.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/onboarding/onboarding_manager.dart';
import '../../core/session/session_manager.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';

class IntroductionPage extends StatefulWidget {
  const IntroductionPage({super.key});

  @override
  State<IntroductionPage> createState() => _IntroductionPageState();
}

class _IntroductionPageState extends State<IntroductionPage> {
  /// Save onboarding_completed, then continue into the Authentication
  /// Flow — same "token exists?" check Splash uses, reusing
  /// SessionManager's cached restore result rather than re-reading
  /// storage. Shared by both Skip and Done since they mean the same
  /// thing here: onboarding is over.
  Future<void> _completeOnboardingAndProceed() async {
    await OnboardingManager.instance.markOnboardingCompleted();
    if (!mounted) return;

    final isLoggedIn = await SessionManager.instance.restoreSession();
    if (!mounted) return;

    AppNavigator.pushReplacementPostAuth(context, isLoggedIn: isLoggedIn);
  }

  PageViewModel _buildPage({
    required String title,
    required List<String> points,
    required String animation,
  }) {
    Size size = MediaQuery.of(context).size;

    return PageViewModel(
      titleWidget: const SizedBox.shrink(),
      decoration: const PageDecoration(
        pageColor: Colors.white,
        contentMargin: EdgeInsets.symmetric(
          horizontal: AppSpacing.horizontalMedium,
        ),
      ),
      bodyWidget: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: size.height * AppSpacing.contentGapRatio),

              /// Animation
              Lottie.asset(
                animation,
                height: size.height * 0.28,
                repeat: false,
              ),

              SizedBox(height: size.height * AppSpacing.contentGapRatio),

              /// Title
              Text(title, textAlign: TextAlign.center, style: AppTextStyles.h1),

              SizedBox(height: size.height * AppSpacing.contentGapRatio),

              /// Points
              ...points.map(
                (pt) => Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.verticalSmall,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.secondary,
                        size: AppIcons.defaultSize,
                      ),
                      const SizedBox(width: AppSpacing.iconText),
                      Expanded(child: Text(pt, style: AppTextStyles.body)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PageViewModel> _pages() {
    return [
      _buildPage(
        title: "Your Beauty Firm's Digital Advantage",
        points: [
          "Built exclusively for salons, spas, and beauty parlour.",
          "Mobile‑first platform designed for modern owners.",
          "Replace messy paperwork with a clean digital system.",
          "Manage transactions, staff activity, and reports in one place.",
        ],
        animation: "assets/animations/no_paperwork.json",
      ),
      _buildPage(
        title: "Clarity, Control, Confidence",
        points: [
          "Gain transparency across daily operations.",
          "Track every transaction with ease and accuracy.",
          "Generate pay slips and detailed financial reports instantly.",
          "Scale effortlessly — from single beauty firm to multiple branches.",
        ],
        animation: "assets/animations/everytime_everywhere.json",
      ),
      _buildPage(
        title: "Smarter Business, Smarter Support",
        points: [
          "Role‑based access keeps your team organized and secure.",
          "Designed to grow with your business, no limits.",
          "Save time daily with streamlined workflows.",
        ],
        animation: "assets/animations/growth.json",
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: IntroductionScreen(
        pages: _pages(),
        globalBackgroundColor: Colors.white,
        showSkipButton: true,
        skip: Text(
          "Skip",
          style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
        ),
        next: const Icon(
          Icons.arrow_forward_ios_outlined,
          size: AppIcons.defaultSize,
          color: AppColors.primary,
        ),
        done: const Text("Get Started", style: AppTextStyles.button),
        onSkip: () {
          _completeOnboardingAndProceed();
        },
        onDone: () {
          _completeOnboardingAndProceed();
        },
        curve: Curves.fastLinearToSlowEaseIn,
        dotsDecorator: DotsDecorator(
          activeColor: AppColors.secondary,
          color: AppColors.primary,
          size: const Size(8, 8),
          activeSize: const Size(28, 8),
          activeShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
        ),
      ),
    );
  }
}
