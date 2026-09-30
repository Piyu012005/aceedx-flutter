# AceEdx Flutter Frontend Reconstruction

## Project Overview
- **Project**: AceEdx Flutter Web Frontend (Clean Rebuild)
- **Purpose**: Reconstruct the entire AceEdx Flutter Web frontend from the ground up based on the forensic evidence extracted from the old compiled Flutter application (`public/web/main.dart.js`).
- **Primary Source of Truth**: Old compiled `main.dart.js`
- **Backend**: Existing unmodified Laravel API backend
- **Database**: Existing unmodified MySQL database
- **Active Environment**: **DEV ONLY** (`https://deve.aceedx.com/api`)
- **Production Environment**: **NEVER TOUCH / REFERENCE CONFIG ONLY**

---

## Development Philosophy & Architecture Flow

```text
OLD FRONTEND (public/web/main.dart.js)
    ↓
FORENSIC EVIDENCE & ARCHITECTURAL BLUEPRINT (docs/)
    ↓
NEW FLUTTER SOURCE CODE (aceedx_flutter/lib)
    ↓
EXISTING UNMODIFIED LARAVEL APIs (/api/*)
    ↓
EXISTING UNMODIFIED DATABASE
```

---

## Project Structure
```text
lib/
├── main.dart                 # Application bootstrap entry point
├── app/
│   ├── app.dart              # Root AceEdxApp widget
│   ├── router/               # GoRouter configuration & route guards
│   ├── theme/                # Design system tokens, colors, typography
│   └── config/               # Environment configurations (AppConfig)
│
├── core/
│   ├── api/                  # Unified ApiClient & HTTP interceptors
│   ├── auth/                 # Auth provider & state management
│   ├── session/              # Session restoration & token storage
│   ├── storage/              # LocalStorage / SharedPreferences abstraction
│   ├── errors/               # ApiException & error handling
│   ├── constants/            # API endpoints & app constants
│   └── utils/                # Date, string, and numeric formatters
│
├── shared/
│   ├── widgets/              # Buttons, inputs, cards, dialogs, loaders
│   ├── components/           # Portal layout shells, sidebar, header, drawer
│   ├── responsive/           # Breakpoints & responsive containers
│   └── models/               # Common data transfer objects & user models
│
├── features/
│   ├── public/               # Home, About, Events, Blog, Policy to Practice
│   ├── auth/                 # Login, Register, Password Reset, OTP, Profile
│   ├── teacher/              # AI Question Paper Generator, Lesson Planner, Attendance
│   ├── school_admin/         # School Management, Teachers, Classrooms, Timetable
│   ├── principal/            # Question Paper Approvals, Academic Audits
│   ├── super_admin/          # KPI Analytics, School Approvals, Module Subscriptions
│   ├── student/              # Personality Test, Gradebook, Attendance
│   ├── parent/               # Children Progress, Planner SSO Bridge
│   ├── marketplace/          # Store Catalog, Cart, Checkout, Razorpay Bridge
│   └── school_directory/     # Find School, Filter, Details, Comparison Matrix
│
└── services/                 # Feature-specific API and business services
```

---

## Verification & Build Commands
```bash
# Get dependencies
flutter pub get

# Static analysis
flutter analyze

# Run unit & smoke tests
flutter test

# Build Flutter Web distribution
flutter build web
```
