import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/design_tokens.dart';
import 'portal_nav_item.dart';
import 'portal_sidebar.dart';

/// Mobile navigation drawer for AceEdx Portal Shells.
///
/// Derived from compiled `main.dart.js` drawer builder (`bk6`).
/// Automatically slides in on mobile viewports (<900px or <600px).
class MobileDrawer extends StatelessWidget {
  /// Portal display title in drawer header (e.g. "Teacher Workspace").
  final String portalTitle;

  /// Optional brand subtitle.
  final String brandSubtitle;

  /// List of navigation items.
  final List<PortalNavItem> items;

  /// Current active item index.
  final int selectedIndex;

  /// Callback when an item index is selected.
  final ValueChanged<int>? onIndexSelected;

  /// Callback when a specific [PortalNavItem] is tapped.
  final void Function(PortalNavItem item, int index)? onItemTap;

  /// Drawer width (defaults to 280px).
  final double width;

  const MobileDrawer({
    super.key,
    required this.portalTitle,
    this.brandSubtitle = 'AceEdx Platform',
    required this.items,
    this.selectedIndex = 0,
    this.onIndexSelected,
    this.onItemTap,
    this.width = 280.0,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: width,
      backgroundColor: AppColors.sidebarBackground,
      elevation: 16.0,
      child: PortalSidebar(
        portalTitle: portalTitle,
        brandSubtitle: brandSubtitle,
        items: items,
        selectedIndex: selectedIndex,
        width: width,
        isCollapsed: false,
        header: _buildDrawerHeader(context),
        onItemTap: (item, index) {
          // Close drawer before firing navigation callback
          Navigator.of(context).pop();

          if (item.onTap != null) {
            item.onTap!();
          } else if (onItemTap != null) {
            onItemTap!(item, index);
          } else if (onIndexSelected != null) {
            onIndexSelected!(item.tabIndex ?? index);
          }
        },
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: AppRadius.radiusMd,
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Text(
                'A',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  portalTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.sidebarText,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  brandSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.sidebarTextMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.sidebarTextMuted, size: 20),
            tooltip: 'Close Menu',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
