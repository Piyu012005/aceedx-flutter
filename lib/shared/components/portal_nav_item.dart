import 'package:flutter/material.dart';

/// Represents a single navigation destination within the AceEdx Portal Shell.
///
/// Derived from compiled `main.dart.js` sidebar structures (`bk8`, `t7`, `bjP`, `al2`).
@immutable
class PortalNavItem {
  /// Unique identifier or index key for this navigation item.
  final String id;

  /// Display title in the sidebar / drawer.
  final String title;

  /// Icon to display alongside the title.
  final IconData icon;

  /// Selected icon (optional, falls back to [icon]).
  final IconData? selectedIcon;

  /// Associated route path (if item navigates to a route).
  final String? route;

  /// Associated tab index (if portal uses tab switcher).
  final int? tabIndex;

  /// Optional badge text (e.g. "Upcoming", "New", "12", "Beta").
  final String? badge;

  /// Background color for the badge pill.
  final Color? badgeColor;

  /// Text color for the badge pill.
  final Color? badgeTextColor;

  /// Whether this item represents an external link.
  final bool isExternal;

  /// External target URL (if [isExternal] is true).
  final String? externalUrl;

  /// Custom tap handler (overrides default route/tab navigation).
  final VoidCallback? onTap;

  /// Optional tooltip message.
  final String? tooltip;

  /// Whether this item is disabled/locked.
  final bool isLocked;

  const PortalNavItem({
    required this.id,
    required this.title,
    required this.icon,
    this.selectedIcon,
    this.route,
    this.tabIndex,
    this.badge,
    this.badgeColor,
    this.badgeTextColor,
    this.isExternal = false,
    this.externalUrl,
    this.onTap,
    this.tooltip,
    this.isLocked = false,
  });

  /// Helper copyWith for modifying properties.
  PortalNavItem copyWith({
    String? id,
    String? title,
    IconData? icon,
    IconData? selectedIcon,
    String? route,
    int? tabIndex,
    String? badge,
    Color? badgeColor,
    Color? badgeTextColor,
    bool? isExternal,
    String? externalUrl,
    VoidCallback? onTap,
    String? tooltip,
    bool? isLocked,
  }) {
    return PortalNavItem(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      selectedIcon: selectedIcon ?? this.selectedIcon,
      route: route ?? this.route,
      tabIndex: tabIndex ?? this.tabIndex,
      badge: badge ?? this.badge,
      badgeColor: badgeColor ?? this.badgeColor,
      badgeTextColor: badgeTextColor ?? this.badgeTextColor,
      isExternal: isExternal ?? this.isExternal,
      externalUrl: externalUrl ?? this.externalUrl,
      onTap: onTap ?? this.onTap,
      tooltip: tooltip ?? this.tooltip,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PortalNavItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          icon == other.icon &&
          route == other.route &&
          tabIndex == other.tabIndex &&
          badge == other.badge &&
          isExternal == other.isExternal &&
          isLocked == other.isLocked;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      icon.hashCode ^
      (route?.hashCode ?? 0) ^
      (tabIndex?.hashCode ?? 0) ^
      (badge?.hashCode ?? 0) ^
      isExternal.hashCode ^
      isLocked.hashCode;
}
