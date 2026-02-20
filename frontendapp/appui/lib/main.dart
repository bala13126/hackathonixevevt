import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/dark_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/theme/theme_provider.dart';
import 'core/constants/app_constants.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/login_page.dart';
import 'features/auth/signup_page.dart';
import 'features/location/location_permission_screen.dart';
import 'features/ai_chat/ai_chat_screen.dart';
import 'features/report/report_missing_screen.dart';
import 'features/case_feed/case_feed_screen.dart';
import 'features/case_detail/case_detail_screen.dart';
import 'features/tip/submit_tip_screen.dart';
import 'features/tracking/case_tracking_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/settings/settings_screen.dart';
import 'core/navigation/bottom_nav_bar.dart';
import 'models/missing_person.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeController _themeController = ThemeController();

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      controller: _themeController,
      child: AnimatedBuilder(
        animation: _themeController,
        builder: (context, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: DarkTheme.theme,
            themeMode: _themeController.themeMode,
            initialRoute: AppConstants.routeLogin,
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case AppConstants.routeSplash:
                  return MaterialPageRoute(builder: (_) => const SplashScreen());

                case AppConstants.routeLogin:
                  return MaterialPageRoute(builder: (_) => const LoginPage());

                case AppConstants.routeSignup:
                  return MaterialPageRoute(builder: (_) => const SignupPage());

                case AppConstants.routeLocationPermission:
                  return MaterialPageRoute(builder: (_) => const LocationPermissionScreen());

                case AppConstants.routeHome:
                case AppConstants.routeMain:
                  return MaterialPageRoute(builder: (_) => const MainNavigationScreen());

                case AppConstants.routeAIChat:
                  return MaterialPageRoute(builder: (_) => const AIChatScreen());

                case AppConstants.routeReportMissing:
                  return MaterialPageRoute(builder: (_) => const ReportMissingScreen());

                case AppConstants.routeCaseFeed:
                  return MaterialPageRoute(builder: (_) => const CaseFeedScreen());

                case AppConstants.routeCaseDetail:
                  final person = settings.arguments as MissingPerson?;
                  if (person != null) {
                    return MaterialPageRoute(
                      builder: (_) => CaseDetailScreen(person: person),
                    );
                  }
                  return MaterialPageRoute(builder: (_) => const MainNavigationScreen());

                case AppConstants.routeSubmitTip:
                  final caseId = settings.arguments as String? ?? '';
                  return MaterialPageRoute(
                    builder: (_) => SubmitTipScreen(caseId: caseId),
                  );

                case AppConstants.routeCaseTracking:
                  return MaterialPageRoute(builder: (_) => const CaseTrackingScreen());

                case AppConstants.routeNotifications:
                  return MaterialPageRoute(builder: (_) => const NotificationsScreen());

                case AppConstants.routeProfile:
                  return MaterialPageRoute(builder: (_) => const ProfileScreen());

                case AppConstants.routeSettings:
                  return MaterialPageRoute(builder: (_) => const SettingsScreen());

                default:
                  return MaterialPageRoute(builder: (_) => const LoginPage());
              }
            },
          );
        },
      ),
    );
  }
}
