/// Centralized route paths, names, and metadata for AceEdx Flutter application.
///
/// Contains all 41 verified routes from the original AceEdx Flutter Web frontend
/// (`main.dart.js`), preserving exact paths, casing, and hyphenation.
abstract final class AppRoutes {
  // ─── Public Landing & Informational (23 Routes) ───────────────────────────
  static const String home = '/';
  static const String aboutUs = '/about-us';
  static const String policyToPractice = '/policy-to-practice';
  static const String productDemos = '/product-demos';
  static const String findSchool = '/find-school';
  static const String schoolDetail = '/school-detail/:id';
  static const String marketplace = '/marketplace';
  static const String allProducts = '/all-products';
  static const String featuredMarketplaceDetail = '/featured-marketplace-detail/:id';
  static const String schoolFilter = '/school-filter';
  static const String compareSchools = '/compare-schools';
  static const String compareSchoolsSelect = '/compare-schools-select';
  static const String allSchools = '/all-schools';
  static const String cart = '/cart';
  static const String featuredEvents = '/featured-events';
  static const String featuredEventDetail = '/featured-event-detail/:id';
  static const String contactUs = '/contact-us';
  static const String termsAndConditions = '/terms-and-conditions';
  static const String refundPolicy = '/refund-policy';
  static const String feedbackForm = '/feedback-form';
  static const String search = '/search';
  static const String blog = '/blog';
  static const String homeAnnouncements = '/home-announcements';

  // ─── Guest / Auth Flows (5 Routes) ────────────────────────────────────────
  static const String login = '/login';
  static const String register = '/register';
  static const String passwordReset = '/password-reset';
  static const String verifyOtp = '/verify-otp';
  static const String updatePassword = '/update-password';

  // ─── Authenticated Common (4 Routes - Any Valid Role) ─────────────────────
  static const String checkout = '/checkout';
  static const String payment = '/payment';
  static const String editProfile = '/edit-profile';
  static const String purchaseHistory = '/purchase-history';

  // ─── Role-Specific Protected Portals & Submodules ─────────────────────────
  static const String teacherDashboard = '/teacher-dashboard';
  static const String questionPaperGenerator = '/question-paper-generator';
  static const String schoolDashboard = '/school-dashboard';
  static const String schoolManagement = '/school-management';
  static const String pricingModuleSchool = '/pricing-module-school';
  static const String advertisementForm = '/advertisement-form';
  static const String principalDashboard = '/principal-dashboard';
  static const String superAdminDashboard = '/super-admin-dashboard';
  static const String studentDashboard = '/student-dashboard';
  static const String parentDashboard = '/parent-dashboard';

  // ─── Dev Only ─────────────────────────────────────────────────────────────
  static const String themeShowcase = '/theme-showcase';

  /// Complete list of all 41 core production routes in AceEdx.
  static const List<String> allCoreRoutes = [
    home,
    aboutUs,
    policyToPractice,
    productDemos,
    findSchool,
    schoolDetail,
    marketplace,
    allProducts,
    featuredMarketplaceDetail,
    schoolFilter,
    compareSchools,
    compareSchoolsSelect,
    allSchools,
    cart,
    featuredEvents,
    featuredEventDetail,
    contactUs,
    termsAndConditions,
    refundPolicy,
    feedbackForm,
    search,
    blog,
    homeAnnouncements,
    login,
    register,
    passwordReset,
    verifyOtp,
    updatePassword,
    checkout,
    payment,
    editProfile,
    purchaseHistory,
    teacherDashboard,
    schoolDashboard,
    schoolManagement,
    pricingModuleSchool,
    advertisementForm,
    principalDashboard,
    superAdminDashboard,
    studentDashboard,
    parentDashboard,
  ];

  /// Guest-only routes that redirect authenticated users to their dashboard.
  static const Set<String> guestOnlyRoutes = {
    login,
    register,
    passwordReset,
  };

  /// Common protected routes requiring an active authenticated session.
  static const Set<String> commonProtectedRoutes = {
    checkout,
    payment,
    editProfile,
    purchaseHistory,
  };

  /// Maps role name to target role dashboard route.
  static String getDashboardForRole(String? role) {
    final normalized = role?.toLowerCase().trim() ?? '';
    switch (normalized) {
      case 'super_admin':
      case 'superadmin':
        return superAdminDashboard;
      case 'school_admin':
      case 'school admin':
      case 'school':
        return schoolDashboard;
      case 'principal':
        return principalDashboard;
      case 'teacher':
        return teacherDashboard;
      case 'student':
        return studentDashboard;
      case 'parent':
        return parentDashboard;
      default:
        return home;
    }
  }

  /// Checks if [currentRole] matches any of the [allowedRoles].
  static bool hasRole(String? currentRole, List<String> allowedRoles) {
    if (currentRole == null || currentRole.isEmpty) return false;
    final normalized = currentRole.toLowerCase().trim();
    return allowedRoles.any((r) => r.toLowerCase().trim() == normalized);
  }
}
