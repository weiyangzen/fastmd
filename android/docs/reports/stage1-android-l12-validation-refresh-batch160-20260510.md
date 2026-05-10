# Stage 1 Android L12 Validation Refresh - Batch 160

Date: 2026-05-10 CST

Worker scope: Android live lane, `android/**` only.

## Batch Selection

The authoritative blueprint and daily todo snapshot still list Android L12
platform validation as the earliest open Android-owned work. This bounded batch
refreshed the Android host validation evidence for the runnable Gradle gates,
then rechecked connected/device validation blockers.

No Android product source changes were required. No `ios/**`, shared `Docs/**`,
or `.cron/**` files were edited.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-validation-refresh-batch160-20260510.md`

Gradle refreshed generated Android-local build outputs under ignored `build/`
directories while running validation.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android`.

- Time captured during validation: `2026-05-10 06:02:35 CST +0800`.
- Default `java -version` on `PATH`: BLOCKED with macOS message
  `Unable to locate a Java Runtime`.
- Explicit JDK used for Android Gradle commands:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
- Explicit Java binary check passed with OpenJDK `17.0.17`
  (`Homebrew 17.0.17+0`).
- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Gradle launcher JVM: `17.0.17`.
- Android SDK path from `local.properties` and validation environment:
  `/Users/wangweiyang/Library/Android/sdk`.
- Maven resolution used Android-local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.
- Installed SDK platforms observed: `android-31`, `android-32`,
  `android-33`, `android-34`, `android-35`, and `android-36`.
- Installed system images observed: Android 36 only.
- Available AVD observed: `Medium_Phone`.
- Attached Android devices: none. `adb devices -l` printed only the header.

Passing Gradle commands used this environment prefix:

```bash
JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home \
ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk \
ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk \
./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true ...
```

Gradle printed its standard deprecation warning during validation:

```text
Deprecated Gradle features were used in this build, making it incompatible with Gradle 10.
```

This warning did not fail any selected passing host gate.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED | The default shell Java lookup printed `Unable to locate a Java Runtime`; explicit JDK 17 was used for Android validation instead. |
| `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported OpenJDK `17.0.17`. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true --version` | PASS | Reported Gradle `9.3.0`, launcher JVM `17.0.17`. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true projects` | PASS | `BUILD SUCCESSFUL in 11s`; module graph included `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true lint` | PASS | `BUILD SUCCESSFUL in 19s`; `201 actionable tasks: 10 executed, 191 up-to-date`. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true build` | PASS | `BUILD SUCCESSFUL in 2m 16s`; `474 actionable tasks: 14 executed, 460 up-to-date`. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true :core:testDebugUnitTest` | PASS | `BUILD SUCCESSFUL in 15s`; `17 actionable tasks: 1 executed, 16 up-to-date`. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true :feature:reader:testDebugUnitTest` | PASS | `BUILD SUCCESSFUL in 16s`; `29 actionable tasks: 2 executed, 27 up-to-date`. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true :app:assembleDebug` | PASS | `BUILD SUCCESSFUL in 17s`; `122 actionable tasks: 5 executed, 117 up-to-date`. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true stage1AndroidPerformanceReport` | PASS | `BUILD SUCCESSFUL in 13s`; performance audit printed fixture/profile matrix and `PASS: Android performance report audit completed.` |
| `bash tools/device_validation_preflight.sh` with the same explicit `JAVA_HOME`, `ANDROID_HOME`, and `ANDROID_SDK_ROOT` | BLOCKED | Reported 5 blockers: no attached device/emulator, no API 27 system image, no attached API 27 target, no low-memory/small-screen target, and no attached API 34+ target. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true :app:connectedDebugAndroidTest` | BLOCKED | Debug app and androidTest APKs were prepared, then `:app:connectedDebugAndroidTest` failed with `DeviceException: No connected devices!`; `152 actionable tasks: 6 executed, 146 up-to-date`; `BUILD FAILED in 18s`. |

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

## Unit Test XML Summary

Current `testDebugUnitTest` XML results under Android build directories report
zero failures/errors:

- `CoreContractsTest`: 15 tests, 0 skipped, 0 failures, 0 errors.
- `MarkdownDocumentTest`: 1 test, 0 skipped, 0 failures, 0 errors.
- `MarkdownSaveIntegrityTest`: 6 tests, 0 skipped, 0 failures, 0 errors.
- `StructuredMarkdownParserTest`: 12 tests, 0 skipped, 0 failures, 0 errors.
- `BlockSourceEditTest`: 2 tests, 0 skipped, 0 failures, 0 errors.
- `RichRendererAssetPolicyTest`: 24 tests, 0 skipped, 0 failures, 0 errors.
- `ReaderSearchEngineTest`: 4 tests, 0 skipped, 0 failures, 0 errors.
- `ReaderSearchHighlightPlannerTest`: 3 tests, 0 skipped, 0 failures, 0 errors.

## Generated Evidence Artifacts

- Debug APK:
  `android/app/build/outputs/apk/debug/app-debug.apk` (`9.3M`).
- Android test APK:
  `android/app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk`
  (`948K`).
- Release unsigned APK from `build`:
  `android/app/build/outputs/apk/release/app-release-unsigned.apk` (`1.1M`).
- App lint report:
  `android/app/build/reports/lint-results-debug.html`.
- Core lint report:
  `android/core/build/reports/lint-results-debug.html`.
- Reader lint report:
  `android/feature/reader/build/reports/lint-results-debug.html`.
- Library lint report:
  `android/feature/library/build/reports/lint-results-debug.html`.
- Settings lint report:
  `android/feature/settings/build/reports/lint-results-debug.html`.
- Core unit-test report:
  `android/core/build/reports/tests/testDebugUnitTest/index.html`.
- Reader unit-test report:
  `android/feature/reader/build/reports/tests/testDebugUnitTest/index.html`.
- Gradle problems report:
  `android/build/reports/problems/problems-report.html`.

Existing Android instrumentation coverage under `app/src/androidTest` includes:

- `MainActivityIntentContractTest`
- `MainActivityReaderScenarioTest`

These instrumentation tests could not execute because no device or booted
emulator was available.

## Renderer Gate Evidence

The `build` command exercised the Android Stage 1 renderer gates wired into
module `check` tasks:

- `auditRendererAssets`: PASS; no Android WebView or `android.webkit`
  implementation is present, no React Native/Flutter/Cordova runtime dependency
  is present, and no vendored JS/CSS/font renderer asset tree is present.
- `auditRendererRequestBlocking`: PASS; renderer request policy blocks network,
  external navigation, `javascript:`, `data:`, iframe, content URI, and
  non-renderer-file requests.
- `testRendererAssetAudit`: PASS; regression cases reject stale hashes, invalid
  paths, remote subresources, active SVG content, network-capable browser APIs,
  dynamic code execution, workers, and web-runtime dependencies.
- `testRendererRequestBlockingAudit`: PASS; regression cases require request
  interception/navigation override for any WebView-capable surface.

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
- No API 27 platform is installed under `platforms/`.
- No API 27 system image is installed under `system-images/`.
- No attached API 34+ target was available for modern-device validation.

## Checklist Evidence For Supervisor

The supervising session can use this report as current Android-lane evidence for
marking these L12 checklist items complete:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Capture Android performance report.

Use the explicit-JDK `./gradlew projects` result in this report as minimum
Android Gradle sanity evidence. Keep connected-device, API 27 runtime,
low-memory/small-screen runtime, and modern-device runtime validation items open
for the blocker reasons above.
