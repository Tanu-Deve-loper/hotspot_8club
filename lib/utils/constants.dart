class AppConstants {
  // API Endpoints
  static const String baseUrl = 'https://staging.chamberofsecrets.8club.co';
  static const String experiencesEndpoint = '/v1/experiences?active=true';
  
  // Full URL (for reference)
  static String get experiencesUrl => baseUrl + experiencesEndpoint;
  
  // Character Limits
  static const int experienceTextLimit = 250;
  static const int questionTextLimit = 600;
  
  // Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  
  // Border Radius
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  
  // Card Dimensions
  static const double cardHeight = 200.0;
  static const double cardWidth = 150.0;
}
