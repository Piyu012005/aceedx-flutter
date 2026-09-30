import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/design_tokens.dart';
import '../models/user.dart';
import '../responsive/responsive_breakpoints.dart';
import 'confirm_action_dialog.dart';

/// Top Header Bar for AceEdx Portal Layout Shells.
///
/// Derived from compiled `main.dart.js` header builder (`bk4` / `aRo`).
/// Height: 70px (`AppDimensions.headerHeight`).
class PortalHeader extends StatelessWidget implements PreferredSizeWidget {
  /// Portal title or breadcrumb displayed on the left.
  final String title;

  /// Optional contextual subtitle or badge (e.g., "Mathematics - Grade 10", "Principal").
  final String? subtitleBadge;

  /// Current authenticated user (optional, displayed in avatar pill).
  final User? user;

  /// Fallback user display name if [user] is null.
  final String? userName;

  /// Fallback user role display if [user] is null.
  final String? userRole;

  /// Fallback profile photo URL if [user] is null.
  final String? profilePhotoUrl;

  /// Number of unread notifications to display on bell badge.
  final int notificationCount;

  /// Number of items in shopping cart to display on cart badge.
  final int cartCount;

  /// Whether to show the notifications bell button.
  final bool showNotifications;

  /// Whether to show the cart icon button.
  final bool showCart;

  /// Whether to show the user avatar & profile menu.
  final bool showProfile;

  /// Whether to show the quick logout button.
  final bool showLogoutButton;

  /// Custom notification tap callback.
  final VoidCallback? onNotificationTap;

  /// Custom cart tap callback.
  final VoidCallback? onCartTap;

  /// Custom profile tap callback.
  final VoidCallback? onProfileTap;

  /// Custom logout callback.
  final VoidCallback? onLogout;

  /// Custom drawer toggle callback (defaults to opening scaffold drawer).
  final VoidCallback? onMenuToggle;

  /// Additional custom actions to append to the right side.
  final List<Widget>? customActions;

  /// Leading custom widget (replaces default hamburger/title).
  final Widget? leading;

  const PortalHeader({
    super.key,
    required this.title,
    this.subtitleBadge,
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
    this.onMenuToggle,
    this.customActions,
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(AppDimensions.headerHeight);

  String get _displayName => user?.name ?? userName ?? 'User';
  String get _displayRole => user?.role ?? userRole ?? '';
  String? get _avatarUrl => user?.profilePhotoUrl ?? profilePhotoUrl;

  String get _initials {
    final name = _displayName.trim();
    if (name.isEmpty) return 'U';
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  void _handleLogout(BuildContext context) async {
    if (onLogout != null) {
      onLogout!();
      return;
    }

    final confirmed = await ConfirmActionDialog.show(
      context,
      title: 'Confirm Logout',
      message: 'Are you sure you want to log out of your AceEdx account?',
      confirmLabel: 'Log Out',
      isDestructive: true,
      icon: Icons.logout,
    );

    if (confirmed == true && context.mounted) {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final isTablet = context.isTablet;
    final showCompact = isMobile || isTablet;

    return Container(
      height: AppDimensions.headerHeight,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1.0),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Menu hamburger on mobile/tablet or custom leading
          if (leading != null)
            leading!
          else if (showCompact)
            IconButton(
              icon: const Icon(Icons.menu, color: AppColors.textPrimary),
              tooltip: 'Toggle Navigation Menu',
              onPressed: onMenuToggle ??
                  () {
                    Scaffold.maybeOf(context)?.openDrawer();
                  },
            ),

          if (showCompact && leading == null)
            const SizedBox(width: AppSpacing.sm),

          // Title & Breadcrumb
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headlineSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (subtitleBadge != null && subtitleBadge!.isNotEmpty && !showCompact) ...[
                  const SizedBox(width: AppSpacing.md),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentBackground,
                        borderRadius: AppRadius.radiusSm,
                        border: Border.all(
                          color: AppColors.primaryLight.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        subtitleBadge!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          // Right Actions
          ...?customActions,

          // Notifications Bell
          if (showNotifications)
            _buildIconButtonWithBadge(
              context: context,
              icon: Icons.notifications_none_outlined,
              count: notificationCount,
              tooltip: 'Notifications',
              onTap: () {
                if (onNotificationTap != null) {
                  onNotificationTap!();
                } else {
                  context.push(AppRoutes.homeAnnouncements);
                }
              },
            ),

          // Shopping Cart Shortcut
          if (showCart)
            _buildIconButtonWithBadge(
              context: context,
              icon: Icons.shopping_cart_outlined,
              count: cartCount,
              tooltip: 'Shopping Cart',
              onTap: () {
                if (onCartTap != null) {
                  onCartTap!();
                } else {
                  context.push(AppRoutes.cart);
                }
              },
            ),

          if (showNotifications || showCart)
            const SizedBox(width: AppSpacing.sm),

          // User Profile Pill & Dropdown
          if (showProfile) _buildUserProfilePill(context, showCompact),

          // Direct Logout Button on desktop
          if (showLogoutButton && !showCompact) ...[
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              icon: const Icon(Icons.logout, color: AppColors.textMuted, size: 20),
              tooltip: 'Log Out',
              onPressed: () => _handleLogout(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIconButtonWithBadge({
    required BuildContext context,
    required IconData icon,
    required int count,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(icon, color: AppColors.textSecondary, size: 22),
          tooltip: tooltip,
          onPressed: onTap,
        ),
        if (count > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUserProfilePill(BuildContext context, bool isCompact) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 52),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.radiusMd,
        side: const BorderSide(color: AppColors.border),
      ),
      elevation: 8.0,
      color: AppColors.surface,
      tooltip: 'User Menu',
      onSelected: (value) {
        switch (value) {
          case 'profile':
            if (onProfileTap != null) {
              onProfileTap!();
            } else {
              context.push(AppRoutes.editProfile);
            }
            break;
          case 'history':
            context.push(AppRoutes.purchaseHistory);
            break;
          case 'logout':
            _handleLogout(context);
            break;
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _displayName,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (_displayRole.isNotEmpty)
                Text(
                  _displayRole.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const Divider(height: 16),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 18, color: AppColors.textSecondary),
              SizedBox(width: AppSpacing.sm),
              Text('Edit Profile', style: AppTypography.bodyMedium),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'history',
          child: Row(
            children: [
              Icon(Icons.receipt_long_outlined, size: 18, color: AppColors.textSecondary),
              SizedBox(width: AppSpacing.sm),
              Text('Purchase History', style: AppTypography.bodyMedium),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 18, color: AppColors.error),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Log Out',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.workspaceBackground,
          borderRadius: AppRadius.radiusFull,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                  ? NetworkImage(_avatarUrl!)
                  : null,
              child: _avatarUrl == null || _avatarUrl!.isEmpty
                  ? Text(
                      _initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            if (!isCompact) ...[
              const SizedBox(width: AppSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (_displayRole.isNotEmpty)
                      Text(
                        _displayRole,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textMuted,
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
