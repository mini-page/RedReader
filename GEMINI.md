# GEMINI CONTROL FILE — iReader

## PRIMARY OBJECTIVE
Refactor, optimize, and standardize the entire Flutter codebase into a scalable, modular, high-performance system.

## CORE PRINCIPLES
- Single responsibility per module
- No duplicated logic
- Unified data pipeline
- Zero layout instability in reader
- Performance-first decisions

---

## EXECUTION MODES

### MODE 1: PLAN
- Scan full repo
- Identify:
  - Dead code
  - Duplicate logic
  - Over-engineered structures
  - Heavy assets
- Output structured refactor plan

### MODE 2: EXECUTE
- Apply refactor step-by-step
- Validate after each change
- Update memory.md continuously

### MODE 3: VERIFY
- Run static checks
- Ensure no broken imports
- Validate build success

---

## MANDATORY RULES

- NEVER break reader engine stability
- NEVER introduce unnecessary dependencies
- ALWAYS centralize logic
- ALWAYS update memory.md after changes

---

## TARGET ARCHITECTURE

Feature-first modular system:

lib/
  core/
  features/
  shared/

NO FLAT STRUCTURES.

---

## PERFORMANCE RULES

- Avoid rebuild-heavy widgets
- Use ValueNotifier / Riverpod
- Precompute tokens
- No runtime parsing during playback

---

## FILE SIZE OPTIMIZATION

- Remove unused assets
- Compress images (WebP)
- Strip debug logs
- Use tree shaking
- Avoid heavy packages

---

## CLEANUP RULES

REMOVE:
- Unused imports
- Dead files
- Duplicate widgets
- Test junk not used

MERGE:
- Utility files
- Repeated UI components

---

## MEMORY TRACKING

All actions must be logged in:

/memory.md

---

## COMMANDS

### /analyze
Scan repo → return issues

### /refactor
Apply structural improvements

### /optimize
Reduce size + improve performance

### /verify
Check build + errors

### /rebuild-reader
Reconstruct reader engine cleanly

---

## HOOKS

ON FILE CHANGE:
- Re-run dependency graph check

ON BUILD FAIL:
- rollback last step using memory.md

ON NEW FEATURE:
- place inside correct feature module

---

## OUTPUT STYLE

- Structured
- No verbosity
- Code-first
