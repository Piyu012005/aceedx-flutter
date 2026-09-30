import 'package:flutter/material.dart';

import '../../app/router/app_routes.dart';
import 'portal_nav_item.dart';

/// Predefined navigation configurations for all AceEdx authenticated role portals.
///
/// Derived from compiled `main.dart.js` (Portal States `a5F`, `a4q`, `atz`, `a5s`, `awx`, `a36`, `Lz`)
/// and forensic specifications in `PORTAL_STRUCTURE.md`.
class RolePortalConfigs {
  const RolePortalConfigs._();

  // ─── 1. TEACHER PORTAL (`/teacher-dashboard`) ─────────────────────────────
  static const String teacherTitle = 'Teacher Dashboard';
  static const String teacherDefaultSubtitle = 'Mathematics - Grade 10';

  static final List<PortalNavItem> teacherNavItems = [
    const PortalNavItem(
      id: 'teacher-dashboard',
      tabIndex: 0,
      title: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    const PortalNavItem(
      id: 'teacher-my-classes',
      tabIndex: 1,
      title: 'My Classes',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      badge: 'Upcoming',
    ),
    const PortalNavItem(
      id: 'teacher-timetable',
      tabIndex: 2,
      title: 'Timetable',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
    ),
    const PortalNavItem(
      id: 'teacher-attendance',
      tabIndex: 3,
      title: 'Attendance',
      icon: Icons.how_to_reg_outlined,
      selectedIcon: Icons.how_to_reg,
    ),
    const PortalNavItem(
      id: 'teacher-assignments',
      tabIndex: 4,
      title: 'Assignments',
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment,
      badge: 'Upcoming',
    ),
    const PortalNavItem(
      id: 'teacher-ai-report-card',
      tabIndex: 5,
      title: 'AI Report Card Generator',
      icon: Icons.assessment_outlined,
      selectedIcon: Icons.assessment,
      badge: 'AI',
    ),
    const PortalNavItem(
      id: 'teacher-ai-generator',
      tabIndex: 6,
      title: 'AI Question Paper Generator',
      icon: Icons.auto_awesome_outlined,
      selectedIcon: Icons.auto_awesome,
      badge: 'AI',
    ),
    const PortalNavItem(
      id: 'teacher-evaluate-paper',
      tabIndex: 7,
      title: 'Evaluate Question Paper',
      icon: Icons.fact_check_outlined,
      selectedIcon: Icons.fact_check,
    ),
    const PortalNavItem(
      id: 'teacher-my-orders',
      tabIndex: 8,
      title: 'My Orders',
      icon: Icons.shopping_bag_outlined,
      selectedIcon: Icons.shopping_bag,
      route: AppRoutes.purchaseHistory,
    ),
    const PortalNavItem(
      id: 'teacher-featured-ads',
      tabIndex: 9,
      title: 'Featured Ads',
      icon: Icons.campaign_outlined,
      selectedIcon: Icons.campaign,
    ),
    const PortalNavItem(
      id: 'teacher-ai-lesson-planner',
      tabIndex: 10,
      title: 'AI Lesson Planner',
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
      badge: 'AI',
    ),
    const PortalNavItem(
      id: 'teacher-coach',
      tabIndex: 11,
      title: 'AceEdx Coach for teachers',
      icon: Icons.support_agent_outlined,
      selectedIcon: Icons.support_agent,
      isExternal: true,
    ),
    const PortalNavItem(
      id: 'teacher-announcements',
      tabIndex: 12,
      title: 'Announcements',
      icon: Icons.campaign_outlined,
      selectedIcon: Icons.campaign,
    ),
    const PortalNavItem(
      id: 'teacher-liked-schools',
      tabIndex: 13,
      title: 'Liked Schools',
      icon: Icons.favorite_border,
      selectedIcon: Icons.favorite,
    ),
    const PortalNavItem(
      id: 'teacher-annual-calendar',
      tabIndex: 14,
      title: 'Annual Calendar',
      icon: Icons.calendar_today_outlined,
      selectedIcon: Icons.calendar_today,
    ),
  ];

  // ─── 2. SCHOOL ADMIN PORTAL (`/school-dashboard`) ─────────────────────────
  static const String schoolAdminTitle = 'School Admin Workspace';

  static final List<PortalNavItem> schoolAdminNavItems = [
    const PortalNavItem(
      id: 'school-dashboard-overview',
      tabIndex: 0,
      title: 'Dashboard Overview',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    const PortalNavItem(
      id: 'school-management-profile',
      tabIndex: 1,
      title: 'Register School / Profile',
      icon: Icons.domain_outlined,
      selectedIcon: Icons.domain,
      route: AppRoutes.schoolManagement,
    ),
    const PortalNavItem(
      id: 'school-teachers',
      tabIndex: 2,
      title: 'Teachers',
      icon: Icons.badge_outlined,
      selectedIcon: Icons.badge,
    ),
    const PortalNavItem(
      id: 'school-add-textbooks',
      tabIndex: 3,
      title: 'Add Textbooks',
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
    ),
    const PortalNavItem(
      id: 'school-attendance-mgmt',
      tabIndex: 4,
      title: 'Attendance Management',
      icon: Icons.how_to_reg_outlined,
      selectedIcon: Icons.how_to_reg,
    ),
    const PortalNavItem(
      id: 'school-timetable-settings',
      tabIndex: 5,
      title: 'Timetable Settings',
      icon: Icons.schedule_outlined,
      selectedIcon: Icons.schedule,
    ),
    const PortalNavItem(
      id: 'school-fees-mgmt',
      tabIndex: 6,
      title: 'Fees Management',
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
    ),
    const PortalNavItem(
      id: 'school-announcements',
      tabIndex: 7,
      title: 'Announcements',
      icon: Icons.campaign_outlined,
      selectedIcon: Icons.campaign,
    ),
    const PortalNavItem(
      id: 'school-annual-calendar',
      tabIndex: 8,
      title: 'Annual Calendar',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
    ),
    const PortalNavItem(
      id: 'school-pricing-modules',
      tabIndex: 9,
      title: 'Pricing Modules',
      icon: Icons.layers_outlined,
      selectedIcon: Icons.layers,
      route: AppRoutes.pricingModuleSchool,
    ),
    const PortalNavItem(
      id: 'school-module-payments',
      tabIndex: 10,
      title: 'Module Payment History',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
    ),
    const PortalNavItem(
      id: 'school-become-featured',
      tabIndex: 11,
      title: 'Become Featured',
      icon: Icons.verified_outlined,
      selectedIcon: Icons.verified,
    ),
    const PortalNavItem(
      id: 'school-advertise',
      tabIndex: 12,
      title: 'Advertise',
      icon: Icons.add_business_outlined,
      selectedIcon: Icons.add_business,
      route: AppRoutes.advertisementForm,
    ),
    const PortalNavItem(
      id: 'school-featured-events',
      tabIndex: 13,
      title: 'Featured Events',
      icon: Icons.event_outlined,
      selectedIcon: Icons.event,
    ),
    const PortalNavItem(
      id: 'school-rules-policy',
      tabIndex: 14,
      title: 'Rules and Policy',
      icon: Icons.gavel_outlined,
      selectedIcon: Icons.gavel,
    ),
  ];

  // ─── 3. PRINCIPAL PORTAL (`/principal-dashboard`) ─────────────────────────
  static const String principalTitle = 'Principal Workspace';

  static final List<PortalNavItem> principalNavItems = [
    const PortalNavItem(
      id: 'principal-command-center',
      tabIndex: 0,
      title: 'Academic Command Center',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    const PortalNavItem(
      id: 'principal-paper-approvals',
      tabIndex: 1,
      title: 'Question Paper Approvals',
      icon: Icons.fact_check_outlined,
      selectedIcon: Icons.fact_check,
      badge: 'Queue',
    ),
    const PortalNavItem(
      id: 'principal-attendance-mgmt',
      tabIndex: 2,
      title: 'Attendance Management',
      icon: Icons.how_to_reg_outlined,
      selectedIcon: Icons.how_to_reg,
    ),
    const PortalNavItem(
      id: 'principal-fee-mgmt',
      tabIndex: 3,
      title: 'Fee Management',
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
    ),
    const PortalNavItem(
      id: 'principal-timetable',
      tabIndex: 4,
      title: 'Timetable',
      icon: Icons.schedule_outlined,
      selectedIcon: Icons.schedule,
    ),
    const PortalNavItem(
      id: 'principal-teachers',
      tabIndex: 5,
      title: 'Teachers',
      icon: Icons.badge_outlined,
      selectedIcon: Icons.badge,
    ),
    const PortalNavItem(
      id: 'principal-school-profile',
      tabIndex: 6,
      title: 'School Profile',
      icon: Icons.domain_outlined,
      selectedIcon: Icons.domain,
    ),
    const PortalNavItem(
      id: 'principal-annual-calendar',
      tabIndex: 7,
      title: 'Annual Calendar & Bus',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
    ),
    const PortalNavItem(
      id: 'principal-rules-policy',
      tabIndex: 8,
      title: 'Rules and Policy',
      icon: Icons.gavel_outlined,
      selectedIcon: Icons.gavel,
    ),
  ];

  // ─── 4. SUPER ADMIN PORTAL (`/super-admin-dashboard`) ─────────────────────
  static const String superAdminTitle = 'Super Admin Platform';

  static final List<PortalNavItem> superAdminNavItems = [
    const PortalNavItem(
      id: 'super-admin-dashboard',
      tabIndex: 0,
      title: 'Master Dashboard KPIs',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    const PortalNavItem(
      id: 'super-admin-add-modules',
      tabIndex: 1,
      title: 'Add Pricing Modules',
      icon: Icons.add_chart_outlined,
      selectedIcon: Icons.add_chart,
    ),
    const PortalNavItem(
      id: 'super-admin-payment-history',
      tabIndex: 2,
      title: 'Pricing Module Payment History',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
    ),
    const PortalNavItem(
      id: 'super-admin-module-toggle',
      tabIndex: 3,
      title: 'Pricing Module Enable/Disable',
      icon: Icons.toggle_on_outlined,
      selectedIcon: Icons.toggle_on,
    ),
    const PortalNavItem(
      id: 'super-admin-bulk-emails',
      tabIndex: 4,
      title: 'Send Bulk Emails',
      icon: Icons.forward_to_inbox_outlined,
      selectedIcon: Icons.forward_to_inbox,
    ),
    const PortalNavItem(
      id: 'super-admin-manage-schools',
      tabIndex: 5,
      title: 'Manage Schools',
      icon: Icons.domain_outlined,
      selectedIcon: Icons.domain,
    ),
    const PortalNavItem(
      id: 'super-admin-manage-marketplace',
      tabIndex: 6,
      title: 'Manage Marketplace',
      icon: Icons.storefront_outlined,
      selectedIcon: Icons.storefront,
    ),
    const PortalNavItem(
      id: 'super-admin-manage-website',
      tabIndex: 7,
      title: 'Manage Website',
      icon: Icons.web_outlined,
      selectedIcon: Icons.web,
    ),
    const PortalNavItem(
      id: 'super-admin-feedback',
      tabIndex: 8,
      title: 'Manage Feedback & Testimonials',
      icon: Icons.reviews_outlined,
      selectedIcon: Icons.reviews,
    ),
    const PortalNavItem(
      id: 'super-admin-leads',
      tabIndex: 9,
      title: 'Manage Leads',
      icon: Icons.leaderboard_outlined,
      selectedIcon: Icons.leaderboard,
    ),
    const PortalNavItem(
      id: 'super-admin-visitors-log',
      tabIndex: 10,
      title: 'Visitors Log',
      icon: Icons.remove_red_eye_outlined,
      selectedIcon: Icons.remove_red_eye,
    ),
    const PortalNavItem(
      id: 'super-admin-demo-videos',
      tabIndex: 11,
      title: 'Demo Videos',
      icon: Icons.video_library_outlined,
      selectedIcon: Icons.video_library,
    ),
    const PortalNavItem(
      id: 'super-admin-manage-parents',
      tabIndex: 12,
      title: 'Manage Parents',
      icon: Icons.family_restroom_outlined,
      selectedIcon: Icons.family_restroom,
    ),
    const PortalNavItem(
      id: 'super-admin-manage-students',
      tabIndex: 13,
      title: 'Manage Students',
      icon: Icons.school_outlined,
      selectedIcon: Icons.school,
    ),
    const PortalNavItem(
      id: 'super-admin-manage-teachers',
      tabIndex: 14,
      title: 'Manage Teachers',
      icon: Icons.badge_outlined,
      selectedIcon: Icons.badge,
    ),
    const PortalNavItem(
      id: 'super-admin-manage-vendors',
      tabIndex: 15,
      title: 'Manage Vendors',
      icon: Icons.local_shipping_outlined,
      selectedIcon: Icons.local_shipping,
    ),
  ];

  // ─── 5. STUDENT PORTAL (`/student-dashboard`) ─────────────────────────────
  static const String studentTitle = 'Student Portal';

  static final List<PortalNavItem> studentNavItems = [
    const PortalNavItem(
      id: 'student-dashboard',
      tabIndex: 0,
      title: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    const PortalNavItem(
      id: 'student-personality-test',
      tabIndex: 1,
      title: 'Personality Test',
      icon: Icons.psychology_outlined,
      selectedIcon: Icons.psychology,
    ),
    const PortalNavItem(
      id: 'student-gradebook',
      tabIndex: 2,
      title: 'Gradebook',
      icon: Icons.grading_outlined,
      selectedIcon: Icons.grading,
    ),
    const PortalNavItem(
      id: 'student-attendance',
      tabIndex: 3,
      title: 'Attendance',
      icon: Icons.how_to_reg_outlined,
      selectedIcon: Icons.how_to_reg,
    ),
    const PortalNavItem(
      id: 'student-assignments',
      tabIndex: 4,
      title: 'Assignments',
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment,
    ),
    const PortalNavItem(
      id: 'student-fees',
      tabIndex: 5,
      title: 'Fees',
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
    ),
    const PortalNavItem(
      id: 'student-annual-calendar',
      tabIndex: 6,
      title: 'Annual Calendar',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
    ),
    const PortalNavItem(
      id: 'student-liked-schools',
      tabIndex: 7,
      title: 'Liked Schools',
      icon: Icons.favorite_border,
      selectedIcon: Icons.favorite,
    ),
    const PortalNavItem(
      id: 'student-my-orders',
      tabIndex: 8,
      title: 'My Orders',
      icon: Icons.shopping_bag_outlined,
      selectedIcon: Icons.shopping_bag,
      route: AppRoutes.purchaseHistory,
    ),
  ];

  // ─── 6. PARENT PORTAL (`/parent-dashboard`) ───────────────────────────────
  static const String parentTitle = 'Parent Portal';

  static final List<PortalNavItem> parentNavItems = [
    const PortalNavItem(
      id: 'parent-dashboard',
      tabIndex: 0,
      title: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    const PortalNavItem(
      id: 'parent-gradebook',
      tabIndex: 1,
      title: 'Gradebook',
      icon: Icons.grading_outlined,
      selectedIcon: Icons.grading,
    ),
    const PortalNavItem(
      id: 'parent-my-orders',
      tabIndex: 2,
      title: 'My Orders',
      icon: Icons.shopping_bag_outlined,
      selectedIcon: Icons.shopping_bag,
      route: AppRoutes.purchaseHistory,
    ),
    const PortalNavItem(
      id: 'parent-liked-schools',
      tabIndex: 3,
      title: 'Liked Schools',
      icon: Icons.favorite_border,
      selectedIcon: Icons.favorite,
    ),
    const PortalNavItem(
      id: 'parent-annual-calendar',
      tabIndex: 4,
      title: 'Annual Calendar',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
    ),
    const PortalNavItem(
      id: 'parent-planner',
      tabIndex: 5,
      title: 'Parents Planner',
      icon: Icons.open_in_new,
      isExternal: true,
      externalUrl: 'https://parent.aceedx.com/',
    ),
  ];

  /// Resolves the portal title for a given role string.
  static String getTitleForRole(String? role) {
    if (role == null) return 'AceEdx Workspace';
    final normalized = role.trim().toLowerCase().replaceAll('_', ' ');
    if (normalized.contains('teacher')) return teacherTitle;
    if (normalized.contains('school')) return schoolAdminTitle;
    if (normalized.contains('principal')) return principalTitle;
    if (normalized.contains('super')) return superAdminTitle;
    if (normalized.contains('student')) return studentTitle;
    if (normalized.contains('parent')) return parentTitle;
    return 'AceEdx Workspace';
  }

  /// Resolves the default navigation items list for a given role string.
  static List<PortalNavItem> getNavItemsForRole(String? role) {
    if (role == null) return teacherNavItems;
    final normalized = role.trim().toLowerCase().replaceAll('_', ' ');
    if (normalized.contains('teacher')) return teacherNavItems;
    if (normalized.contains('school')) return schoolAdminNavItems;
    if (normalized.contains('principal')) return principalNavItems;
    if (normalized.contains('super')) return superAdminNavItems;
    if (normalized.contains('student')) return studentNavItems;
    if (normalized.contains('parent')) return parentNavItems;
    return teacherNavItems;
  }
}
