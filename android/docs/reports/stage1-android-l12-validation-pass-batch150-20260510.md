# Stage 1 Android L12 Validation Pass - Batch 150

Date: 2026-05-10 04:09 CST

Worker scope: Android live lane, `android/**` only.

## Batch Selection

The authoritative blueprint and daily todo snapshot leave Android L12 platform
validation open. This bounded batch advanced the earliest Android-owned
validation items that the local host can run now, plus the Android performance
report capture.

No Android product source changes were required. No `ios/**`, shared `Docs/**`,
or `.cron/**` files were edited.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-validation-pass-batch150-20260510.md`

Gradle refreshed generated Android-local build outputs under ignored `build/`
directories while running validation.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android`.

- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Explicit JDK used for Gradle commands:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
- Explicit Java version: OpenJDK `17.0.17` (`Homebrew 17.0.17+0`).
- Android SDK path: `/Users/wangweiyang/Library/Android/sdk`.
- Installed SDK platforms observed: `android-31`, `android-32`, `android-33`,
  `android-34`, `android-35`, `android-36`.
- Installed emulator image observed: `system-images/android-36/...`.
- Available AVD observed: `Medium_Phone`, configured as Android 36 arm64-v8a
  with 2048 MB RAM.
- Attached Android devices: none. `adb devices -l` printed only the header.
- SDK command-line tools blocker: no
  `/Users/wangweiyang/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager`
  binary is installed in this SDK tree.
- Maven resolution used local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.

The default shell still does not expose a Java runtime:

```text
java -version
The operation couldn't be completed. Unable to locate a Java Runtime.
Please visit http://www.java.com for information on installing Java.
```

This was not a blocker for this batch because all Gradle commands pinned
`JAVA_HOME` to the explicit OpenJDK 17 installation above.

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
| `./gradlew --version --console=plain --no-daemon` with explicit `JAVA_HOME` | PASS | Reported Gradle `9.3.0`, launcher JVM `17.0.17`. |
| `./gradlew projects` | PASS | Printed root project `fastmd-android` with modules `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `./gradlew :core:testDebugUnitTest` | PASS | Included in combined host validation command; task was up-to-date with passing XML results. |
| `./gradlew :feature:reader:testDebugUnitTest` | PASS | Included in combined host validation command; task was up-to-date with passing XML results. |
| `./gradlew :app:assembleDebug` | PASS | Included in combined host validation command; `BUILD SUCCESSFUL in 19s`; debug APK exists at `android/app/build/outputs/apk/debug/app-debug.apk` (`9.3M`). |
| `./gradlew stage1AndroidPerformanceReport` | PASS | Included in combined host validation command; printed profile limits and fixture size matrix; `PASS: Android performance report audit completed.` |
| `./gradlew lint build` | PASS | `BUILD SUCCESSFUL in 2m 16s`; `474 actionable tasks: 14 executed, 460 up-to-date`; included module lint, debug/release build, unit tests, and Stage 1 renderer asset/request-blocking gates. |
| `./gradlew :app:connectedDebugAndroidTest` | BLOCKED | Build prepared and packaged app/test APKs, then failed only at task execution with `DeviceException: No connected devices!`. |
| `adb devices -l` | BLOCKED | Printed `List of devices attached` with no device rows. |
| `emulator -list-avds` | PARTIAL | Printed `Medium_Phone`; its config uses Android 36, not API 27. No emulator was started in this batch. |
| `sdkmanager --list_installed` from expected cmdline-tools path | BLOCKED | `/Users/wangweiyang/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager: No such file or directory`. |

Gradle printed its standard deprecation warning during passing commands:

```text
Deprecated Gradle features were used in this build, making it incompatible with Gradle 10.
```

This warning did not fail any selected validation gate.

## Performance Report Output

`stage1AndroidPerformanceReport` printed:

```text
Android performance profile limits:
  WatchCompact softLimitBytes=262144
  LegacyEfficient softLimitBytes=1048576
  ModernStandard softLimitBytes=5242880
  LargeScreen softLimitBytes=5242880
Android fixture size matrix:
  basic.md bytes=124 lines=7
  rich-preview.md bytes=5050 lines=246
  long-1mb.md bytes=328 lines=10
  large-5mb.md bytes=296 lines=8
  huge-table.md bytes=333 lines=9
  huge-code-block.md bytes=176 lines=11
  remote-image.md bytes=148 lines=5
  local-image.md bytes=142 lines=5
PASS: Android performance report audit completed.
```

This is source-level performance posture evidence. It does not replace real
device performance validation for API 27, low-memory/small-screen, or modern
device profiles.

## Generated Evidence Artifacts

- Debug APK:
  `android/app/build/outputs/apk/debug/app-debug.apk` (`9.3M`)
- Release unsigned APK:
  `android/app/build/outputs/apk/release/app-release-unsigned.apk` (`1.1M`)
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
- App unit-test report:
  `android/app/build/reports/tests/testDebugUnitTest/index.html`
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

## Device Validation Blockers

Keep these Android L12 checklist items open until a device-backed report covers
them:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

Current blockers:

- No Android device or running emulator is attached.
- The only available AVD observed is Android 36 `Medium_Phone`, not API 27.
- No API 27 platform is installed in `platforms/`.
- No API 27 system image is installed in `system-images/`.
- The expected SDK command-line tools `sdkmanager` path is absent, so this batch
  could not install missing API 27 tooling.

## Checklist Evidence For Supervisor

The supervising session can use this report as current Android-lane evidence for
marking these L12 checklist items complete:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Capture Android performance report.

Keep the connected/API/device validation items open for the blocker reasons
above.
