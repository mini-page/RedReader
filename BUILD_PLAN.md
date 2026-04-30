# Red Reader: Flash Fast Reading — End-to-End Build Plan

## 1) Goal and Success Criteria
- Build a production-ready MVP RSVP reader in Flutter (Android + iOS).
- Preserve center-anchor reading stability (no layout shift) at 300–900 WPM.
- Support text paste first, then file ingestion (TXT, DOCX, PDF) in background isolates.
- Ship with modular architecture that can absorb AI/sync features later without rewrites.

## 2) Delivery Roadmap

### Phase 0 — Project Foundation (1–2 days)
- Create Flutter app on latest stable channel.
- Set up Riverpod, GoRouter, Hive, SharedPreferences.
- Add linting (`flutter_lints` + custom rules), format checks, CI skeleton.
- Define app theme tokens, spacing scale, typography, color system.
- Add core folder architecture.

**Exit criteria**
- App boots on Android/iOS simulators.
- Navigation shell works.
- CI passes `flutter analyze` + unit tests.

### Phase 1 — Reader Core MVP (4–6 days)
- Implement tokenizer and ORP index calculation.
- Implement deterministic timer engine with pause/resume and punctuation delay policy.
- Build reader screen with fixed-width anchor box + repaint isolation.
- Add paste text flow, playback controls, WPM slider, chunk toggle (1w/2w/3w).
- Add session progress model in memory.

**Exit criteria**
- Stable playback at 300/600/900 WPM.
- No visible layout jump between words/chunks.
- Pause/resume has no drift.

### Phase 2 — Persistence + Settings + File Parsing (4–6 days)
- Persist sessions in Hive; persist preferences in SharedPreferences.
- Add settings UI (WPM presets, chunk, font size, punctuation pause, theme, ORP color).
- Add TXT, DOCX, PDF parsers via isolate/`compute` pipeline.
- Add import error handling and user-safe failures.

**Exit criteria**
- App resumes last session reliably.
- File import works for representative fixtures.
- Settings survive app restart.

### Phase 3 — Library + Resume UX (2–4 days)
- Build home cards: continue reading, paste, upload, demo.
- Build session library list with progress and metadata.
- Add clear/delete actions and confirmations.

**Exit criteria**
- User can start, resume, and manage multiple sessions.

### Phase 4 — Hardening + Release Prep (3–5 days)
- Performance profiling, memory checks, startup optimization.
- Add tests (unit/widget/integration), crash logging, release notes.
- App store assets, privacy policy, license validation.

**Exit criteria**
- Release candidate passes QA matrix and profiling thresholds.

## 3) Concrete Architecture

```text
lib/
  core/
    constants/
    theme/
    utils/
    routing/
  features/
    onboarding/
    home/
    reader/
      domain/
      data/
      presentation/
    settings/
    library/
  shared/
    widgets/
    models/
```

### Layer rules
- **domain**: pure Dart entities/use-cases, no Flutter imports.
- **data**: repositories, persistence adapters, file parsers.
- **presentation**: screens/controllers/providers/widgets.
- Dependency direction: `presentation -> domain`, `data -> domain`, never reverse.

## 4) Core Reader Engine Design

### Token entity
```dart
class Token {
  final String word;
  final int orpIndex;

  const Token(this.word, this.orpIndex);
}
```

### ORP index
```dart
int getORPIndex(String word) {
  if (word.length <= 1) return 0;
  if (word.length <= 5) return 1;
  if (word.length <= 9) return 2;
  return 3;
}
```

### Base cadence
```dart
Duration baseDelay(int wpm) => Duration(milliseconds: (60000 / wpm).round());
```

### Smart timing
```dart
Duration adjustDelay(String word, Duration base) {
  if (word.endsWith('.') || word.endsWith(',')) return base * 1.5;
  if (word.length > 10) return base * 1.2;
  return base;
}
```

### Drift-safe scheduler requirements
- Never rely on periodic timers alone for long sessions.
- Keep `nextTickAt` timestamp and compute each delay from current wall clock.
- On resume, compute remaining delay from `nextTickAt - now`, clamp at zero.
- Controller must support immediate stop/cancel token.

## 5) Rendering Stability Blueprint
- Keep a **fixed anchor container** centered on screen.
- Render only active token subtree with `ValueListenableBuilder` or equivalent.
- Wrap token render in `RepaintBoundary`.
- Use monospaced anchor guides and fixed line-height to avoid vertical jitter.
- Avoid slide transitions; only opacity transition.

Recommended widget stack:
```text
Center
  SizedBox(fixed width/height)
    RepaintBoundary
      AnimatedSwitcher(80ms in / 60ms out)
        TokenWordView(keyed by token index)
```

## 6) Riverpod State Model

### Providers
- `readerControllerProvider`: playback state machine.
- `settingsProvider`: persisted user preferences.
- `sessionRepositoryProvider`: Hive-backed repository.
- `parserServiceProvider`: isolate parser orchestrator.

### ReaderState (minimum)
- `tokens`, `currentIndex`, `isPlaying`, `wpm`, `chunkSize`, `progress`, `sessionId`, `error`.

## 7) File Parsing Strategy
- Parse each format to plain UTF-8 text in background isolate.
- Normalize whitespace, strip control chars, preserve sentence punctuation.
- Tokenize once, cache tokens in session object.
- Fail soft with user-friendly error and retry path.

## 8) Data Contracts

### Session
- `id`, `title`, `sourceType`, `rawText`, `currentIndex`, `wpm`, `chunkSize`, `createdAt`, `updatedAt`.

### Settings
- `defaultWpm`, `defaultChunkSize`, `fontSize`, `pauseOnPunctuation`, `themeMode`, `orpColor`.

## 9) QA & Performance Gates

### Automated checks
- Unit tests: ORP logic, timing adjustments, tokenizer behavior.
- Widget tests: reader anchor stability + control interactions.
- Integration tests: paste flow, session resume, file import smoke tests.

### Manual perf checklist
- 60fps target during playback on mid-tier Android device.
- No dropped frames when dragging WPM slider quickly.
- No drift after 10+ minutes playback.

## 10) CI/CD Baseline
- PR pipeline: `flutter pub get`, `flutter analyze`, `flutter test`.
- Optional nightly: integration tests on Android emulator.
- Release workflow: semantic version bump + changelog generation.

## 11) Risks & Mitigations
- **Timer drift**: monotonic timestamp scheduler + drift tests.
- **PDF parsing variability**: support fallback parser and sanitize extraction.
- **Janky rebuilds**: isolate reader subtree + avoid global rebuilds.
- **State corruption**: repository versioning + migration guards.

## 12) Expansion-Ready Hooks
- Add `ReadingAssistService` interface now (no-op implementation).
- Keep domain interfaces for sync/analytics to avoid future invasive refactors.
- Add event bus for `session_started`, `session_completed`, `wpm_changed`.

## 13) Definition of Done for MVP
- Paste text + play/pause/seek + WPM/chunk controls.
- ORP highlighting and smart punctuation delay.
- Resume last session from home card.
- Settings persisted across restarts.
- Stable frame pacing on representative test devices.

