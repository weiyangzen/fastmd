# Stage 1 Android L12 Validation Refresh - Batch 162

Date: 2026-05-10 CST

Worker scope: Android live lane, `android/**` only.

## Batch Selection

The authoritative blueprint and daily todo snapshot identify Android L12
platform validation as the earliest remaining Android-owned work. This bounded
batch refreshed the host-side Gradle gates that can run without a device, then
rechecked connected/device blockers.

No Android product source changes were required. No `ios/**`, shared `Docs/**`,
or `.cron/**` files were edited.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-validation-refresh-batch162-20260510.md`

Gradle also refreshed generated Android-local build outputs under ignored
`build/` directories while running validation.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android`.

- Time captured during validation: `2026-05-10 06:23:02 CST +0800`.
- Default shell `java -version`: BLOCKED by macOS with
  `Unable to locate a Java Runtime`.
- Default shell `./gradlew --version`: BLOCKED by the same missing default Java
  runtime.
- Explicit JDK used for Android Gradle commands:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
- Explicit Java version: OpenJDK `17.0.17`
  (`Homebrew 17.0.17+0`).
- Android Studio JBR is also present at
  `/Applications/Android Studio.app/Contents/jbr/Contents/Home` and reports
  OpenJDK `21.0.6`, but this batch used JDK 17.
- Android SDK path from `local.properties`:
  `/Users/wangweiyang/Library/Android/sdk`.
- Maven resolution used Android-local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.
- Attached Android devices: none. `adb devices -l` printed only the header.
- Available AVD: `Medium_Phone`.
- Installed Android SDK platforms: API 31, 32, 33, 34, 35, and 36.
- Installed Android system images: Android 36 only.
- SDK command-line tools blocker:
  `/Users/wangweiyang/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager`
  is missing.

Passing Gradle commands used this scoped environment:

```bash
JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home \
ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk \
ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk \
./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true ...
```

Gradle printed its standard deprecation warning:

```text
Deprecated Gradle features were used in this build, making it incompatible with Gradle 10.
```

This warning did not fail any host-side validation gate.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED | Default shell Java lookup printed `Unable to locate a Java Runtime`; explicit JDK 17 was used for Android validation. |
| `./gradlew --version` | BLOCKED | Default wrapper invocation hit the same missing default Java runtime. |
| `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported OpenJDK `17.0.17`. |
| `/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/java -version` | PASS | Reported OpenJDK `21.0.6`; not used for the Gradle gates in this batch. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true projects lint build :core:testDebugUnitTest :feature:reader:testDebugUnitTest :app:assembleDebug stage1AndroidPerformanceReport` with explicit JDK 17 and SDK env | PASS | `BUILD SUCCESSFUL in 2m 28s`; `476 actionable tasks: 16 executed, 460 up-to-date`. The `projects` output included `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `/Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices -l` | BLOCKED for device validation | Printed `List of devices attached` with no device rows. |
| `/Users/wangweiyang/Library/Android/sdk/emulator/emulator -list-avds` | PARTIAL | Printed `Medium_Phone`; no emulator was booted in this batch. |
| `find /Users/wangweiyang/Library/Android/sdk/platforms -maxdepth 1 -type d -name 'android-*'` | PARTIAL | Found API 31 through API 36 platforms; no API 27 platform is installed. |
| `find /Users/wangweiyang/Library/Android/sdk/system-images -maxdepth 3 -type d -name 'android-*'` | PARTIAL | Found only `/Users/wangweiyang/Library/Android/sdk/system-images/android-36`. |
| `ls -l /Users/wangweiyang/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager` | BLOCKED | `No such file or directory`; local SDK manager is absent at the expected path. |
| `bash tools/device_validation_preflight.sh` with explicit JDK 17 and SDK env | BLOCKED | Reported 5 blockers: no attached device/emulator, no API 27 system image, no attached API 27 runtime, no low-memory/small-screen runtime, and no attached API 34+ runtime. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true :app:connectedDebugAndroidTest` with explicit JDK 17 and SDK env | BLOCKED | App and androidTest APK preparation completed, then `:app:connectedDebugAndroidTest` failed with `DeviceException: No connected devices!`; `BUILD FAILED in 19s`; `152 actionable tasks: 6 executed, 146 up-to-date`. |

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

This is Android source-level performance posture evidence. It does not replace
real device performance validation for API 27, low-memory/small-screen, or
modern-device profiles.

## Unit Test XML Summary

Current `testDebugUnitTest` XML results under Android build directories report
zero failures/errors:

- `FastMdReaderSessionViewModelTest`: 15 tests, 0 skipped, 0 failures, 0 errors.
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
  (`945K`).
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
- App unit-test report:
  `android/app/build/reports/tests/testDebugUnitTest/index.html`.
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

The passing `build` command exercised Android Stage 1 renderer gates wired into
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

Representative gate output:

```text
PASS: No Android WebView or android.webkit implementation is present.
PASS: No React Native, Flutter, Cordova, or equivalent web runtime dependency is present.
PASS: No vendored JS/CSS/font renderer asset tree is present; Android rich blocks use native fallback paths.
PASS: Renderer request policy is a first-class Android core contract.
PASS: native fallback request policy and tests satisfy the gate.
```

## Device Validation Blockers

Keep these Android L12 checklist items open until a device-backed report covers
them:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

Current blockers:

- No Android device or running emulator is attached.
- `Medium_Phone` is the only listed AVD, but it was not booted in this batch.
- No API 27 platform is installed under `platforms/`.
- No API 27 system image is installed under `system-images/`.
- The expected SDK command-line tools `sdkmanager` path is absent, so this batch
  could not install missing API 27 tooling.
- No attached API 27 runtime is ready for Android 8.1 validation.
- No attached low-memory/small-screen runtime is ready.
- No attached API 34+ runtime is ready for modern-device validation.

## Checklist Evidence For Supervisor

The supervising session can use this report as current Android-lane evidence for
marking these L12 checklist items complete:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Capture Android performance report.

Use the explicit-JDK `projects` output in this report as minimum Android Gradle
sanity evidence. Keep connected-device, API 27 runtime, low-memory/small-screen
runtime, and modern-device runtime validation items open for the blocker reasons
above.
