# Stage 1 Android L12 Gradle Validation Pass - Batch 146

Date: 2026-05-10 03:45 CST

Worker scope: Android live lane, `android/**` only.

## Batch Selection

The daily todo snapshot leaves Android L12 platform validation open. This batch advances the earliest Android-owned Gradle validation gates that can run locally without attached device/emulator validation:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.

No shared Docs checklist files were edited.

## Environment

- Repository: `/Users/wangweiyang/GitHub/fastmd/android`
- System `java -version`: blocked, macOS reports no default Java runtime.
- Per-command JDK used: `/Applications/Android Studio.app/Contents/jbr/Contents/Home`
- Bundled JBR version: OpenJDK 21.0.6, build `21.0.6+-13391695-b895.109`
- Android SDK used: `/Users/wangweiyang/Library/Android/sdk`
- Installed compile platform confirmed earlier in this lane: `platforms/android-35`

All Gradle commands below were run with:

```bash
JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' \
ANDROID_HOME="$HOME/Library/Android/sdk" \
ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
```

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `./gradlew projects` | PASS | Root project `fastmd-android` lists `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 655ms`. |
| `./gradlew lint` | PASS | `BUILD SUCCESSFUL in 12s`; lint reports generated for app, core, reader, library, and settings modules. |
| `./gradlew build` | PASS | `BUILD SUCCESSFUL in 2m 12s`; 474 actionable tasks, 36 executed, 438 up-to-date. Includes debug/release build, unit tests, lint, and Android Stage 1 renderer asset/request-blocking gates. |
| `./gradlew :core:testDebugUnitTest` | PASS | `BUILD SUCCESSFUL in 534ms`; `:core:testDebugUnitTest` completed up-to-date after the aggregate build. |
| `./gradlew :feature:reader:testDebugUnitTest` | PASS | `BUILD SUCCESSFUL in 499ms`; `:feature:reader:testDebugUnitTest` completed up-to-date after the aggregate build. |
| `./gradlew :app:assembleDebug` | PASS | `BUILD SUCCESSFUL in 587ms`; debug APK present at `app/build/outputs/apk/debug/app-debug.apk`. |

## Generated Artifacts

- APK: `app/build/outputs/apk/debug/app-debug.apk` (`9.3M`, timestamp `2026-05-10 01:36`)
- App lint: `app/build/reports/lint-results-debug.html`
- Core lint: `core/build/reports/lint-results-debug.html`
- Reader lint: `feature/reader/build/reports/lint-results-debug.html`
- Core unit-test report: `core/build/reports/tests/testDebugUnitTest/index.html`
- Reader unit-test report: `feature/reader/build/reports/tests/testDebugUnitTest/index.html`

Core test XML reported zero failures/errors:

- `CoreContractsTest`: 15 tests, 0 failures, 0 errors
- `MarkdownDocumentTest`: 1 test, 0 failures, 0 errors
- `MarkdownSaveIntegrityTest`: 6 tests, 0 failures, 0 errors
- `StructuredMarkdownParserTest`: 12 tests, 0 failures, 0 errors
- `BlockSourceEditTest`: 2 tests, 0 failures, 0 errors
- `RichRendererAssetPolicyTest`: 24 tests, 0 failures, 0 errors
- `ReaderSearchEngineTest`: 4 tests, 0 failures, 0 errors

Reader test XML reported zero failures/errors:

- `ReaderSearchHighlightPlannerTest`: 3 tests, 0 failures, 0 errors

## Checklist Evidence For Supervisor

The supervisor can mark these L12 Android checklist items complete based on this report:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.

Open Android L12 items intentionally left for later batches:

- `./gradlew :app:connectedDebugAndroidTest`
- Android API 27 validation
- Android low-memory/small-screen profile validation
- Android modern device validation
- Android performance report capture

