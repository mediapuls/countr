# countr — Native Swift iOS App Design

## Overview

A native Swift/SwiftUI rebuild of the countr app. Track anything with customizable counters, automatic resets, streaks, goals, and rich analytics. Syncs across devices via iCloud.

**Target:** iOS 17+, watchOS 10+
**Bundle ID:** com.timotoaster.countr
**CloudKit Container:** iCloud.com.timotoaster.countr
**App Group:** group.com.timotoaster.countr

## Architecture

- **SwiftUI** for all UI
- **SwiftData** for persistence with CloudKit sync
- **WidgetKit** for home screen, lock screen, and StandBy widgets
- **WatchKit + SwiftUI** for Apple Watch companion
- **App Intents** for Siri & Shortcuts
- **ActivityKit** for Live Activities / Dynamic Island

### Project Structure

```
countr/
├── countr/                  ← main iOS app
│   ├── Models/              ← SwiftData models
│   ├── Views/               ← screens & components
│   │   ├── Home/
│   │   ├── Stats/
│   │   ├── Settings/
│   │   ├── Onboarding/
│   │   └── Components/
│   ├── Services/            ← reset, notifications, haptics, undo
│   └── Intents/             ← Siri & Shortcuts
├── countrWatch/             ← watchOS app
├── countrWidgets/           ← WidgetKit extension
├── countrLiveActivity/      ← Live Activity extension
└── Shared/                  ← models & logic shared across targets
```

## Data Models

### Counter (SwiftData @Model)

| Property | Type | Default | Notes |
|---|---|---|---|
| id | UUID | auto | primary key |
| name | String | "" | counter label (empty default for CloudKit, validated non-empty at creation) |
| count | Int | 0 | current count |
| stepValue | Int | 1 | custom increment per tap |
| resetMode | ResetMode | .manual | when to auto-reset |
| lastResetDate | String | today | ISO YYYY-MM-DD |
| goal | Int? | nil | optional target |
| color | CounterColor | .blue | preset palette color |
| emoji | String? | nil | optional emoji |
| reminderTime | String? | nil | "HH:MM" format |
| order | Int | 0 | position in list |
| group | CounterGroup? | nil | optional relationship |
| createdAt | Date | now | creation timestamp |

### CounterGroup (SwiftData @Model)

| Property | Type | Default | Notes |
|---|---|---|---|
| id | UUID | auto | primary key |
| name | String | "" | e.g. "Health" (empty default for CloudKit, validated non-empty at creation) |
| order | Int | 0 | display position |
| isExpanded | Bool | true | collapse state |
| counters | [Counter] | [] | inverse relationship |

### DailyHistory (SwiftData @Model)

| Property | Type | Notes |
|---|---|---|
| id | UUID | primary key |
| counterId | UUID | links to Counter by ID (not a SwiftData relationship — history is preserved if counter is deleted) |
| date | String | YYYY-MM-DD |
| total | Int | count for that day |

### UndoEntry (in-memory only)

| Property | Type | Notes |
|---|---|---|
| counterId | UUID | which counter |
| previousCount | Int | count before action |
| delta | Int | amount added/subtracted |
| timestamp | Date | expires after 30 seconds |

### Enums

**ResetMode:** manual, daily, weekly, monthly, yearly

**CounterColor:** coral, orange, amber, yellow, lime, green, teal, cyan, blue, indigo, purple, pink (~12 curated colors)

## Screens & Navigation

### Tab Bar

3 tabs using SwiftUI `TabView`:
1. **Home** (house.fill)
2. **Stats** (chart.bar.fill)
3. **Settings** (gearshape.fill)

Standard iOS tab bar. Tint matches app accent color.

### Home Screen

**Layout:**
- Header: "countr" title + "Track your daily goals" subtitle
- Collapsible group sections with disclosure chevron
- Ungrouped counters appear at the top
- Big "+" floating action button to create counter
- Empty state with logo when no counters exist

**Counter Card:**
- Color accent stripe (left border or top bar using counter's color)
- Counter name (headline weight)
- Reset mode badge (e.g. "daily")
- Large count display (~48pt, spring-animates on change)
- Goal progress bar (if goal set): animated width, shows "count / goal"
- Streak badge: "X day streak" when streak >= 2
- Bottom row: minus button, plus button, share button
- Edit button (···) in top-right corner

**Interactions:**
- Tap card → increment by step value
- Long press card → quick-add menu: 1x, 5x, 10x, 25x (multiplied by step value)
- Minus button → decrement by step value (clamped to 0)
- Edit button → opens edit sheet
- Share button → capture card as image and share
- Shake device → undo last action (within 30 seconds, shows toast)

### Create Counter (sheet)

- Name input (required)
- Group picker (optional, includes "New Group" inline creation)
- Reset mode selector (segmented/chips)
- Step value input (default 1)
- Goal input (optional, number only)
- Color picker (palette grid of ~12 colors)
- Reminder toggle + time picker (default 20:00)
- Create / Cancel buttons

### Edit Counter (sheet)

- All create fields, pre-populated
- Save Changes button
- Reset to 0 (with confirmation alert)
- Move Up / Move Down (reorder)
- Delete Counter (with confirmation alert)

### Stats Screen

**Summary Cards (top):**
- Total counters
- Total logged today (sum of all current counts)
- Best streak (longest across all counters)
- Trend indicator on "total logged today": arrow + "X% vs last week"

**Per-Counter Cards:**
- Counter name + color accent
- Reset mode badge
- Current count / goal
- Streak badge
- Milestone badge: "Goal hit X times this month"
- Mini line chart (current week, Mon-Sun) for counters with reset mode != manual
- Tap card → opens chart modal

### Chart Modal (full screen cover)

- Month navigation (back/forward, month/year title)
- Cannot navigate to future months
- Line chart with area fill using SwiftUI Charts
- Stats grid: Total, Daily Avg, Best Day, Active Days / Total Days
- Daily breakdown list: each logged day with value and horizontal bar
- Values animate in on appear

### Settings Screen

- **App Icon:** dark / light selection
- **Appearance:** auto / light / dark (chip selector)
- **Haptic Feedback:** toggle
- **Default Reset Mode:** chip selector
- **Default Step Value:** number input
- **Export Backup:** serializes to .countr.json, shares via ShareLink
- **Import Backup:** fileImporter, validates, confirmation alert, replaces all data
- **About:** app icon, "countr" branding, version

### Onboarding

- 4-page horizontal TabView with page dots
- Pages: Welcome, Tap to count, Set goals, Stay on track
- Skip button + Next button + Get Started on final page
- Shown once on first launch, tracked via @AppStorage

## Business Logic

### Reset Service

- Runs on app launch and when `scenePhase` changes to `.active`
- For each counter: compares `lastResetDate` to current date based on `resetMode`
- If period boundary crossed:
  1. Save current count to DailyHistory with `lastResetDate`
  2. Set count to 0
  3. Update `lastResetDate` to today
- Edge case: app not opened for multiple days — saves history for last active day only, not intermediate empty days
- Trims DailyHistory to 365 entries per counter

### Streak Calculation

Walks backward through DailyHistory from today:
- **Daily:** consecutive days with total > 0
- **Weekly:** consecutive ISO weeks (Mon-Sun) with at least one day total > 0
- **Monthly:** consecutive months with at least one day total > 0
- **Yearly:** consecutive years with at least one day total > 0
- **Manual:** same as daily
- Displayed when streak >= 2

### Undo Service

- In-memory stack of UndoEntry (not persisted, not synced via CloudKit)
- Captures state before every increment/decrement
- Shake gesture triggers undo of most recent entry
- Entries expire after 30 seconds
- Shows brief toast notification: "Undid +5 on Water"
- Only one level of undo (most recent action)

### Notification Service

- Uses `UNUserNotificationCenter`
- Requests permission when user enables a reminder on any counter
- On app launch: reschedules all active reminders
- For each counter with `reminderTime`: schedules daily notification at that time
- Dynamically cancels notification when counter is incremented (count > 0)
- Reschedules when count resets to 0
- Message: "[Name] — You haven't logged [Name] today. Tap to open countr."

### Haptic Service

- Light impact: increment/decrement
- Medium impact: long-press menu selection
- Success notification: goal reached
- All haptics respect the settings toggle
- Uses UIImpactFeedbackGenerator / UINotificationFeedbackGenerator

### Goal Celebration

- Triggers when count crosses from below goal to >= goal
- Confetti overlay: Canvas-based particle effect, colored dots/rectangles with physics, fades after ~2.5 seconds
- Success haptic burst
- Only triggers once per reset period (tracked in-memory)
- Respects Reduce Motion: skips confetti, uses simple flash

## Extensions & Integrations

### Home Screen Widgets (WidgetKit)

- **Small:** single counter — name, count, goal progress ring, color accent
- **Medium:** up to 3 counters side by side
- **Large:** up to 6 counters in grid
- **Interactive:** tap button on widget to increment (iOS 17 App Intents-based)
- Reads from shared SwiftData store via app group

### Lock Screen Widgets

- **Circular:** count with progress ring
- **Inline:** counter name + count text
- **Rectangular:** counter name, count, mini progress bar

### Live Activity / Dynamic Island

- User manually pins a counter via button in the app
- **Compact leading:** counter color dot + name
- **Compact trailing:** count number
- **Expanded:** name, count, goal progress bar, increment button
- **Minimal (Dynamic Island pill):** just the count
- Auto-ends when: goal reached, period resets, or user manually stops

### Apple Watch App

- **List view:** all counters with name, count, color accent, goal progress
- **Detail view:** large count display, +/- buttons, circular goal progress ring
- **Complication (circular):** most recently used counter's count with progress ring
- **Sync:** shared CloudKit store for background sync, WatchConnectivity for immediate sync when both devices are active

### Siri & Shortcuts (App Intents)

- **IncrementCounterIntent:** "Add [amount] to [counter name]" — defaults to step value
- **GetCounterIntent:** "How many for [counter name]?" — returns current count
- **ResetCounterIntent:** "Reset [counter name]"
- All intents use `@Parameter` with dynamic entity lookup from SwiftData
- Automatically appears in Shortcuts app

### iCloud Sync

- SwiftData `ModelConfiguration` with `cloudKitDatabase: .private("iCloud.com.timotoaster.countr")`
- All models (Counter, CounterGroup, DailyHistory) sync automatically
- Conflict resolution: last-write-wins (CloudKit default)
- Offline-first: full functionality without network, syncs when connected
- CloudKit requirement: all model properties must be optional or have default values

## Visual Design

### Theme System

- Follows system appearance by default (auto)
- User can override to always light or always dark
- Stored in `@AppStorage("theme_mode")`
- **Light:** white/light gray backgrounds, neutral card backgrounds
- **Dark:** black background, dark gray (#1c1c1e) cards
- Counter colors appear as accent stripes/borders on cards, not card backgrounds

### Color Palette

12 curated counter colors, each with light and dark variants for contrast:
coral, orange, amber, yellow, lime, green, teal, cyan, blue, indigo, purple, pink

### Typography

- System font throughout (SF Pro via SwiftUI)
- Dynamic Type: all text scales with accessibility settings
- Count display: ~48pt, bold/heavy weight
- Counter name: headline weight
- Badges/labels: caption weight
- Reset mode badge: caption, rounded background pill

### Animations

- **Count change:** spring scale on the number (scaleEffect pops to 1.15, settles to 1.0)
- **Progress bar:** withAnimation(.easeInOut) on width
- **Card press:** scaleEffect(0.97) on tap with spring
- **Card entrance:** staggered opacity + offset slide-up
- **Group collapse:** smooth height animation, chevron rotation
- **Goal confetti:** Canvas particle system, ~2.5 seconds, colored shapes falling
- **Chart values:** animate from 0 on modal appear
- **Undo toast:** slide in from top, auto-dismiss after 2 seconds
- **Reduce Motion:** all animations replaced with simple opacity fades

### Accessibility

- **VoiceOver:** every card announces "Water, 5 of 8, daily counter, 3 day streak"
- **Accessibility actions:** increment, decrement, edit as custom rotor actions per card
- **Dynamic Type:** all layouts adapt — cards reflow at largest text sizes
- **Reduce Motion:** confetti and stagger skipped, simple fades used
- **Color contrast:** all 12 counter colors verified against both light and dark card backgrounds

## Data Import/Export

### Export

- Serializes all counters, groups, and histories to JSON
- Format: `{ "version": 1, "counters": [...], "groups": [...], "histories": { "counterId": [...] } }`
- File extension: `.countr.json`
- Shared via SwiftUI `ShareLink`

### Import

- `fileImporter` modifier to pick `.json` file
- Validates JSON structure and version field
- Confirmation alert: "This will replace all your data. Are you sure?"
- Deletes all existing data, inserts imported data
- Triggers CloudKit sync after import

### Migration from Expo App

Not needed for v1 — fresh app with no existing user base. If needed later, could parse the Expo AsyncStorage JSON export format and map to SwiftData models.
