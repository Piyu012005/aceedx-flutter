import 'package:aceedx_flutter/app/theme/app_theme.dart';
import 'package:aceedx_flutter/shared/components/components.dart';
import 'package:aceedx_flutter/shared/models/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';


Future<void> _pumpApp(
  WidgetTester tester, {
  required Widget child,
  double width = 1200,
  double height = 800,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: child,
    ),
  );
}

void main() {
  group('Day 1 Step 3G: Portal Layout Shell Reconstruction Tests', () {
    // ─── 1. PortalNavItem Model & RolePortalConfigs ─────────────────────────
    test('PortalNavItem supports properties, copyWith, and equality', () {
      const item1 = PortalNavItem(
        id: 'tab-0',
        title: 'Dashboard',
        icon: Icons.dashboard,
        tabIndex: 0,
      );

      final item2 = item1.copyWith(title: 'Overview');
      expect(item2.id, 'tab-0');
      expect(item2.title, 'Overview');
      expect(item2.icon, Icons.dashboard);
      expect(item2.tabIndex, 0);

      const item3 = PortalNavItem(
        id: 'tab-0',
        title: 'Dashboard',
        icon: Icons.dashboard,
        tabIndex: 0,
      );
      expect(item1, equals(item3));
      expect(item1.hashCode, equals(item3.hashCode));
    });

    test('RolePortalConfigs provides correct titles and nav items for all roles', () {
      // Teacher
      expect(RolePortalConfigs.getTitleForRole('teacher'), 'Teacher Dashboard');
      expect(RolePortalConfigs.getNavItemsForRole('teacher').length, 15);
      expect(RolePortalConfigs.getNavItemsForRole('teacher').first.title, 'Dashboard');
      expect(RolePortalConfigs.getNavItemsForRole('teacher')[1].title, 'My Classes');

      // School Admin
      expect(RolePortalConfigs.getTitleForRole('school_admin'), 'School Admin Workspace');
      expect(RolePortalConfigs.getNavItemsForRole('school_admin').length, 15);
      expect(RolePortalConfigs.getNavItemsForRole('school_admin')[1].title, 'Register School / Profile');

      // Principal
      expect(RolePortalConfigs.getTitleForRole('principal'), 'Principal Workspace');
      expect(RolePortalConfigs.getNavItemsForRole('principal').length, 9);
      expect(RolePortalConfigs.getNavItemsForRole('principal')[1].title, 'Question Paper Approvals');

      // Super Admin
      expect(RolePortalConfigs.getTitleForRole('super_admin'), 'Super Admin Platform');
      expect(RolePortalConfigs.getNavItemsForRole('super_admin').length, 16);

      // Student
      expect(RolePortalConfigs.getTitleForRole('student'), 'Student Portal');
      expect(RolePortalConfigs.getNavItemsForRole('student').length, 9);

      // Parent
      expect(RolePortalConfigs.getTitleForRole('parent'), 'Parent Portal');
      expect(RolePortalConfigs.getNavItemsForRole('parent').length, 6);
      expect(RolePortalConfigs.getNavItemsForRole('parent').last.isExternal, isTrue);
      expect(RolePortalConfigs.getNavItemsForRole('parent').last.externalUrl, 'https://parent.aceedx.com/');
    });

    // ─── 2. ConfirmActionDialog Tests ───────────────────────────────────────
    testWidgets('ConfirmActionDialog renders title, message and triggers callbacks',
        (WidgetTester tester) async {
      bool confirmed = false;
      bool cancelled = false;

      await _pumpApp(
        tester,
        child: ConfirmActionDialog(
          title: 'Delete Question Paper',
          message: 'Are you sure you want to permanently delete this paper?',
          confirmLabel: 'Delete',
          cancelLabel: 'Cancel',
          isDestructive: true,
          icon: Icons.delete_outline,
          onConfirm: () => confirmed = true,
          onCancel: () => cancelled = true,
        ),
      );

      expect(find.text('Delete Question Paper'), findsOneWidget);
      expect(find.text('Are you sure you want to permanently delete this paper?'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pump();
      expect(cancelled, isTrue);

      await tester.tap(find.text('Delete'));
      await tester.pump();
      expect(confirmed, isTrue);
    });

    // ─── 3. PortalHeader Tests ──────────────────────────────────────────────
    testWidgets('PortalHeader renders title, badges, avatar initials and action callbacks',
        (WidgetTester tester) async {
      bool notifTapped = false;
      bool cartTapped = false;
      bool logoutTapped = false;

      final testUser = const User(
        id: 101,
        name: 'Dr. Sarah Smith',
        email: 'sarah@aceedx.com',
        role: 'Teacher',
      );

      await _pumpApp(
        tester,
        width: 1200,
        child: Scaffold(
          appBar: PortalHeader(
            title: 'Teacher Workspace',
            subtitleBadge: 'Mathematics - Grade 10',
            user: testUser,
            notificationCount: 5,
            cartCount: 2,
            onNotificationTap: () => notifTapped = true,
            onCartTap: () => cartTapped = true,
            onLogout: () => logoutTapped = true,
          ),
        ),
      );

      expect(find.text('Teacher Workspace'), findsOneWidget);
      expect(find.text('Mathematics - Grade 10'), findsOneWidget);
      expect(find.text('Dr. Sarah Smith'), findsOneWidget);
      expect(find.text('DS'), findsOneWidget); // Initials for Dr. Sarah

      // Notification badge count '5'
      expect(find.text('5'), findsOneWidget);
      // Cart badge count '2'
      expect(find.text('2'), findsOneWidget);

      // Tap notifications
      await tester.tap(find.byTooltip('Notifications'));
      await tester.pump();
      expect(notifTapped, isTrue);

      // Tap cart
      await tester.tap(find.byTooltip('Shopping Cart'));
      await tester.pump();
      expect(cartTapped, isTrue);

      // Tap logout
      await tester.tap(find.byTooltip('Log Out'));
      await tester.pump();
      expect(logoutTapped, isTrue);
    });

    testWidgets('PortalHeader renders hamburger button on mobile screens (<900px)',
        (WidgetTester tester) async {
      bool menuTapped = false;

      await _pumpApp(
        tester,
        width: 500, // Mobile width
        child: Scaffold(
          appBar: PortalHeader(
            title: 'Teacher Workspace',
            userName: 'John Doe',
            userRole: 'Teacher',
            onMenuToggle: () => menuTapped = true,
          ),
        ),
      );

      expect(find.byIcon(Icons.menu), findsOneWidget);
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pump();
      expect(menuTapped, isTrue);
    });

    // ─── 4. PortalSidebar Tests ─────────────────────────────────────────────
    testWidgets('PortalSidebar renders brand header, items list and fires selection callbacks',
        (WidgetTester tester) async {
      int selectedTab = 0;

      final items = [
        const PortalNavItem(
          id: 'tab-0',
          title: 'Dashboard Overview',
          icon: Icons.dashboard,
          tabIndex: 0,
        ),
        const PortalNavItem(
          id: 'tab-1',
          title: 'AI Generator',
          icon: Icons.auto_awesome,
          tabIndex: 1,
          badge: 'AI',
        ),
        const PortalNavItem(
          id: 'tab-2',
          title: 'Attendance',
          icon: Icons.how_to_reg,
          tabIndex: 2,
        ),
      ];

      await _pumpApp(
        tester,
        width: 1200,
        child: Scaffold(
          body: PortalSidebar(
            portalTitle: 'Teacher Workspace',
            items: items,
            selectedIndex: 0,
            onIndexSelected: (idx) => selectedTab = idx,
          ),
        ),
      );

      expect(find.text('Teacher Workspace'), findsOneWidget);
      expect(find.text('Dashboard Overview'), findsOneWidget);
      expect(find.text('AI Generator'), findsOneWidget);
      expect(find.text('AI'), findsOneWidget); // Badge
      expect(find.text('Attendance'), findsOneWidget);

      // Tap on AI Generator (Tab 1)
      await tester.tap(find.text('AI Generator'));
      await tester.pump();
      expect(selectedTab, 1);
    });

    // ─── 5. PortalLayoutShell Full Integration Tests ────────────────────────
    testWidgets('PortalLayoutShell renders sidebar and content on desktop and switches tabs',
        (WidgetTester tester) async {
      int currentTab = 0;

      await _pumpApp(
        tester,
        width: 1200,
        child: PortalLayoutShell(
          portalTitle: 'Teacher Workspace',
          subtitleBadge: 'Physics - Grade 12',
          userName: 'Albert Einstein',
          userRole: 'Teacher',
          selectedIndex: currentTab,
          onIndexSelected: (idx) => currentTab = idx,
          bodyBuilder: (context, activeIndex) {
            return Center(
              child: Text('Active Content: Tab $activeIndex'),
            );
          },
        ),
      );

      // Verify desktop layout
      expect(find.text('Teacher Workspace'), findsNWidgets(2)); // In Sidebar and Header
      expect(find.text('Physics - Grade 12'), findsOneWidget);
      expect(find.text('Active Content: Tab 0'), findsOneWidget);

      // Tap on another tab in sidebar (My Classes is at index 1)
      await tester.tap(find.text('My Classes'));
      await tester.pumpAndSettle();

      expect(currentTab, 1);
      expect(find.text('Active Content: Tab 1'), findsOneWidget);
    });

    testWidgets('PortalLayoutShell shows MobileDrawer on mobile viewports (<600px)',
        (WidgetTester tester) async {
      await _pumpApp(
        tester,
        width: 450, // Mobile width
        child: const PortalLayoutShell(
          portalTitle: 'Principal Workspace',
          userRole: 'Principal',
          userName: 'Principal Skinner',
          body: Center(child: Text('Principal Content Body')),
        ),
      );

      expect(find.text('Principal Content Body'), findsOneWidget);
      expect(find.byIcon(Icons.menu), findsOneWidget);

      // Open mobile drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Drawer should now be visible with navigation items
      expect(find.text('Academic Command Center'), findsOneWidget);
      expect(find.text('Question Paper Approvals'), findsOneWidget);
    });
  });
}
