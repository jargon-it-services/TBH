import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../features/splash/splash_page.dart';

import 'core/connectivity/connectivity_service.dart';
import 'core/navigation/app_navigator.dart';
import 'core/referral/deep_link_service.dart';
import 'core/theme/app_colors.dart';
import 'core/widgets/connectivity_banner.dart';
import 'features/auth/login_page.dart';
import 'features/home/home_shell_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Fire-and-forget: starts connectivity monitoring immediately without
  // blocking app launch on the first check resolving.
  ConnectivityService.instance.initialize();
  // Same fire-and-forget treatment: captures/stores an invite token if
  // the app was opened via an invite link (cold start) and keeps
  // listening for further links while running. Deliberately started
  // independently of session/auth setup — DeepLinkService has no
  // concept of authentication and must never block app launch.
  DeepLinkService.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    return MaterialApp(
      navigatorKey: AppNavigator.key,
      title: 'The Beauty Hub',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0), // 🔥 lock font scaling
          ),
          // Single app-wide connectivity banner — lives here (not per
          // screen) so there's exactly one place that can ever show an
          // offline/online message, regardless of which screen or how
          // many in-flight requests are affected by the same change.
          child: ConnectivityBanner(child: child!),
        );
      },
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.pageBackground,
        useMaterial3: true,
      ),
      routes: {
        '/login': (_) => const LoginPage(),
        '/home': (_) => const HomeShellPage(),
      },
      home: const SplashPage(),
    );
  }
}
