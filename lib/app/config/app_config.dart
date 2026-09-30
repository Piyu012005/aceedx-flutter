/// Environment types for the AceEdx frontend application.
enum Environment {
  development,
  staging,
  production,
}

/// Global Application Configuration for AceEdx Frontend Rebuild.
///
/// DEFAULT ENVIRONMENT IS STRICTLY SET TO DEVELOPMENT.
/// Production is for reference configuration only and MUST NOT be targeted by default.
class AppConfig {
  final Environment environment;
  final String appTitle;
  final String apiBaseUrl;
  final String webBaseUrl;
  final bool enableLogging;

  const AppConfig({
    required this.environment,
    required this.appTitle,
    required this.apiBaseUrl,
    required this.webBaseUrl,
    this.enableLogging = true,
  });

  /// Development Environment (DEV Target)
  static const AppConfig dev = AppConfig(
    environment: Environment.development,
    appTitle: 'AceEdx (DEV)',
    apiBaseUrl: 'https://deve.aceedx.com/api',
    webBaseUrl: 'https://deve.aceedx.com',
    enableLogging: true,
  );

  /// Staging Environment
  static const AppConfig staging = AppConfig(
    environment: Environment.staging,
    appTitle: 'AceEdx (Staging)',
    apiBaseUrl: 'https://staging.aceedx.com/api',
    webBaseUrl: 'https://staging.aceedx.com',
    enableLogging: true,
  );

  /// Production Configuration (REFERENCE ONLY - NEVER USE AS DEFAULT)
  static const AppConfig prod = AppConfig(
    environment: Environment.production,
    appTitle: 'AceEdx - AN EDTECH COMPANY',
    apiBaseUrl: 'https://aceedx.com/api',
    webBaseUrl: 'https://aceedx.com',
    enableLogging: false,
  );

  /// Active default configuration instance (Defaults strictly to DEV)
  static AppConfig current = dev;

  /// Check if active environment is development
  static bool get isDev => current.environment == Environment.development;

  /// Check if active environment is production
  static bool get isProd => current.environment == Environment.production;
}
