# Stage 1 Android L12 Host Validation Refresh - Batch 165

Date: 2026-05-10 CST

Worker scope: Android live lane, `android/**` only.

## Batch Selection

The authoritative blueprint and daily todo snapshot still list Android L12
platform validation as the earliest remaining Android-owned work. This bounded
batch refreshed the host-side Gradle gates that do not require an attached
Android device or booted emulator:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Capture Android performance report.

`./gradlew projects` was included in the same explicit-JDK Gradle invocation as
the minimum Android Gradle sanity check required by the lane prompt.

No Android product source changes were required. No `ios/**`, shared `Docs/**`,
or `.cron/**` files were edited.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-host-validation-refresh-batch165-20260510.md`

Gradle also refreshed generated Android-local build outputs under `build/`
directories while running validation.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android`.

- Time captured after validation: `2026-05-10 06:44:26 CST +0800`.
- Default shell `java -version`: blocked by macOS with
  `Unable to locate a Java Runtime`.
- Default shell `./gradlew projects`: blocked by the same missing default Java
  runtime before Gradle started.
- Explicit JDK used for Android Gradle commands:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
- Explicit Java version: OpenJDK `17.0.17` (`Homebrew 17.0.17+0`).
- Android Studio JBR is also present at
  `/Applications/Android Studio.app/Contents/jbr/Contents/Home` and reports
  OpenJDK `21.0.6`; it was not used for this batch's passing Gradle command.
- Android SDK path from `local.properties`:
  `/Users/wangweiyang/Library/Android/sdk`.
- Maven resolution used Android-local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.

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

This warning did not fail the selected host-side validation gates.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED | macOS printed `Unable to locate a Java Runtime`. |
| `./gradlew projects` with the default shell Java environment | BLOCKED | The wrapper invocation hit the same missing default Java runtime before Gradle started. |
| `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported OpenJDK `17.0.17`. |
| `/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/java -version` | PASS | Reported OpenJDK `21.0.6`; not used for this batch's Gradle gates. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true projects lint build :core:testDebugUnitTest :feature:reader:testDebugUnitTest :app:assembleDebug stage1AndroidPerformanceReport` with explicit JDK 17 and SDK env | PASS | `BUILD SUCCESSFUL in 2m 19s`; `476 actionable tasks: 16 executed, 460 up-to-date`. The `projects` output included `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |

The combined passing Gradle command covered:

- `./gradlew projects`
- `./gradlew lint`
- `./gradlew build`
- `./gradlew :core:testDebugUnitTest`
- `./gradlew :feature:reader:testDebugUnitTest`
- `./gradlew :app:assembleDebug`
- `./gradlew stage1AndroidPerformanceReport`

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
  dynamic code execution, workers, malformed metadata, unsupported extensions,
  and web-runtime dependencies.
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

## Remaining Device Validation Scope

Keep these Android L12 checklist items open until a device-backed report covers
them:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

This host-only batch did not boot an emulator or run connected-device tests.

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
until a device-backed batch provides passing evidence.
