import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/session/session_data.dart';
import '../../../../core/storage/session_storage.dart';
import '../../../../shared/components/confirm_action_dialog.dart';
import '../../../../shared/components/portal_layout_shell.dart';
import '../../../../shared/components/portal_nav_item.dart';
import '../../../../shared/components/role_portal_configs.dart';
import '../../../../shared/models/user.dart';
import '../question_paper_generator/question_paper_generator_screen.dart';
import 'teacher_dashboard_home_view.dart';

/// Main Teacher Dashboard Screen for AceEdx Flutter Web frontend.
///
/// Implements `A.FE` and `A.a5F` from `public/web/main.dart.js`, wrapping the
/// 15 navigation modules in a responsive [PortalLayoutShell].
class TeacherDashboardScreen extends StatefulWidget {
  /// Optional initial tab title passed via route parameter or deep link.
  final String? initialTabTitle;

  /// Injected session storage instance.
  final SessionStorage? sessionStorage;

  /// Injected auth service instance.
  final AuthenticationService? authService;

  const TeacherDashboardScreen({
    super.key,
    this.initialTabTitle,
    this.sessionStorage,
    this.authService,
  });

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  late int _selectedTabIndex;
  late SessionData _sessionData;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadSession();
    _selectedTabIndex = _resolveInitialTabIndex(widget.initialTabTitle);
  }

  @override
  void didUpdateWidget(covariant TeacherDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTabTitle != widget.initialTabTitle &&
        widget.initialTabTitle != null) {
      final newIndex = _resolveInitialTabIndex(widget.initialTabTitle);
      if (newIndex != _selectedTabIndex) {
        setState(() {
          _selectedTabIndex = newIndex;
        });
      }
    }
  }

  void _loadSession() {
    if (widget.sessionStorage != null) {
      _sessionData = widget.sessionStorage!.readSession();
      _currentUser = User(
        id: _sessionData.userId ?? 0,
        name: _sessionData.userName ?? 'Teacher',
        email: _sessionData.userEmail ?? '',
        phone: _sessionData.userPhone,
        role: _sessionData.selectedRole ?? 'teacher',
        roles: _sessionData.userRoles ?? const ['teacher'],
        schoolId: _sessionData.schoolId,
        teacherId: _sessionData.teacherId,
        schoolName: _sessionData.schoolName,
        profilePhotoUrl: _sessionData.profilePhotoUrl,
        childrenName: _sessionData.childrenName,
      );
    } else {
      _sessionData = SessionData.empty;
      _currentUser = null;
    }
  }

  /// Resolves tab title (case-insensitive with alias mapping) to tab index.
  /// Matches forensic behavior in `A.cgL` & `A.cgJ`.
  int _resolveInitialTabIndex(String? tabTitle) {
    if (tabTitle == null || tabTitle.trim().isEmpty) return 0;
    final query = tabTitle.trim().toLowerCase();

    for (int i = 0; i < RolePortalConfigs.teacherNavItems.length; i++) {
      final item = RolePortalConfigs.teacherNavItems[i];
      final itemTitle = item.title.toLowerCase();

      if (itemTitle == query) return i;

      // Forensic aliases for AI Question Paper Generator
      if ((query == 'ai_question_paper' ||
              query == 'ai question paper' ||
              query == 'question_paper_generator' ||
              query == 'question paper generator' ||
              query == 'ai question paper generator') &&
          (item.id == 'teacher-ai-generator' || itemTitle == 'ai question paper generator')) {
        return i;
      }

      // Forensic alias: "ai teaching assistant" -> "ai lesson planner"
      if (query == 'ai teaching assistant' && itemTitle == 'ai lesson planner') {
        return i;
      }
    }
    return 0;
  }

  void _handleTabSelected(int index) {
    if (index < 0 || index >= RolePortalConfigs.teacherNavItems.length) return;

    final targetItem = RolePortalConfigs.teacherNavItems[index];

    // Special external launcher tab: "AceEdx Coach for teachers"
    if (targetItem.id == 'teacher-coach') {
      _showCoachExternalModal();
      return;
    }

    setState(() {
      _selectedTabIndex = index;
    });

    // Update query parameter ?tab=... without full page reload if GoRouter is active
    final tabName = targetItem.title;
    try {
      GoRouter.maybeOf(context)?.go(
        '${AppRoutes.teacherDashboard}?tab=${Uri.encodeComponent(tabName)}',
      );
    } catch (_) {}
  }

  void _showCoachExternalModal() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.open_in_new, color: Color(0xFF10B981)),
            SizedBox(width: 10),
            Text('AceEdx Coach for teachers'),
          ],
        ),
        content: const Text(
          'Opens the AceEdX Coach portal in your browser.\n\nPortal URL: https://teacher.aceedx.com/',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: const Text('Open teacher.aceedx.com'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await ConfirmActionDialog.show(
      context,
      title: 'Log Out',
      message: 'Are you sure you want to log out of your Teacher account?',
      confirmLabel: 'Log Out',
      isDestructive: true,
      icon: Icons.logout,
    );

    if (confirmed == true && mounted) {
      if (widget.authService != null) {
        await widget.authService!.logout();
      } else if (widget.sessionStorage != null) {
        await widget.sessionStorage!.clearSession();
      }

      if (mounted) {
        try {
          GoRouter.maybeOf(context)?.go('${AppRoutes.home}?skipAdminRedirect=true');
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = _currentUser?.name ??
        _sessionData.userName ??
        (_sessionData.userEmail?.split('@').first) ??
        'Teacher';

    final userEmail = _currentUser?.email ?? _sessionData.userEmail ?? '';
    final userId = _currentUser?.id.toString() ?? _sessionData.userId?.toString();

    final activeItem = RolePortalConfigs.teacherNavItems[_selectedTabIndex];

    return PortalLayoutShell(
      portalTitle: RolePortalConfigs.teacherTitle,
      brandSubtitle: 'AceEdx Platform',
      subtitleBadge: 'Teacher',
      navItems: RolePortalConfigs.teacherNavItems,
      selectedIndex: _selectedTabIndex,
      onIndexSelected: _handleTabSelected,
      user: _currentUser,
      userName: userName,
      userRole: 'Teacher',
      profilePhotoUrl: _currentUser?.profilePhotoUrl ?? _sessionData.profilePhotoUrl,
      onLogout: _handleLogout,
      body: _buildTabContent(activeItem, userName, userEmail, userId),
    );
  }

  Widget _buildTabContent(
    PortalNavItem activeItem,
    String userName,
    String userEmail,
    String? userId,
  ) {
    // Tab 0: Home Overview
    if (_selectedTabIndex == 0) {
      return TeacherDashboardHomeView(
        userName: userName,
        userId: userId,
        onTabSelected: _handleTabSelected,
      );
    }

    // Tab 6: AI Question Paper Generator (A.PM)
    if (_selectedTabIndex == 6 ||
        activeItem.id == 'teacher-ai-generator' ||
        activeItem.title.toLowerCase() == 'ai question paper generator') {
      return QuestionPaperGeneratorScreen(
        sessionStorage: widget.sessionStorage,
      );
    }

    // Special placeholder view for sub-modules (matching A.a5L / forensic structure)
    return _TeacherSubmodulePlaceholder(
      item: activeItem,
      onBackToHome: () => _handleTabSelected(0),
    );
  }
}

/// Generic Submodule Placeholder View (`A.a5L`).
///
/// Displayed when teacher navigates to secondary modules that are scheduled
/// for future implementation phases.
class _TeacherSubmodulePlaceholder extends StatelessWidget {
  final PortalNavItem item;
  final VoidCallback onBackToHome;

  const _TeacherSubmodulePlaceholder({
    required this.item,
    required this.onBackToHome,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(32.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  item.icon,
                  size: 36,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              if (item.badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: Text(
                    item.badge!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const Text(
                'This module is currently in development and will be activated in an upcoming release.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onBackToHome,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back to Dashboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
