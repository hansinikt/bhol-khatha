class AppConfig {
  // Pass at run time: --dart-define=GNANI_API_KEY=... --dart-define=GNANI_BASE_URL=...
  static const gnaniApiKey = String.fromEnvironment('GNANI_API_KEY');
  static const gnaniBaseUrl = String.fromEnvironment('GNANI_BASE_URL');
}