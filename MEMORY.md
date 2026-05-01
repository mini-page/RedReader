# Project Memory: iReader: READ FAST, THINK DEEP

iReader is a hybrid AI-assisted cognitive reading system built with Flutter. It focuses on maximizing reading efficiency and comprehension.

## Project Structure

- **lib/**
  - **core/**: Shared constants, theme, and services.
    - `constants/demo_text.dart`: Demo text for initial app run.
    - `theme/app_theme.dart`: Light and dark theme definitions.
    - `services/secure_storage_service.dart`: Encrypted storage for AI keys.
    - `services/ai_service.dart`: Direct HTTP Gemini client with 4-tier fallback (2.0 Lite primary).
  - **features/**: Feature-based architecture.
    - **main/**: App shell and navigation.
      - `presentation/main_scaffold.dart`: Bottom navigation and root structure.
    - **home/**: Dashboard with horizontal ActionSlider (AI Topic, Wiki, URL, Random).
    - **library/**: Dedicated screen with search/sort for saved sessions.
    - **reader/**: Unified engine supporting RSVP, Scroll, and Audio.
    - **stats/**: Cognitive analytics with "Knowledge Seeker" leveling.

## Tech Stack
- **Framework**: Flutter (Android 15 / API 35 optimized)
- **State Management**: Riverpod 3.x
- **AI**: Google Gemini (v1beta endpoint, prepended system prompts)
- **Storage**: Hive, SharedPreferences, Secure Storage
- **Build**: Kotlin 2.1.0 aligned.

## Advanced Architectures (Archived)

### Hybrid Context-Focus UI (Turn 42)
- **Concept**: Top Context Pane (Paragraph) + Center Focal Strip (Sentence Window).
- **Highlight**: Grey pill background in context, Red ORP in focal strip.
- **Controls**: Media-style scrubbing slider with MM:SS duration tracking.
- **State**: Precise WPM-based duration math in `ReaderController`.

## Active Evolution
- [x] Implemented Bottom Navigation & Secure Storage.
- [x] Refactored AI to use Gemini 2.0 Flash Lite with robust fallbacks.
- [x] Redesigned Home with horizontal ActionSlider.
- [x] Implemented "Center-Focus" Scroll mode with red brackets.
- [x] Optimized Android build with Kotlin 2.1.0.

## Navigation Map
- `/`: MainScaffold (Home, Library, Stats, Settings).
- `/reader`: The core engine.
- `/preview`: AI-powered text refinement.
