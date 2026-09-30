import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/design_tokens.dart';
import '../models/user.dart';
import '../responsive/responsive_breakpoints.dart';
import 'mobile_drawer.dart';
import 'portal_header.dart';
import 'portal_nav_item.dart';
import 'portal_sidebar.dart';
import 'role_portal_configs.dart';

/// Master Responsive Layout Shell for AceEdx Authenticated Portals.
///
/// Derived from compiled `main.dart.js` portal shell patterns (`A.a5s`, `A.a4q`, `A.a5F`, `A.atz`, `A.awx`, `A.a36`).
/// Integrates the persistent top [PortalHeader], collapsible [PortalSidebar], [MobileDrawer],
/// and central scrollable responsive workspace area.
class PortalLayoutShell extends StatefulWidget {
  /// Portal display title (e.g. "Teacher Workspace", "School Admin Workspace").
  final String? portalTitle;

  /// Optional brand subtitle.
  final String brandSubtitle;

  /// Optional contextual badge on header (e.g., "Mathematics - Grade 10").
  final String? subtitleBadge;

  /// List of navigation items for the sidebar / drawer.
  final List<PortalNavItem>? navItems;

  /// Current active navigation index.
  final int selectedIndex;

  /// Callback when active index changes.
  final ValueChanged<int>? onIndexSelected;

  /// Callback when an item is tapped.
  final void Function(PortalNavItem item, int index)? onItemTap;

  /// Authenticated user entity.
  final User? user;

  /// Fallback user name if [user] is null.
  final String? userName;

  /// Fallback user role if [user] is null.
  final String? userRole;

  /// Fallback profile photo URL.
  final String? profilePhotoUrl;

  /// Unread notifications count.
  final int notificationCount;

  /// Shopping cart items count.
  final int cartCount;

  /// Whether to display the notification bell in the header.
  final bool showNotifications;

  /// Whether to display the cart shortcut in the header.
  final bool showCart;

  /// Whether to display the user avatar pill in the header.
  final bool showProfile;

  /// Whether to display the quick logout button.
  final bool showLogoutButton;

  /// Custom notification tap handler.
  final VoidCallback? onNotificationTap;

  /// Custom cart tap handler.
  final VoidCallback? onCartTap;

  /// Custom profile tap handler.
  final VoidCallback? onProfileTap;

  /// Custom logout handler.
  final VoidCallback? onLogout;

  /// Fixed sidebar width on desktop (defaults to 240px).
  final double sidebarWidth;

  /// Main workspace content widget.
  final Widget? body;

  /// Dynamic tab builder function based on active tab index.
  final Widget Function(BuildContext context, int activeIndex)? bodyBuilder;

  /// Custom background color for content workspace (defaults to [AppColors.workspaceBackground]).
  final Color? backgroundColor;

  /// Floating Action Button for the scaffold.
  final Widget? floatingActionButton;

  /// Custom bottom bar if needed.
  final Widget? bottomNavigationBar;

  const PortalLayoutShell({
    super.key,
    this.portalTitle,
    this.brandSubtitle = 'AceEdx Platform',
    this.subtitleBadge,
    this.navItems,
    this.selectedIndex = 0,
    this.onIndexSelected,
    this.onItemTap,
    this.user,
    this.userName,
    this.userRole,
    this.profilePhotoUrl,
    this.notificationCount = 0,
    this.cartCount = 0,
    this.showNotifications = true,
    this.showCart = true,
    this.showProfile = true,
    this.showLogoutButton = true,
    this.onNotificationTap,
    this.onCartTap,
    this.onProfileTap,
    this.onLogout,
    this.sidebarWidth = AppDimensions.sidebarWidthDesktop,
    this.body,
    this.bodyBuilder,
    this.backgroundColor,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  @override
  State<PortalLayoutShell> createState() => _PortalLayoutShellState();
}

class _PortalLayoutShellState extends State<PortalLayoutShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(covariant PortalLayoutShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      setState(() {
        _currentIndex = widget.selectedIndex;
      });
    }
  }

  void _handleIndexChange(int newIndex) {
    setState(() {
      _currentIndex = newIndex;
    });
    if (widget.onIndexSelected != null) {
      widget.onIndexSelected!(newIndex);
    }
  }

  String get _effectiveRole =>
      widget.user?.role ?? widget.userRole ?? 'teacher';

  String get _effectiveTitle =>
      widget.portalTitle ?? RolePortalConfigs.getTitleForRole(_effectiveRole);

  List<PortalNavItem> get _effectiveNavItems =>
      widget.navItems ?? RolePortalConfigs.getNavItemsForRole(_effectiveRole);

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final isTablet = context.isTablet;
    final showDesktopSidebar = !isMobile && !isTablet;

    final navItems = _effectiveNavItems;
    final title = _effectiveTitle;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: widget.backgroundColor ?? AppColors.workspaceBackground,
      drawer: isMobile || isTablet
          ? MobileDrawer(
              portalTitle: title,
              brandSubtitle: widget.brandSubtitle,
              items: navItems,
              selectedIndex: _currentIndex,
              onIndexSelected: _handleIndexChange,
              onItemTap: widget.onItemTap,
            )
          : null,
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: widget.bottomNavigationBar,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Persistent Desktop Sidebar
          if (showDesktopSidebar)
            PortalSidebar(
              portalTitle: title,
              brandSubtitle: widget.brandSubtitle,
              items: navItems,
              selectedIndex: _currentIndex,
              width: widget.sidebarWidth,
              onIndexSelected: _handleIndexChange,
              onItemTap: widget.onItemTap,
            ),

          // Main Content Pane with Header & Workspace
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header
                PortalHeader(
                  title: title,
                  subtitleBadge: widget.subtitleBadge,
                  user: widget.user,
                  userName: widget.userName,
                  userRole: widget.userRole,
                  profilePhotoUrl: widget.profilePhotoUrl,
                  notificationCount: widget.notificationCount,
                  cartCount: widget.cartCount,
                  showNotifications: widget.showNotifications,
                  showCart: widget.showCart,
                  showProfile: widget.showProfile,
                  showLogoutButton: widget.showLogoutButton,
                  onNotificationTap: widget.onNotificationTap,
                  onCartTap: widget.onCartTap,
                  onProfileTap: widget.onProfileTap,
                  onLogout: widget.onLogout,
                  onMenuToggle: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                ),

                // Workspace Body
                Expanded(
                  child: Container(
                    color: widget.backgroundColor ?? AppColors.workspaceBackground,
                    child: widget.bodyBuilder != null
                        ? widget.bodyBuilder!(context, _currentIndex)
                        : (widget.body ?? const SizedBox.shrink()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
