import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../features/account/account_page.dart';
import '../../../features/dashboard/dashboard_page.dart';
import '../../../features/transactions/transactions_page.dart';

/// Post-login app shell: the bottom navigation bar and the three tabs
/// it switches between — Dashboard, Transactions, Profile.
///
/// This is the screen SplashPage/LoginPage/IntroductionPage all land
/// on once a session exists. It owns no role-based logic itself — the
/// Dashboard tab ([DashboardPage]) is responsible for showing the
/// right content for the logged-in user's role.
class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const [DashboardPage(), TransactionsPage(), AccountPage()];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabChange(int index) {
    setState(() => _currentIndex = index);
    _pageController.jumpToPage(index);
  }

  Widget _navIcon({
    required IconData activeIcon,
    required IconData inactiveIcon,
    required int index,
  }) {
    final bool isActive = _currentIndex == index;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 550),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: Icon(
        isActive ? activeIcon : inactiveIcon,
        key: ValueKey(isActive),
        size: isActive ? 26 : 24,
        color: isActive
            ? AppColors.iconOnPrimary
            : AppColors.iconOnPrimary.withOpacity(0.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: _pages,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                offset: const Offset(0, 8),
                color: Colors.black.withOpacity(0.15),
              ),
            ],
          ),
          child: GNav(
            selectedIndex: _currentIndex,
            onTabChange: _onTabChange,
            backgroundColor: Colors.transparent,
            rippleColor: AppColors.secondary,
            hoverColor: Colors.white.withOpacity(0.05),
            gap: 10,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            tabBorderRadius: 20,
            color: AppColors.iconOnPrimary.withOpacity(0.6),
            activeColor: AppColors.iconOnPrimary,
            textStyle: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.iconOnPrimary,
            ),
            tabs: [
              GButton(
                icon: Icons.dashboard_outlined, // required
                leading: _navIcon(
                  index: 0,
                  inactiveIcon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                ),
                text: 'Dashboard',
              ),
              GButton(
                icon: Icons.compare_arrows_outlined,
                leading: _navIcon(
                  index: 1,
                  inactiveIcon: Icons.compare_arrows_outlined,
                  activeIcon: Icons.swap_horiz,
                ),
                text: 'Transactions',
              ),
              GButton(
                icon: Icons.person_outline,
                leading: _navIcon(
                  index: 2,
                  inactiveIcon: Icons.person_outline,
                  activeIcon: Icons.person,
                ),
                text: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
