class AppConstants {
  // App Info
  static const String appName = 'ResQLink';
  static const String appTagline = 'Every second matters. Together, we bring them home.';
  
  // Spacing (8px grid)
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
  
  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  static const double radiusFull = 999.0;
  
  // Elevation
  static const double elevationSmall = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationLarge = 8.0;
  
  // Animation Duration
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  // Validation
  static const int minPasswordLength = 6;
  static const int phoneNumberLength = 10;
  
  // Routes
  static const String routeSplash = '/';
  static const String routeLogin = '/login';
  static const String routeSignup = '/signup';
  static const String routeLocationPermission = '/location-permission';
  static const String routeHome = '/home';
  static const String routeMain = '/main';
  static const String routeAIChat = '/ai-chat';
  static const String routeReportMissing = '/report-missing';
  static const String routeCaseFeed = '/case-feed';
  static const String routeCaseDetail = '/case-detail';
  static const String routeSubmitTip = '/submit-tip';
  static const String routeCaseTracking = '/case-tracking';
  static const String routeNotifications = '/notifications';
  static const String routeProfile = '/profile';
  static const String routeSettings = '/settings';
}
