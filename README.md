# 🏋️ TitanLog

**High-performance, local-first fitness tracking app built with Flutter.**

TitanLog is designed for lifters who demand speed and zero-friction logging. Pre-loaded with 204 exercises, it tracks workouts, detects personal records automatically, and provides detailed analytics — all offline.

---

## ✨ Features

### 📊 Dashboard
- **Consistency Calendar** — GitHub-style heatmap showing your workout frequency over the past 12 weeks
- **Bento Grid Stats** — Monthly workout count, streak tracker, and quick stats at a glance
- **Recent PRs** — Last 3 personal records broken with gold accent styling

### 🏋️ Workout Logger
- **Start Empty Workout** — Begin logging instantly, add exercises as you go
- **204 Pre-loaded Exercises** — Organized across 13 muscle groups and 6 equipment types
- **Table-Style Set Logging** — Weight × Reps with a checkmark to complete each set
- **Smart Defaults** — Auto-fills weight/reps from your last session for each exercise
- **Multi-Add** — Select 5+ exercises at once and add them to your workout in bulk
- **Swipe-to-Delete** — Remove sets with a quick swipe gesture
- **Haptic Feedback** — Every logged set gives satisfying tactile feedback

### ⏱️ Sticky Rest Timer
- Floating countdown timer that persists across exercise navigation
- ±15 second quick-adjust buttons
- Visual warning when timer is about to expire
- Automatic start when a set is completed

### 📈 Analytics
- **Volume Over Time** — Line chart with gradient fill, toggleable time range (1W / 1M / 3M / All)
- **Estimated 1RM** — Epley formula tracking per exercise over time
- **Exercise Selector** — Drill into any specific exercise for detailed trends

### 🏆 Automatic PR Detection
- Detects personal records on every completed set
- Tracks: heaviest weight, best volume (weight × reps), estimated 1RM
- Toast notification + heavy haptic feedback on new PRs

### ⚙️ Settings
- **Weight Units** — Toggle between kg (default) and lbs
- **Rest Timer Default** — Choose from 1:00, 1:30, 2:00, or 3:00

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter |
| **State Management** | Riverpod 2.x |
| **Database** | Drift (SQLite) — offline-first |
| **Charts** | fl_chart |
| **Typography** | Inter (Google Fonts) |
| **Design** | Material 3, Dark Mode First |

---

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point
├── app_shell.dart               # Bottom navigation shell
├── core/
│   ├── theme/
│   │   ├── app_colors.dart      # Color system
│   │   └── app_theme.dart       # Material 3 dark theme
│   └── utils/
│       └── haptic_utils.dart    # Haptic feedback utilities
├── database/
│   ├── app_database.dart        # Drift database + seed logic
│   ├── tables/                  # 5 table definitions
│   ├── daos/                    # 3 Data Access Objects
│   └── seed/                    # 204 exercise seed data
└── features/
    ├── dashboard/               # Heatmap, bento cards, PRs
    ├── workout/                 # Logger, set rows, rest timer
    ├── exercises/               # Library with search & multi-add
    ├── analytics/               # Volume & 1RM charts
    ├── settings/                # Units & timer config
    └── providers/               # Core Riverpod providers
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.8+)
- Android Studio / Xcode for emulators

### Run
```bash
git clone https://github.com/YOUR_USERNAME/titanlog.git
cd titanlog
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

---

## 📱 Exercise Database

204 exercises across 13 muscle groups:

| Muscle Group | Count | Equipment |
|---|---|---|
| Chest | 22 | Barbell, Dumbbell, Cable, Machine, Bodyweight |
| Back | 28 | Barbell, Dumbbell, Cable, Machine, Bodyweight |
| Shoulders | 22 | Barbell, Dumbbell, Cable, Machine, Bodyweight |
| Biceps | 16 | Barbell, Dumbbell, Cable, Machine |
| Triceps | 16 | Barbell, Dumbbell, Cable, Machine, Bodyweight |
| Legs (Quads) | 20 | Barbell, Dumbbell, Machine, Bodyweight |
| Hamstrings | 14 | Barbell, Dumbbell, Machine, Cable, Bodyweight |
| Glutes | 14 | Barbell, Dumbbell, Cable, Machine, Bodyweight |
| Core | 18 | Bodyweight, Cable, Machine |
| Calves | 8 | Machine, Barbell, Dumbbell, Bodyweight |
| Forearms | 6 | Barbell, Dumbbell |
| Cardio | 10 | Machine, Bodyweight |
| Full Body | 10 | Barbell, Dumbbell, Kettlebell |

---

## 📄 License

MIT License — built with 💪 for lifters who demand speed.
