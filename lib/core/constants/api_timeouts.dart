/// Standard request timeout durations for AceEdx API calls.
abstract final class ApiTimeouts {
  /// Standard request timeout (30 seconds)
  static const Duration request = Duration(seconds: 30);

  /// Short timeout for lightweight requests (10 seconds)
  static const Duration short = Duration(seconds: 10);

  /// Long timeout for heavier operations like AI question paper generation (120 seconds)
  static const Duration long = Duration(seconds: 120);

  /// Dedicated AI question paper generation timeout (120 seconds)
  static const Duration aiGeneration = Duration(seconds: 120);
}

