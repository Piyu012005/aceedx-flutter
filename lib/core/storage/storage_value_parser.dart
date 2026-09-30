import 'dart:convert';

/// Utility class providing type-safe conversions for browser storage values.
///
/// Prevents runtime type mismatches when reading from `SharedPreferences`
/// or browser `localStorage` where numbers, booleans, or lists might be
/// stored as raw strings or malformed formats.
abstract final class StorageValueParser {
  /// Safely converts dynamic [value] to [int].
  ///
  /// Handles:
  /// - `int` (e.g. `1` -> `1`)
  /// - `num` (e.g. `1.0` -> `1`)
  /// - `String` (e.g. `"1"` -> `1`, `" 250 "` -> `250`)
  /// - Invalid strings or unsupported types -> `null` (never throws)
  static int? parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty ||
          trimmed.toLowerCase() == 'null' ||
          trimmed.toLowerCase() == 'undefined') {
        return null;
      }
      final parsed = int.tryParse(trimmed);
      if (parsed != null) return parsed;
      // Handle potential decimal strings like "1.0"
      final doubleParsed = double.tryParse(trimmed);
      if (doubleParsed != null) return doubleParsed.toInt();
    }
    return null;
  }

  /// Safely converts dynamic [value] to [bool].
  ///
  /// Handles:
  /// - `bool` (`true` / `false`)
  /// - `num` (`1` -> `true`, `0` -> `false`)
  /// - `String` (`"true"`, `"1"`, `"yes"` -> `true`; `"false"`, `"0"`, `"no"` -> `false`)
  /// - Invalid strings or unsupported types -> `null` (never throws)
  static bool? parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) {
      if (value == 1) return true;
      if (value == 0) return false;
      return null;
    }
    if (value is String) {
      final s = value.trim().toLowerCase();
      if (s == 'true' || s == '1' || s == 'yes') return true;
      if (s == 'false' || s == '0' || s == 'no') return false;
    }
    return null;
  }

  /// Safely converts dynamic [value] to a sanitized [String].
  ///
  /// Rules:
  /// - Trims leading and trailing whitespace.
  /// - Returns `null` if empty or matches `"null"` / `"undefined"`.
  /// - Never produces literal `"null"` string.
  static String? parseString(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    if (str.isEmpty ||
        str.toLowerCase() == 'null' ||
        str.toLowerCase() == 'undefined') {
      return null;
    }
    return str;
  }

  /// Safely converts dynamic [value] to a `List<String>`.
  ///
  /// Supports:
  /// - Native `List` (elements mapped and filtered)
  /// - JSON array string (e.g. `'["teacher", "admin"]'`)
  /// - Comma-separated string (e.g. `'teacher, admin'`)
  /// - Single string (e.g. `'teacher'` -> `['teacher']`)
  /// - Corrupted/malformed data -> `null` (never crashes)
  static List<String>? parseStringList(dynamic value) {
    if (value == null) return null;

    if (value is List) {
      final list = value
          .map((e) => parseString(e))
          .where((e) => e != null && e.isNotEmpty)
          .cast<String>()
          .toList();
      return list.isNotEmpty ? list : null;
    }

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty ||
          trimmed.toLowerCase() == 'null' ||
          trimmed.toLowerCase() == 'undefined') {
        return null;
      }

      // Check if it's a JSON array representation
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is List) {
            final list = decoded
                .map((e) => parseString(e))
                .where((e) => e != null && e.isNotEmpty)
                .cast<String>()
                .toList();
            return list.isNotEmpty ? list : null;
          }
        } catch (_) {
          return null;
        }
      }

      // If it looks like a JSON object or malformed structure, reject
      if (trimmed.startsWith('{') || trimmed.startsWith('[') || trimmed.endsWith('}')) {
        return null;
      }

      // Check if it's a comma-separated list
      if (trimmed.contains(',')) {
        final list = trimmed
            .split(',')
            .map((e) => parseString(e))
            .where((e) => e != null && e.isNotEmpty)
            .cast<String>()
            .toList();
        return list.isNotEmpty ? list : null;
      }

      final single = parseString(trimmed);
      return single != null ? [single] : null;
    }

    return null;
  }

  /// Canonical Bearer token normalization rule.
  ///
  /// Strips any leading `'Bearer '` / `'bearer '` prefixes and whitespace.
  /// Returns raw token string, or `null` if empty/absent.
  ///
  /// Examples:
  /// - `"abc123"` -> `"abc123"`
  /// - `"Bearer abc123"` -> `"abc123"`
  /// - `"bearer abc123"` -> `"abc123"`
  /// - `"  Bearer abc123  "` -> `"abc123"`
  /// - `"Bearer Bearer abc123"` -> `"abc123"`
  /// - `""` / `null` / `"null"` -> `null`
  static String? normalizeToken(dynamic rawToken) {
    var token = parseString(rawToken);
    if (token == null) return null;

    // Iteratively strip leading "bearer " (case-insensitive)
    while (token!.toLowerCase().startsWith('bearer ')) {
      token = token.substring(7).trim();
    }

    return token.isEmpty ? null : token;
  }
}
