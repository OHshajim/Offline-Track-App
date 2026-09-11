# OfflineTrack 📱⚡

**An Offline-First Task, Meeting & Lead Follow-up Manager built with Flutter and SQLite.**

OfflineTrack is an on-device productivity suite designed for freelancers, independent contractors, and traveling professionals who cannot afford to lose track of tasks, client meetings, and sales follow-ups when working in low-connectivity or offline environments.

---

## 🌟 Key Features

1. **100% Offline Usability**:
   - Zero external cloud services, server logins, or network calls required.
   - Powered directly by local SQLite (`sqflite`). Instant zero-latency responses.

2. **Automated Local Reminders**:
   - Uses device-level hardware alarms via `flutter_local_notifications`.
   - Alerts trigger on time even if the phone has zero cellular bars, is in Airplane mode, or after a system restart.

3. **Core Modules**:
   - **Unified Home Dashboard**: Aggregates urgent items into **"Today"**, **"Overdue"**, and **"Upcoming"** categories.
   - **Task Manager**: Filterable by status (Pending, Completed), Priority (Low, Medium, High), and Category (Work, Meeting, Lead, Personal) with animated progress tracking.
   - **Meeting Reminders**: Fast meeting creation with exact time alerts and daily/weekly recurrence tags.
   - **Lead Follow-up Tracker**: Lightweight CRM pipeline (New, Contacted, Follow-up Due, Closed) with follow-up reminders.
   - **Settings & Data Management**: Real-time database export to JSON for personal backups, sample data loader, and notification testing.

4. **Sleek Dark Mode & Animations**:
   - Deep obsidian and midnight slate theme (`#0B0F19`, `#141C2E`).
   - Vibrant accent hierarchy (Electric Violet, Cyan, Emerald, Amber, Rose).
   - Staggered entrance animations, bouncy checkboxes, and breathing status pulse indicators.

---

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev) (Dart SDK 3.0+)
- **Local Database**: [`sqflite`](https://pub.dev/packages/sqflite) (SQLite engine)
- **Local Notifications**: [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications)
- **Timezone Scheduling**: [`timezone`](https://pub.dev/packages/timezone)
- **State Management**: [`provider`](https://pub.dev/packages/provider)
- **Formatting**: [`intl`](https://pub.dev/packages/intl)

---

## 🚀 Getting Started

### 1. Prerequisites
Ensure you have the Flutter SDK installed on your system:
```bash
flutter doctor
```

### 2. Install Dependencies
Navigate to the project root directory and run:
```bash
flutter pub get
```

### 3. Run the Application
Launch on an Android emulator or connected device:
```bash
flutter run
```

---

## 📂 Project Architecture

```
lib/
├── core/
│   ├── database/
│   │   └── database_helper.dart      # SQLite singleton, table creation, indexes & CRUD
│   ├── models/
│   │   ├── task_model.dart           # Task entity
│   │   ├── meeting_model.dart        # Meeting entity with recurrence
│   │   ├── lead_model.dart           # CRM Lead entity with follow-up flags
│   │   └── reminder_model.dart       # Notification registry
│   ├── services/
│   │   └── notification_service.dart # Platform channel notification scheduler
│   └── theme/
│       └── app_theme.dart            # Dark mode palette, colors, and ThemeData
├── providers/
│   ├── task_provider.dart            # Task state management & filters
│   ├── meeting_provider.dart         # Meeting scheduling & agenda state
│   ├── lead_provider.dart            # Lead pipeline & status state
│   └── dashboard_provider.dart       # Tri-sectional unified data aggregator
├── screens/
│   ├── dashboard/
│   │   └── dashboard_screen.dart     # Today, Overdue, Upcoming view & quick create
│   ├── tasks/
│   │   ├── task_list_screen.dart     # Search, filter, progress, swipe-to-delete
│   │   └── task_form_screen.dart     # Add/edit task form
│   ├── meetings/
│   │   ├── meeting_list_screen.dart  # Agenda view & recurrence display
│   │   └── meeting_form_screen.dart  # Meeting scheduler
│   ├── leads/
│   │   ├── lead_list_screen.dart     # CRM pipeline cards & badges
│   │   ├── lead_detail_screen.dart   # Profile, contact actions & history
│   │   └── lead_form_screen.dart     # Add/edit lead form
│   ├── settings/
│   │   └── settings_screen.dart      # JSON database export, demo seeding & alert test
│   └── main_navigation_screen.dart   # Animated bottom navigation bar
├── widgets/
│   └── common_widgets.dart           # AnimatedEntrance, GlowCard, PulsingBadge, etc.
└── main.dart                         # Application entry point
```

---

## 📑 Project Report
For the complete technical report, architecture diagrams, and future synchronization analysis, read [`REPORT.md`](./REPORT.md).
