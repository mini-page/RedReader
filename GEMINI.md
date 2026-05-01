# iReader: READ FAST, THINK DEEP

## Project Mission
iReader is a hybrid AI-assisted cognitive reading system designed to maximize reading efficiency while deepening comprehension through deterministic RSVP engines and optional AI-powered transformation layers.

## Core Mandates
1. **Performance First**: The reading engine must remain silky smooth. UI threads must never be blocked by AI processing.
2. **Stateless AI**: AI features are optional utility layers. The app must always function locally without an internet connection or API keys.
3. **Data Privacy**: API keys must be stored in Secure Storage and never logged or sent to any telemetry.

## Architecture
- **Features-First**: Organized by domain (Main, Home, Reader, Library, Settings, Stats).
- **State Management**: Riverpod 3.0+ using `Notifier` and `AsyncNotifier`.
- **Navigation**: GoRouter with `MainScaffold` providing Bottom Navigation.
- **Reading Engine**: Supports RSVP, Scroll, and Audio (TTS) modes.

## Development Status
- [x] **Phase 1**: Navigation Foundation & Secure Storage.
- [x] **Phase 2**: Multi-mode Reading (Scroll & Audio).
- [x] **Phase 3**: AI Integration Layer (Summarize, Simplify, Translate).
- [x] **Phase 4**: Cognitive Analytics (Tracking & Stats).

## Context Map
- `lib/features/reader/`: The core reading logic and engine.
- `lib/features/main/`: Bottom navigation and scaffold.
- `lib/core/services/`: Shared services like Secure Storage.
- `lib/shared/models/`: App-wide data structures.
