# Stage 1 Android L12 Host Validation Refresh - Batch 156

Date: 2026-05-10 05:25:26 CST

Worker scope: Android live lane, `android/**` only.

## Batch Selection

The authoritative blueprint and daily todo snapshot show Android L12 platform
validation as the earliest still-open Android-owned work. This bounded batch
refreshed the host-side Android validation gates that can run without touching
iOS or shared Docs:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Capture Android performance report.

No Android product source changes were required. No `ios/**`, shared `Docs/**`,
or `.cron/**` files were edited.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-host-validation-refresh-batch156-20260510.md`

Gradle refreshed generated Android-local build outputs under ignored `build/`
directories while running validation.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android`.

- Default `./gradlew --version`: blocked because the default shell has no
  registered Java runtime. macOS printed `Unable to locate a Java Runtime`.
- Explicit JDK used for Gradle validation:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
- Explicit Java version: OpenJDK `17.0.17` (`Homebrew 17.0.17+0`).
- Android SDK path from `android/local.properties`:
  `/Users/wangweiyang/Library/Android/sdk`.
- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Maven resolution used local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.
- Installed SDK platforms observed: `android-31`, `android-32`, `android-33`,
  `android-34`, `android-35`, and `android-36`.
- Installed system images observed: `android-36` only.
- Available AVD observed: `Medium_Phone`.
- Attached Android devices before this report: none. `adb devices -l` printed
  only the header.

Passing Gradle commands used this environment prefix:

```bash
JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home \
ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk \
ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk \
./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true ...
```

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported OpenJDK `17.0.17`. |
| `./gradlew --version` without explicit `JAVA_HOME` | BLOCKED | macOS reported `Unable to locate a Java Runtime`; Gradle validation must scope `JAVA_HOME` explicitly on this host. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true projects` | PASS | `BUILD SUCCESSFUL in 14s`; module graph included `:app`, `:core`, `:feature:reader`, `:feature:library`, and `:feature:settings`. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true lint :core:testDebugUnitTest :feature:reader:testDebugUnitTest :app:assembleDebug stage1AndroidPerformanceReport` | PASS | `BUILD SUCCESSFUL in 2m 32s`; `240 actionable tasks: 40 executed, 200 up-to-date`. Covered Android lint, selected core/reader unit tests, debug APK assembly, and source-level Android performance report capture. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true build` | PASS | `BUILD SUCCESSFUL in 3m 41s`; `474 actionable tasks: 35 executed, 439 up-to-date`. Covered debug/release build, app/core/reader unit tests, lint, and renderer asset/request-blocking gates wired into `check`. |
| `/Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices -l` | BLOCKED for device validation | Printed `List of devices attached` with no device rows. |
| `/Users/wangweiyang/Library/Android/sdk/emulator/emulator -list-avds` | PARTIAL | Printed `Medium_Phone`; no emulator was booted in this batch. |
| `ANDROID_HOME=... ANDROID_SDK_ROOT=... bash tools/device_validation_preflight.sh` | BLOCKED | Found 5 blockers: no attached device/emulator, no API 27 system image, no attached API 27 target, no low-memory target, and no attached API 34+ target. |

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

This is source-level Android performance posture evidence. It does not replace
real device performance validation for API 27, low-memory/small-screen, or
modern-device profiles.

## Generated Evidence Artifacts

- Debug APK:
  `android/app/build/outputs/apk/debug/app-debug.apk` (`9.3M`).
- Release unsigned APK:
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

## Unit Test XML Summary

The debug-unit XML results available after this batch report zero skipped,
failures, or errors:

- `FastMdReaderSessionViewModelTest`: 15 tests.
- `CoreContractsTest`: 15 tests.
- `MarkdownDocumentTest`: 1 test.
- `MarkdownSaveIntegrityTest`: 6 tests.
- `StructuredMarkdownParserTest`: 12 tests.
- `BlockSourceEditTest`: 2 tests.
- `RichRendererAssetPolicyTest`: 24 tests.
- `ReaderSearchEngineTest`: 4 tests.
- `ReaderSearchHighlightPlannerTest`: 3 tests.

## Renderer Gate Evidence From `build`

`./gradlew build` exercised the Android Stage 1 renderer gates wired into
`check`:

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
- No low-memory/small-screen target is currently attached.
- No API 34+ target is currently attached.

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
