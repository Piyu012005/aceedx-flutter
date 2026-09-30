import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/responsive/responsive_breakpoints.dart';

/// Main Overview Tab Content for Teacher Dashboard.
///
/// Faithfully reproduces compiled `A.akn` (`TeacherDashboardHomeView`),
/// `A.a0H` / `A.a0I` (Demo Banner), `A.Os` (Quick Action Stat Cards),
/// and `A.aqz` (Recommended Modules Checklist) from AceEdx `main.dart.js`.
class TeacherDashboardHomeView extends StatefulWidget {
  /// Name of the authenticated teacher.
  final String userName;

  /// User ID for preferences keying.
  final String? userId;

  /// Callback when a quick action card requests switching to a tab.
  final ValueChanged<int>? onTabSelected;

  const TeacherDashboardHomeView({
    super.key,
    required this.userName,
    this.userId,
    this.onTabSelected,
  });

  @override
  State<TeacherDashboardHomeView> createState() => _TeacherDashboardHomeViewState();
}

class _TeacherDashboardHomeViewState extends State<TeacherDashboardHomeView> {
  bool _isBannerDismissed = false;
  bool _isBannerLoaded = false;

  String get _bannerStorageKey {
    final uid = widget.userId?.trim();
    return 'teacher_demo_banner_hidden_v1_${(uid != null && uid.isNotEmpty) ? uid : "anon"}';
  }

  @override
  void initState() {
    super.initState();
    _loadBannerDismissedState();
  }

  @override
  void didUpdateWidget(covariant TeacherDashboardHomeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _loadBannerDismissedState();
    }
  }

  Future<void> _loadBannerDismissedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDismissed = prefs.getBool(_bannerStorageKey) ?? false;
      if (mounted) {
        setState(() {
          _isBannerDismissed = isDismissed;
          _isBannerLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isBannerDismissed = false;
          _isBannerLoaded = true;
        });
      }
    }
  }

  Future<void> _handleDismissBanner() async {
    setState(() {
      _isBannerDismissed = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_bannerStorageKey, true);
    } catch (_) {
      // Best-effort storage persistence
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final isTablet = context.isTablet;

    final double contentPadding = isMobile
        ? 16.0
        : (isTablet ? 24.0 : 32.0);

    return SingleChildScrollView(
      padding: EdgeInsets.all(contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Teacher Demo Alert Banner (dismissible)
          if (_isBannerLoaded && !_isBannerDismissed) ...[
            _TeacherDemoBanner(
              isMobile: isMobile,
              onDismiss: _handleDismissBanner,
            ),
            const SizedBox(height: 14),
          ],

          // 2. Welcome Emerald Gradient Card
          _TeacherWelcomeBanner(
            userName: widget.userName,
            isMobile: isMobile,
          ),
          const SizedBox(height: 18),

          // 3. Quick Action Cards Row / Wrap
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _TeacherQuickActionCard(
                title: 'My Classes',
                subtitle: 'Students & sections',
                icon: Icons.people_outline,
                accentColor: const Color(0xFF2563EB),
                isUpcoming: true,
                isMobile: isMobile,
                onTap: () => widget.onTabSelected?.call(1),
              ),
              _TeacherQuickActionCard(
                title: 'Timetable',
                subtitle: 'Today’s schedule',
                icon: Icons.calendar_month_outlined,
                accentColor: const Color(0xFF8B5CF6),
                isUpcoming: true,
                isMobile: isMobile,
                onTap: () => widget.onTabSelected?.call(2),
              ),
              _TeacherQuickActionCard(
                title: 'Announcements',
                subtitle: 'School updates',
                icon: Icons.campaign_outlined,
                accentColor: const Color(0xFFF59E0B),
                isUpcoming: false,
                isMobile: isMobile,
                onTap: () => widget.onTabSelected?.call(12),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 4. Section Title: "Recommended modules for Teachers"
          Text(
            'Recommended modules for Teachers',
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),

          // 5. Recommended Modules Checklist Container
          _TeacherRecommendedModulesCard(
            isMobile: isMobile,
          ),
        ],
      ),
    );
  }
}

/// Dismissible Demo Banner (`A.a0H` / `A.a0I`).
class _TeacherDemoBanner extends StatelessWidget {
  final bool isMobile;
  final VoidCallback onDismiss;

  const _TeacherDemoBanner({
    required this.isMobile,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final padding = isMobile ? 12.0 : 14.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // Amber-50 (B.ht)
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFCD34D), // Amber-300 (B.jx)
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.info_outline,
            color: Color(0xFFD97706), // Amber-600 (B.fp)
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Demo Mode (Teacher)',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E), // Amber-900
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Teacher APIs are not connected yet. Modules are visible for UI demo and will be activated once APIs are ready.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFFB45309), // Amber-700
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onDismiss,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF92400E),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Don’t show again',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Emerald Welcome Card (`A.akn`).
class _TeacherWelcomeBanner extends StatelessWidget {
  final String userName;
  final bool isMobile;

  const _TeacherWelcomeBanner({
    required this.userName,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final double cardPadding = isMobile ? 18.0 : 22.0;
    final displayName = userName.trim().isNotEmpty ? userName.trim() : 'Teacher';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF10B981), // Emerald-500 (B.aB)
            Color(0xFF34D399), // Emerald-400 (B.fq)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: isMobile ? 22 : 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Quick access to your most-used modules.',
                  style: TextStyle(
                    fontSize: isMobile ? 12.5 : 13.5,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 16),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.28),
                  width: 1,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.school,
                  size: 34,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Quick Action Stat Card (`A.Os`).
class _TeacherQuickActionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final bool isUpcoming;
  final bool isMobile;
  final VoidCallback onTap;

  const _TeacherQuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.isUpcoming,
    required this.isMobile,
    required this.onTap,
  });

  @override
  State<_TeacherQuickActionCard> createState() => _TeacherQuickActionCardState();
}

class _TeacherQuickActionCardState extends State<_TeacherQuickActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cardWidth = widget.isMobile ? double.infinity : 280.0;

    return SizedBox(
      width: cardWidth,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered
                  ? widget.accentColor.withValues(alpha: 0.4)
                  : const Color(0xFFE2E8F0), // Slate-200 (B.b8)
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? widget.accentColor.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.02),
                blurRadius: _isHovered ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon Container (44x44)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              // Content Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A), // Slate-900 (B.ai)
                            ),
                          ),
                        ),
                        if (widget.isUpcoming) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB), // Amber-50 (B.ht)
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFFFCD34D), // Amber-300 (B.jx)
                                width: 1.0,
                              ),
                            ),
                            child: const Text(
                              'UPCOMING',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF92400E),
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B), // Slate-500 (B.yU)
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

/// Recommended Modules Card (`A.aqz`).
class _TeacherRecommendedModulesCard extends StatelessWidget {
  final bool isMobile;

  const _TeacherRecommendedModulesCard({
    required this.isMobile,
  });

  static const List<String> _bulletItems = [
    'My Classes (students list, subjects, sections)',
    'Attendance (daily + period-wise)',
    'Assignments/Homework (create, collect, review)',
    'AI Report Card Generator (marks, results, report cards)',
    'Timetable (personal schedule + substitutions)',
    'Announcements (view + classroom announcements)',
    'Messages/Chat (parents & students communication)',
    'Leave/Requests (apply/approve, if required)',
  ];

  @override
  Widget build(BuildContext context) {
    final padding = isMobile ? 14.0 : 18.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC), // Slate-50 (B.av)
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E8F0), // Slate-200 (B.b8)
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'What we should show on Teacher Dashboard',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A), // Slate-900 (B.bZj)
            ),
          ),
          const SizedBox(height: 10),
          for (final item in _bulletItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '•  ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF334155),
                        height: 1.35,
                      ),
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
