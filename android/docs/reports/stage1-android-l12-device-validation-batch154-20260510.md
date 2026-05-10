# Stage 1 Android L12 Device Validation - Batch 154

Date: 2026-05-10 CST

Worker scope: Android live lane, `android/**` only.

## Batch Selection

The authoritative blueprint and daily todo snapshot show Android L12 platform
validation as the earliest still-open Android-owned cluster. This bounded batch
refreshed host-side Android validation evidence, captured the Android
performance report task, and rechecked the still-open device-backed validation
items.

No Android product source changes were required. No `ios/**`, shared `Docs/**`,
or `.cron/**` files were edited.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-device-validation-batch154-20260510.md`

Gradle refreshed generated Android-local build outputs under ignored `build/`
directories while running validation.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android`.

- Time captured before validation: `2026-05-10 04:40:58 CST +0800`.
- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Explicit JDK used for Gradle commands:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
- Explicit Java binary check passed with OpenJDK `17.0.17`
  (`Homebrew 17.0.17+0`).
- Android SDK path from `local.properties`:
  `/Users/wangweiyang/Library/Android/sdk`.
- Maven resolution used local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.
- Installed SDK platforms observed: `android-31`, `android-32`, `android-33`,
  `android-34`, `android-35`, and `android-36`.
- Installed system images observed: Android 36 only.
- Available AVD observed: `Medium_Phone`.
- Attached Android devices: none. `adb devices -l` printed only the header.
- SDK command-line tools blocker: no
  `/Users/wangweiyang/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager`
  binary is installed in this SDK tree.

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
| `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported OpenJDK `17.0.17`. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true projects` | PASS | `BUILD SUCCESSFUL in 13s`; module graph included `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true lint build :core:testDebugUnitTest :feature:reader:testDebugUnitTest :app:assembleDebug stage1AndroidPerformanceReport` | PASS | `BUILD SUCCESSFUL in 4m 10s`; `475 actionable tasks: 60 executed, 415 up-to-date`. Covered Android lint, full build, core debug unit tests, reader debug unit tests, debug app assembly, renderer security gates, and Android performance report capture. |
| `/Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices -l` | BLOCKED for device validation | Printed `List of devices attached` with no device rows. |
| `/Users/wangweiyang/Library/Android/sdk/emulator/emulator -list-avds` | PARTIAL | Printed `Medium_Phone`; no emulator was booted in this batch. |
| `/Users/wangweiyang/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager --version` | BLOCKED | `sdkmanager` is missing at the expected cmdline-tools path. |
| `bash tools/device_validation_preflight.sh` | BLOCKED | Reported 5 blockers: no attached device/emulator, no API 27 system image, no attached API 27 target, no low-memory/small-screen target, and no attached API 34+ target. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true :app:connectedDebugAndroidTest` | BLOCKED | Debug app and androidTest APKs were prepared, then `:app:connectedDebugAndroidTest` failed with `DeviceException: No connected devices!`; `152 actionable tasks: 11 executed, 141 up-to-date`; `BUILD FAILED in 1m 24s`. |

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
- Gradle problems report:
  `android/build/reports/problems/problems-report.html`

Existing Android instrumentation coverage under `app/src/androidTest` includes:

- `MainActivityIntentContractTest`
- `MainActivityReaderScenarioTest`

These tests could not execute because no device or booted emulator was
available.

## Renderer Gate Evidence

The combined host validation command also exercised the Android Stage 1 renderer
gates wired into `check`:

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
- The expected SDK command-line tools `sdkmanager` path is absent, so this batch
  could not install missing API 27 tooling.
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

Keep the connected/API/device validation items open for the blocker reasons
above.
