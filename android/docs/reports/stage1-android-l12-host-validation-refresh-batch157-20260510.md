# Stage 1 Android L12 Host Validation Refresh - Batch 157

Date: 2026-05-10 05:28:48 CST

Worker scope: Android live lane, `android/**` only.

## Batch Selection

The authoritative blueprint and daily todo snapshot show Android L12 platform
validation as the earliest still-open Android-owned work. This bounded batch
refreshed the host-side Android validation gates that can run without an
attached Android device or booted emulator:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Capture Android performance report.

`./gradlew projects` was also run first as the minimum Android Gradle sanity
check required by the lane prompt.

No Android product source changes were required. No `ios/**`, shared `Docs/**`,
or `.cron/**` files were edited.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-host-validation-refresh-batch157-20260510.md`

Gradle refreshed generated Android-local build outputs under ignored `build/`
directories while running validation.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android`.

- Default `java -version`: blocked; macOS reported `Unable to locate a Java Runtime`.
- Explicit JDK used for passing Gradle commands:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
- Explicit Java version: OpenJDK `17.0.17` (`Homebrew 17.0.17+0`).
- Android SDK path from `android/local.properties`:
  `/Users/wangweiyang/Library/Android/sdk`.
- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Maven resolution used local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.
- Attached Android devices: none; `adb devices -l` printed only the header.
- Available AVDs: `Medium_Phone`.
- Installed Android system images observed by preflight: Android 36 only.

Passing Gradle commands used this scoped environment:

```bash
JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home \
ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk \
ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk \
./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true ...
```

Gradle printed its standard deprecation warning during passing commands:

```text
Deprecated Gradle features were used in this build, making it incompatible with Gradle 10.
```

This warning did not fail any selected validation gate.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED for default shell | macOS reported `Unable to locate a Java Runtime`. |
| `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported OpenJDK `17.0.17`. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true projects` | PASS | `BUILD SUCCESSFUL in 12s`; module graph included `:app`, `:core`, `:feature:reader`, `:feature:library`, and `:feature:settings`. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true lint` | PASS | `BUILD SUCCESSFUL in 19s`; `201 actionable tasks: 10 executed, 191 up-to-date`; lint covered app, core, reader, library, and settings modules. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true :core:testDebugUnitTest` | PASS | `BUILD SUCCESSFUL in 15s`; `17 actionable tasks: 1 executed, 16 up-to-date`. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true :feature:reader:testDebugUnitTest` | PASS | `BUILD SUCCESSFUL in 15s`; `29 actionable tasks: 2 executed, 27 up-to-date`. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true :app:assembleDebug` | PASS | `BUILD SUCCESSFUL in 19s`; `122 actionable tasks: 5 executed, 117 up-to-date`; debug APK present at `android/app/build/outputs/apk/debug/app-debug.apk`. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true build stage1AndroidPerformanceReport` | PASS | `BUILD SUCCESSFUL in 2m 20s`; `475 actionable tasks: 15 executed, 460 up-to-date`; covered debug/release build, unit tests, lint, renderer gates wired into `check`, and source-level Android performance report capture. |
| `/Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices -l` | BLOCKED for device validation | Printed `List of devices attached` with no device rows. |
| `/Users/wangweiyang/Library/Android/sdk/emulator/emulator -list-avds` | PARTIAL | Printed `Medium_Phone`; no emulator was booted in this batch. |
| `ANDROID_HOME=... ANDROID_SDK_ROOT=... bash tools/device_validation_preflight.sh` | BLOCKED | Found 5 blockers: no attached device/emulator, no API 27 system image, no attached API 27 runtime, no low-memory/small-screen runtime, and no attached API 34+ runtime. |

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
  `android/app/build/outputs/apk/debug/app-debug.apk` (`9.3M`).
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

The XML scan found no nonzero failure/error/skipped attributes under:

- `android/app/build/test-results/testDebugUnitTest/`
- `android/core/build/test-results/testDebugUnitTest/`
- `android/feature/reader/build/test-results/testDebugUnitTest/`

Available debug unit-test XML suites:

- `FastMdReaderSessionViewModelTest`
- `CoreContractsTest`
- `MarkdownDocumentTest`
- `MarkdownSaveIntegrityTest`
- `StructuredMarkdownParserTest`
- `BlockSourceEditTest`
- `RichRendererAssetPolicyTest`
- `ReaderSearchEngineTest`
- `ReaderSearchHighlightPlannerTest`

## Renderer Gate Evidence From `build`

The passing root `./gradlew build stage1AndroidPerformanceReport` run exercised
the Android Stage 1 renderer gates wired into `check`:

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

Representative gate output from this batch:

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
- No Android API 27 system image is installed under
  `/Users/wangweiyang/Library/Android/sdk/system-images`.
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

Use the `./gradlew projects` result in this report as minimum Android Gradle
sanity evidence. Keep connected-device, API 27 runtime, low-memory/small-screen
runtime, and modern-device runtime validation items open for the blocker reasons
above.
