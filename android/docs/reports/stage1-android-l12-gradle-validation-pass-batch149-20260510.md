# Stage 1 Android L12 Gradle Validation Pass - Batch 149

Date: 2026-05-10 04:05 CST

Worker scope: Android live lane, `android/**` only.

## Batch Selection

The daily todo snapshot leaves Android L12 platform validation open. This batch
advanced the earliest Android-owned Gradle validation gates that can run on the
local host without relying on an attached Android device or emulator:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.

No Android product source changes were required. No shared `Docs/**`, `ios/**`,
or `.cron/**` files were edited.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-gradle-validation-pass-batch149-20260510.md`

Gradle also refreshed generated Android-local build outputs under ignored
`build/` directories while running validation.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android`.

- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Explicit JDK used for passing Gradle commands:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
- Explicit Java version: OpenJDK `17.0.17` (`2025-10-21`).
- Android SDK path: `/Users/wangweiyang/Library/Android/sdk`.
- Installed compile platform present: `platforms/android-35`.
- Maven resolution used local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.

The default shell still does not expose a Java runtime:

```text
./gradlew --version --console=plain --no-daemon
The operation couldn't be completed. Unable to locate a Java Runtime.
Please visit http://www.java.com for information on installing Java.
```

This was not a blocker for the selected validation gates because the commands
below pinned `JAVA_HOME` to the explicit OpenJDK 17 installation.

## Validation Results

All passing Gradle commands below were run with:

```bash
JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home \
ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk \
ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk \
./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true ...
```

| Command | Result | Evidence |
| --- | --- | --- |
| `./gradlew --version --console=plain --no-daemon` without explicit `JAVA_HOME` | BLOCKED | macOS reported `Unable to locate a Java Runtime`. |
| `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported OpenJDK `17.0.17`. |
| `./gradlew lint` | PASS | `BUILD SUCCESSFUL in 1m 34s`; `201 actionable tasks: 35 executed, 166 up-to-date`; lint reports generated for app, core, reader, library, and settings modules. |
| `./gradlew build` | PASS | `BUILD SUCCESSFUL in 2m 51s`; `474 actionable tasks: 39 executed, 435 up-to-date`; included debug/release build, unit tests, lint wiring, and Android Stage 1 renderer asset/request-blocking audit gates. |
| `./gradlew :core:testDebugUnitTest` | PASS | `BUILD SUCCESSFUL in 16s`; `17 actionable tasks: 1 executed, 16 up-to-date`. |
| `./gradlew :feature:reader:testDebugUnitTest` | PASS | `BUILD SUCCESSFUL in 16s`; `29 actionable tasks: 2 executed, 27 up-to-date`. |
| `./gradlew :app:assembleDebug` | PASS | `BUILD SUCCESSFUL in 17s`; `122 actionable tasks: 5 executed, 117 up-to-date`. |

Gradle printed its standard deprecation warning during passing commands:

```text
Deprecated Gradle features were used in this build, making it incompatible with Gradle 10.
```

This warning did not fail any selected validation gate.

## Generated Evidence Artifacts

- Debug APK:
  `android/app/build/outputs/apk/debug/app-debug.apk` (`9.3M`)
- App lint report:
  `android/app/build/reports/lint-results-debug.html`
- Core lint report:
  `android/core/build/reports/lint-results-debug.html`
- Reader lint report:
  `android/feature/reader/build/reports/lint-results-debug.html`
- Library lint report:
  `android/feature/library/build/reports/lint-results-debug.html`
- Settings lint report:
  `android/feature/settings/build/reports/lint-results-debug.html`
- Core unit-test report:
  `android/core/build/reports/tests/testDebugUnitTest/index.html`
- Reader unit-test report:
  `android/feature/reader/build/reports/tests/testDebugUnitTest/index.html`
- Gradle problems report:
  `android/build/reports/problems/problems-report.html`

## Unit Test XML Summary

Core debug unit test XML reported zero failures/errors:

- `CoreContractsTest`: 15 tests, 0 skipped, 0 failures, 0 errors.
- `MarkdownDocumentTest`: 1 test, 0 skipped, 0 failures, 0 errors.
- `MarkdownSaveIntegrityTest`: 6 tests, 0 skipped, 0 failures, 0 errors.
- `StructuredMarkdownParserTest`: 12 tests, 0 skipped, 0 failures, 0 errors.
- `BlockSourceEditTest`: 2 tests, 0 skipped, 0 failures, 0 errors.
- `RichRendererAssetPolicyTest`: 24 tests, 0 skipped, 0 failures, 0 errors.
- `ReaderSearchEngineTest`: 4 tests, 0 skipped, 0 failures, 0 errors.

Reader debug unit test XML reported zero failures/errors:

- `ReaderSearchHighlightPlannerTest`: 3 tests, 0 skipped, 0 failures, 0 errors.

## Checklist Evidence For Supervisor

The supervising session can use this report as current Android-lane evidence for
marking these L12 checklist items complete:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.

Keep these Android L12 items open unless covered by a separate device-backed
report:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.
- Capture Android performance report.

Reason: this batch intentionally covered host Gradle validation only. It did not
attempt connected, API 27, low-memory/small-screen, modern-device, or performance
capture validation.
