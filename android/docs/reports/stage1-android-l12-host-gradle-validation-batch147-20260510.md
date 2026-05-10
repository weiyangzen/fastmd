# Stage 1 Android L12 Host Gradle Validation - Batch 147

Date: 2026-05-10 03:52 CST

Worker scope: Android live lane, `android/**` only.

## Batch Selection

The authoritative blueprint and daily todo snapshot still leave the earliest Android-owned open items in L12 Platform Validation. This bounded batch refreshes the host-side Android Gradle gates that can run locally without an attached device or emulator:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.

No shared Docs checklist files were edited.

## Environment

- Repository: `/Users/wangweiyang/GitHub/fastmd/android`
- Default `java -version`: blocked by macOS with `Unable to locate a Java Runtime`.
- Per-command JDK used: `/Applications/Android Studio.app/Contents/jbr/Contents/Home`
- Android SDK environment used:
  - `ANDROID_HOME=$HOME/Library/Android/sdk`
  - `ANDROID_SDK_ROOT=$HOME/Library/Android/sdk`

All passing Gradle commands below were run with:

```bash
JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' \
ANDROID_HOME="$HOME/Library/Android/sdk" \
ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
```

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED for default shell Java | macOS reported `Unable to locate a Java Runtime`; validation continued with Android Studio bundled JBR. |
| `./gradlew projects` | PASS | Root project `fastmd-android` listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 414ms`. |
| `./gradlew lint` | PASS | `BUILD SUCCESSFUL in 642ms`; 201 actionable tasks, 10 executed, 191 up-to-date. |
| `./gradlew build` | PASS | `BUILD SUCCESSFUL in 1m 55s`; 474 actionable tasks, 14 executed, 460 up-to-date. The build included app/core/feature checks plus Android Stage 1 renderer asset and renderer request-blocking audit gates. |
| `./gradlew :core:testDebugUnitTest` | PASS | `BUILD SUCCESSFUL in 456ms`; 17 actionable tasks, 1 executed, 16 up-to-date. |
| `./gradlew :feature:reader:testDebugUnitTest` | PASS | `BUILD SUCCESSFUL in 421ms`; 29 actionable tasks, 2 executed, 27 up-to-date. |
| `./gradlew :app:assembleDebug` | PASS | `BUILD SUCCESSFUL in 541ms`; 122 actionable tasks, 5 executed, 117 up-to-date. |

## Build And Report Artifacts

- Debug APK: `app/build/outputs/apk/debug/app-debug.apk` (`9.3M`, timestamp `2026-05-10 01:36`)
- App lint report: `app/build/reports/lint-results-debug.html`
- Core lint report: `core/build/reports/lint-results-debug.html`
- Reader lint report: `feature/reader/build/reports/lint-results-debug.html`
- Core unit-test report: `core/build/reports/tests/testDebugUnitTest/index.html`
- Reader unit-test report: `feature/reader/build/reports/tests/testDebugUnitTest/index.html`
- Gradle problems report: `build/reports/problems/problems-report.html`

## Unit Test XML Summary

Core debug unit-test XML reported zero failures/errors:

- `CoreContractsTest`: 15 tests, 0 failures, 0 errors
- `MarkdownDocumentTest`: 1 test, 0 failures, 0 errors
- `MarkdownSaveIntegrityTest`: 6 tests, 0 failures, 0 errors
- `StructuredMarkdownParserTest`: 12 tests, 0 failures, 0 errors
- `BlockSourceEditTest`: 2 tests, 0 failures, 0 errors
- `RichRendererAssetPolicyTest`: 24 tests, 0 failures, 0 errors
- `ReaderSearchEngineTest`: 4 tests, 0 failures, 0 errors

Reader debug unit-test XML reported zero failures/errors:

- `ReaderSearchHighlightPlannerTest`: 3 tests, 0 failures, 0 errors

## Checklist Evidence For Supervisor

The supervisor can mark these Android L12 checklist items complete based on this report:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.

Open Android L12 items intentionally left for later batches:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.
- Capture Android performance report.
