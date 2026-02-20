# ResQLink - AI-Assisted Missing Person Reporting Platform

A professional Flutter mobile application for reporting and tracking missing persons with AI assistance.

## 🎯 Overview

ResQLink is a complete, production-grade Flutter mobile application designed to help reunite families by providing a comprehensive platform for reporting missing persons, tracking cases, and submitting tips. The application features a premium UI design similar to top-tier apps like Uber and Notion.

**Note: This is a FRONTEND-ONLY application. No backend integration, API calls, or network services are included. All data is mocked locally for UI demonstration purposes.**

## ✨ Features

### Complete App Flow
- **Splash Screen** → Animated introduction
- **Authentication** → Login / Sign Up with validation
- **Location Permission** → Geo-priority feature explanation
- **Home Dashboard** → Scrollable missing persons feed
- **AI Assistant** → ChatGPT-style conversation interface
- **Report Missing** → Multi-section form with AI auto-fill
- **Case Feed** → Browse and filter all cases
- **Case Detail** → Comprehensive case information with secure screen
- **Submit Tip** → Anonymous tip submission
- **Case Tracking** → Visual progress timeline
- **Notifications** → Grouped priority alerts
- **Profile** → Honor system, badges, and contributions

### Key Capabilities

#### Authentication & Validation
- Email or phone number login
- Form validation (email regex, 10-digit phone, 6+ char password)
- Password visibility toggle
- Confirm password matching

#### Missing Person Reporting
- **AI Auto-Fill**: Animated form population with sample data
- Multi-section form (Basic Info, Appearance, Last Seen, Contact, Privacy)
- Photo upload UI
- Privacy level selection (Public, Protected, Private)

#### AI Chat Assistant
- ChatGPT-style message bubbles
- Typing animation
- User and AI avatars
- Contextual responses based on user input
- Voice input UI (visual only)

#### Case Management
- Urgency badges (Critical, High, Normal) with color coding
- Distance chips showing proximity
- Verification labels
- Privacy-masked contact information
- Secure screen with screenshot blocking (visual indicator)

#### Honor System
- Honor score display
- Rescue count tracking
- Medal and certificate badges
- Contribution summary
- Community impact metrics

### Design Quality

#### Material 3 Design System
- Large whitespace for breathing room
- Soft shadows (elevation: 2, 4, 8)
- Rounded cards (12px, 16px, 24px radius)
- Consistent 8px grid spacing
- Elegant typography hierarchy
- Minimal visual clutter
- Smooth animations (200ms, 300ms, 500ms)

#### Professional Color System
- Primary: `#0A2540` (Deep Blue)
- Accent: `#4A90E2` (Sky Blue)
- Critical: `#E53935` (Red)
- High: `#FF9800` (Orange)
- Normal: `#4CAF50` (Green)
- Comprehensive neutral grays (50-900)

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry with navigation
├── core/
│   ├── theme/
│   │   ├── app_colors.dart           # Color palette
│   │   ├── app_text_styles.dart      # Typography scale
│   │   └── app_theme.dart            # Material theme config
│   ├── constants/
│   │   └── app_constants.dart        # App-wide constants
│   └── data/
│       └── mock_data.dart            # Mock data generator
├── models/
│   ├── missing_person.dart           # MissingPerson model & enums
│   ├── user.dart                     # User model
│   ├── chat_message.dart             # ChatMessage model
│   ├── tip.dart                      # Tip model
│   └── notification.dart             # AppNotification model
├── features/
│   ├── splash/
│   │   └── splash_screen.dart        # Animated splash
│   ├── auth/
│   │   ├── login_page.dart           # Login with validation
│   │   └── signup_page.dart          # Signup with validation
│   ├── location/
│   │   └── location_permission_screen.dart
│   ├── home/
│   │   └── home_page.dart            # Dashboard with FABs
│   ├── ai_chat/
│   │   └── ai_chat_screen.dart       # ChatGPT-style interface
│   ├── report/
│   │   └── report_missing_screen.dart # AI auto-fill form
│   ├── case_feed/
│   │   └── case_feed_screen.dart     # Filterable case list
│   ├── case_detail/
│   │   └── case_detail_screen.dart   # Detailed case view
│   ├── tip/
│   │   └── submit_tip_screen.dart    # Tip submission
│   ├── tracking/
│   │   └── case_tracking_screen.dart # Progress timeline
│   ├── notifications/
│   │   └── notifications_screen.dart # Alert cards
│   └── profile/
│       └── profile_screen.dart       # User profile & honor
└── widgets/
    ├── urgency_badge.dart            # Color-coded urgency
    ├── distance_chip.dart            # Location distance
    ├── verification_label.dart       # Verification status
    ├── missing_person_card.dart      # Reusable card component
    └── secure_screen.dart            # Screenshot security wrapper
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.0+
- Dart 3.0+

### Installation

1. Clone the repository
2. Navigate to the project folder
3. Get dependencies:
```bash
flutter pub get
```

4. Run the app:
```bash
# Chrome
flutter run -d chrome

# Mobile emulator
flutter run

# Specific device
flutter devices
flutter run -d <device-id>
```

## 🎨 UI Components

### Reusable Widgets
- `MissingPersonCard`: Full-featured card with image, badges, and info
- `UrgencyBadge`: Color-coded priority indicator
- `DistanceChip`: Location proximity display
- `VerificationLabel`: Status indicator
- `SecureScreen`: Privacy protection wrapper

### Animations
- Splash screen fade-in
- AI chat typing indicator
- Form auto-fill sequential animation
- Page transitions
- Button hover effects

## 📱 Screens Overview

### Splash Screen
- Animated app icon and tagline
- Auto-navigates to login after 3 seconds

### Login Page
- Email OR phone number input with validation
- Password field with visibility toggle
- "Forgot Password" link
- "Create New Account" navigation

### Signup Page
- Full name validation (2+ chars)
- Phone number (10 digits, numeric only)
- Email (regex validation)
- Password (6+ chars)
- Confirm password matching

### Home Dashboard
- Priority banner for urgent cases
- Scrollable missing persons cards
- Two FABs: "AI Assistant" and "Report Missing"
- Navigation to notifications and profile

### AI Chat
- Conversational interface
- Context-aware responses
- Message history
- Voice input UI
- Send button

### Report Missing Person
- **AI Auto-Fill Button**: Animates through fields
- Photo upload preview
- 5 form sections with validation
- Privacy level radio buttons
- Submit confirmation

### Case Detail
- Hero image header
- Urgency, verification, and distance badges
- Info cards: Last Seen, Appearance, Description, Contact
- Map preview
- Timeline visualization
- "Submit Tip" FAB
- Secure screen banner

### Submit Tip
- Multi-line text input
- Photo attachment UI
- Location sharing toggle
- Anonymous submission option

### Case Tracking
- Vertical progress timeline
- 5 stages: Submitted → Verified → Active → Found → Archived
- Color-coded completion status
- Timestamps for each stage

### Notifications
- Grouped (New / Earlier)
- Type-specific icons and colors
- Unread indicator
- "Mark all read" action

### Profile
- User photo, name, email, phone
- Honor system card with gradient
- Honor score and rescue count
- Medal and certificate badges
- Contribution summary
- Menu items (My Cases, Saved Cases, Privacy, Help, About)
- Logout button

## 🔒 Privacy & Security

- Privacy level system (Public, Protected, Private)
- Contact info masking
- Generalized location display
- Secure screen wrapper (visual indicator for screenshot blocking)
- Anonymous tip submission

## 📊 Mock Data

The app includes comprehensive mock data:
- 5 missing person profiles
- 1 current user profile
- 5 notifications with various types
- Dynamic timestamp calculations
- Realistic placeholder images

## 🎯 Validation Rules

- **Email**: Regex `^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$`
- **Phone**: 10 digits, numeric only
- **Password**: Minimum 6 characters
- **Name**: Minimum 2 characters

## 🌈 Color Semantics

- **Critical Red** (#E53935): Urgent cases, dangerous situations
- **High Orange** (#FF9800): High priority, needs attention
- **Normal Green** (#4CAF50): Regular cases, success states
- **Primary Blue** (#0A2540): Brand identity, primary actions
- **Accent Blue** (#4A90E2): AI features, highlights

## 📝 Notes

- **Frontend Only**: No backend, API, network, or repository layer
- **Mock Data**: All data generated locally for demonstration
- **Navigation**: Named routes with argument passing
- **State Management**: StatefulWidget for local UI state
- **Responsive**: Works on various screen sizes
- **Production Quality**: Ready for demo and presentation

## 🎓 Learning Highlights

This project demonstrates:
- Clean architecture folder structure
- Theme system and design tokens
- Form validation and error handling
- Navigation with arguments
- Reusable component library
- Animation implementation
- Professional UI/UX patterns
- Material 3 design principles

## 📄 License

This is a demonstration project created for educational purposes.

## 👨‍💻 Author

Built with ❤️ using Flutter

---

**ResQLink** - Every second matters. Together, we bring them home.
