# Hybrid Context-Focus Reader Plan

## Objective
Redesign the `ReaderScreen` to match the "Hybrid Focus" visual reference provided by the user. The goal is to solve the visibility issues of the current Scroll Mode and provide a seamless, audio-book style interface that offers both paragraph-level context and sentence-level focal highlighting.

## Key Files & Context
- `lib/features/reader/presentation/reader_screen.dart` (UI Refactoring)
- `lib/features/reader/presentation/reader_controller.dart` (Time/Progress Logic)

## Implementation Steps

### 1. State Enhancements (ReaderController)
-   Add helper getters to `ReaderState` to calculate estimated reading times based on the current WPM:
    -   `int get totalDurationSeconds => (tokens.length / (wpm / 60)).round();`
    -   `int get currentDurationSeconds => (index / (wpm / 60)).round();`
-   Add `seekTo(double percent)` method to allow scrubbing via a progress slider.

### 2. Context View (Top Half)
-   Replace the current broken vertical `ListView` with a `SingleChildScrollView` containing `RichText`.
-   This text block will render the surrounding context (e.g., +/- 100 words from the current index) to mimic a paragraph.
-   The currently active word (`state.index`) will be styled with a distinctive background color (e.g., a grey pill) to show the user exactly where they are in the broader text, exactly as shown in the reference image.

### 3. Focal Sentence View (Center)
-   Create a new central visual element that displays a "sliding window" of the text (e.g., 3 words before the current word, the current word, and 3 words after).
-   This creates a "Running Sentence" effect.
-   The current word remains perfectly centered, slightly larger, and highlighted with the Accent Red color.
-   Surrounding context words are slightly dimmed, guiding the eye to the center without losing sentence flow.

### 4. Audio-Player Style Controls (Bottom)
-   Redesign the bottom control bar to match standard media players.
-   **Slider**: A continuous horizontal slider bound to the reading progress (`state.index`).
-   **Timestamps**: Display `currentDurationSeconds` and `totalDurationSeconds` formatted as `MM:SS` below the slider.
-   **Controls**: 
    -   Skip Backward (e.g., 10 seconds worth of tokens).
    -   Large, prominent Play/Pause button.
    -   Skip Forward.
    -   A speed toggle (`1x`) button that opens the WPM/Chunk settings popup.

## Verification & Testing
-   Verify that the top context view auto-scrolls to keep the active word visible.
-   Verify the center focal view updates smoothly without layout jumping.
-   Ensure scrubbing the slider accurately updates the current index and syncs with TTS playback.
