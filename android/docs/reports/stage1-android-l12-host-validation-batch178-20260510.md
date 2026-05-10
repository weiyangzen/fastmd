# Stage 1 Android L12 Host Validation - Batch 178

Date: 2026-05-10 09:54 CST

Worker scope: Android live lane, `android/**` only.

## Batch Selection

The authoritative blueprint and daily todo snapshot still leave Android L12
platform validation open. This bounded batch refreshed the earliest
Android-owned host-side validation gates that can run without a connected
Android device or API 27 emulator.

No Android product source changes were required. No `ios/**`, shared `Docs/**`,
or `.cron/**` files were edited.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-host-validation-batch178-20260510.md`

Gradle refreshed generated Android-local output under ignored `build/`
directories while running validation.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android`.

- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Explicit JDK:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
- Java version: OpenJDK `17.0.17` (`Homebrew 17.0.17+0`).
- Android SDK path: `/Users/wangweiyang/Library/Android/sdk`.
- Maven resolution used local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.
- Available AVD observed: `Medium_Phone`.
- Attached Android devices: none.
- SDK command-line tools blocker:
  `/Users/wangweiyang/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager`
  is not executable or is missing.

Installed Android system images observed:

```text
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis/arm64-v8a
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore/arm64-v8a
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore_ps16k/arm64-v8a
```

No Android API 27 system image is installed locally.

## Validation Results

Passing Gradle commands used:

```bash
JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home \
ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk \
ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk \
./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true ...
```

| Command | Result | Evidence |
| --- | --- | --- |
| `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported OpenJDK `17.0.17`. |
| `./gradlew projects` | PASS | `BUILD SUCCESSFUL in 13s`; confirmed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `./gradlew lint build :core:testDebugUnitTest :feature:reader:testDebugUnitTest :app:assembleDebug stage1AndroidPerformanceReport` | PASS | `BUILD SUCCESSFUL in 2m 20s`; `475 actionable tasks: 15 executed, 460 up-to-date`. This covered lint, full build, core and reader debug unit tests, debug app assembly, renderer asset/request-blocking gates wired through `check`, and Android performance report capture. |
| `/Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices -l` | BLOCKED for device validation | Printed only `List of devices attached`; no attached device rows. |
| `/Users/wangweiyang/Library/Android/sdk/emulator/emulator -list-avds` | PARTIAL | Printed `Medium_Phone`; no emulator was booted in this batch. |
| `find /Users/wangweiyang/Library/Android/sdk/system-images -maxdepth 4 -type d` | BLOCKED for API 27 validation | Only Android 36 system images were present. |
| `test -x /Users/wangweiyang/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager` | BLOCKED | Exit code `1`; this batch could not install missing API 27 SDK components through the expected local SDK manager path. |
| `ANDROID_HOME=... ANDROID_SDK_ROOT=... JAVA_HOME=... bash tools/device_validation_preflight.sh` | BLOCKED | Found 5 blockers: no attached Android device/emulator, no API 27 system image, no attached API 27 target, no low-memory target currently attached, and no API 34+ target currently attached. |

Gradle printed the standard deprecation warning about future Gradle 10
compatibility. It did not fail any selected validation gate.

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

This is source-level Android performance posture evidence. It does not replace
real device performance validation for API 27, low-memory/small-screen, or
modern-device profiles.

## Generated Evidence Artifacts

- Debug APK:
  `android/app/build/outputs/apk/debug/app-debug.apk` (`9.3M`)
- Android test APK:
  `android/app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk`
  (`945K`)
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

The selected unit-test tasks were up-to-date in this run, and the XML results
available under `build/test-results/testDebugUnitTest` report zero
failures/errors:

- `FastMdReaderSessionViewModelTest`: 15 tests, 0 skipped, 0 failures, 0 errors.
- `CoreContractsTest`: 15 tests, 0 skipped, 0 failures, 0 errors.
- `MarkdownDocumentTest`: 1 test, 0 skipped, 0 failures, 0 errors.
- `MarkdownSaveIntegrityTest`: 6 tests, 0 skipped, 0 failures, 0 errors.
- `StructuredMarkdownParserTest`: 12 tests, 0 skipped, 0 failures, 0 errors.
- `BlockSourceEditTest`: 2 tests, 0 skipped, 0 failures, 0 errors.
- `RichRendererAssetPolicyTest`: 24 tests, 0 skipped, 0 failures, 0 errors.
- `ReaderSearchEngineTest`: 4 tests, 0 skipped, 0 failures, 0 errors.
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
- The only AVD listed by the local emulator is `Medium_Phone`; it was not
  booted in this batch.
- No API 27 system image is installed under `system-images/`.
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
