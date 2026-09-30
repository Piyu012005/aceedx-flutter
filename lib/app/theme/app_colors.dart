import 'package:flutter/material.dart';

/// Master Color Palette for AceEdx Flutter Application.
///
/// Derived from forensic analysis of `public/web/main.dart.js`.
class AppColors {
  const AppColors._();

  // Primary Brand Colors
  static const Color primary = Color(0xFF1E3A8A); // Deep Brand Blue
  static const Color primaryHover = Color(0xFF1D4ED8); // Medium Blue
  static const Color primaryLight = Color(0xFF3B82F6); // Active Blue Accent
  static const Color primaryDark = Color(0xFF172554); // Deep Navy

  // Secondary & Accent Colors
  static const Color secondary = Color(0xFF06B6D4); // Cyan Accent
  static const Color secondaryLight = Color(0xFF22D3EE);
  static const Color accent = Color(0xFF3B82F6);
  static const Color accentBackground = Color(0xFFEFF6FF); // Soft Blue Tint

  // Background & Surface Colors
  static const Color background = Color(0xFFF8FAFC); // Main Scaffold Light Slate
  static const Color workspaceBackground = Color(0xFFF1F5F9); // Dashboard Workspace Off-White
  static const Color surface = Color(0xFFFFFFFF); // Pure White Surface
  static const Color card = Color(0xFFFFFFFF); // Card Surface

  // Sidebar Specific Colors
  static const Color sidebarBackground = Color(0xFF0F172A); // Midnight Dark Slate
  static const Color sidebarBackgroundSecondary = Color(0xFF1E293B);
  static const Color sidebarItemActive = Color(0xFF1E3A8A);
  static const Color sidebarItemHover = Color(0xFF334155);
  static const Color sidebarText = Color(0xFFE2E8F0);
  static const Color sidebarTextMuted = Color(0xFF94A3B8);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A); // Dark Slate Heading
  static const Color textSecondary = Color(0xFF334155); // Body Text
  static const Color textMuted = Color(0xFF64748B); // Subtitle / Hint / Caption
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White on Blue
  static const Color textOnDark = Color(0xFFF8FAFC);

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0); // Subtle Gray Border
  static const Color borderMedium = Color(0xFFCBD5E1);
  static const Color borderFocus = Color(0xFF2563EB); // Focus Ring
  static const Color divider = Color(0xFFE2E8F0);

  // Status & Semantic Colors
  static const Color success = Color(0xFF10B981); // Emerald Green (Approved)
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color successDark = Color(0xFF047857);

  static const Color warning = Color(0xFFF59E0B); // Amber / Orange (Pending)
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFFB45309);

  static const Color error = Color(0xFFEF4444); // Crimson Red (Rejected / Error)
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFFB91C1C);

  static const Color info = Color(0xFF0284C7); // Informational Sky Blue
  static const Color infoLight = Color(0xFFE0F2FE);

  // Disabled & Neutral States
  static const Color disabled = Color(0xFFE2E8F0);
  static const Color disabledText = Color(0xFF94A3B8);
  static const Color shimmerBase = Color(0xFFE2E8F0);
  static const Color shimmerHighlight = Color(0xFFF8FAFC);
}
