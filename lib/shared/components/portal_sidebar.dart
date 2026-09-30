import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/design_tokens.dart';
import 'portal_nav_item.dart';

/// Desktop & Drawer Navigation Sidebar for AceEdx Portals.
///
/// Derived from compiled `main.dart.js` sidebar builders (`bk8`, `t7`, `bjP`, `al2`).
class PortalSidebar extends StatelessWidget {
  /// Portal display title in sidebar header (e.g. "Teacher Workspace").
  final String portalTitle;

  /// Optional brand subtitle.
  final String brandSubtitle;

  /// List of navigation items.
  final List<PortalNavItem> items;

  /// Current active item index.
  final int selectedIndex;

  /// Callback when an item is tapped.
  final ValueChanged<int>? onIndexSelected;

  /// Callback when a specific [PortalNavItem] is tapped.
  final void Function(PortalNavItem item, int index)? onItemTap;

  /// Custom width for sidebar (defaults to 240px).
  final double width;

  /// Whether sidebar is in collapsed icon-only mode (70px).
  final bool isCollapsed;

  /// Optional custom header widget.
  final Widget? header;

  /// Optional custom footer widget.
  final Widget? footer;

  const PortalSidebar({
    super.key,
    required this.portalTitle,
    this.brandSubtitle = 'AceEdx Platform',
    required this.items,
    this.selectedIndex = 0,
    this.onIndexSelected,
    this.onItemTap,
    this.width = AppDimensions.sidebarWidthDesktop,
    this.isCollapsed = false,
    this.header,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = isCollapsed ? AppDimensions.sidebarWidthCompact : width;

    return Container(
      width: effectiveWidth,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBackground,
        border: Border(
          right: BorderSide(
            color: AppColors.sidebarBackgroundSecondary,
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top Brand Header
            if (header != null)
              header!
            else
              _buildDefaultHeader(context),

            const Divider(
              color: AppColors.sidebarBackgroundSecondary,
              height: 1,
            ),

            // Scrollable Navigation Items
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                  horizontal: AppSpacing.sm,
                ),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = index == selectedIndex ||
                      (item.tabIndex != null && item.tabIndex == selectedIndex);

                  return _SidebarTile(
                    item: item,
                    isSelected: isSelected,
                    isCollapsed: isCollapsed,
                    onTap: () {
                      if (item.isLocked) return;

                      if (item.onTap != null) {
                        item.onTap!();
                      } else if (onItemTap != null) {
                        onItemTap!(item, index);
                      } else if (onIndexSelected != null) {
                        onIndexSelected!(item.tabIndex ?? index);
                      }
                    },
                  );
                },
              ),
            ),

            // Bottom Footer
            if (footer != null)
              footer!
            else
              _buildDefaultFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCollapsed ? AppSpacing.sm : AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      alignment: Alignment.centerLeft,
      child: isCollapsed
          ? Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppRadius.radiusMd,
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
            )
          : Row(
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
                          letterSpacing: 0.2,
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
              ],
            ),
    );
  }

  Widget _buildDefaultFooter() {
    if (isCollapsed) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      alignment: Alignment.center,
      child: const Text(
        'AceEdx v1.0.0 • Production Ready',
        style: TextStyle(
          color: AppColors.sidebarTextMuted,
          fontSize: 11,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _SidebarTile extends StatefulWidget {
  final PortalNavItem item;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.item,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  State<_SidebarTile> createState() => _SidebarTileState();
}

class _SidebarTileState extends State<_SidebarTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isSelected = widget.isSelected;
    final isCollapsed = widget.isCollapsed;

    Color backgroundColor = Colors.transparent;
    if (isSelected) {
      backgroundColor = AppColors.sidebarItemActive;
    } else if (_isHovered && !item.isLocked) {
      backgroundColor = AppColors.sidebarItemHover;
    }

    final Color foregroundColor = isSelected
        ? Colors.white
        : item.isLocked
            ? AppColors.sidebarTextMuted.withValues(alpha: 0.5)
            : (_isHovered ? Colors.white : AppColors.sidebarTextMuted);

    Widget tileContent = MouseRegion(
      cursor: item.isLocked ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(
            horizontal: isCollapsed ? AppSpacing.sm : AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: AppRadius.radiusMd,
          ),
          child: Row(
            mainAxisAlignment:
                isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(
                isSelected && item.selectedIcon != null
                    ? item.selectedIcon!
                    : item.icon,
                color: foregroundColor,
                size: 20,
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (item.badge != null && item.badge!.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: item.badgeColor ??
                          (isSelected
                              ? Colors.white.withValues(alpha: 0.2)
                              : AppColors.primaryLight.withValues(alpha: 0.3)),
                      borderRadius: AppRadius.radiusSm,
                    ),
                    child: Text(
                      item.badge!,
                      style: TextStyle(
                        color: item.badgeTextColor ??
                            (isSelected ? Colors.white : AppColors.secondaryLight),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                if (item.isExternal) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.open_in_new,
                    size: 13,
                    color: foregroundColor.withValues(alpha: 0.7),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );

    if (item.tooltip != null || isCollapsed) {
      tileContent = Tooltip(
        message: item.tooltip ?? item.title,
        waitDuration: const Duration(milliseconds: 500),
        child: tileContent,
      );
    }

    return tileContent;
  }
}
