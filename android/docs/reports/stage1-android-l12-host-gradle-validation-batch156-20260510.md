# Stage 1 Android L12 Host Gradle Validation - Batch 156

Date: 2026-05-10 CST

Worker scope: Android live lane, `android/**` only.

## Batch Selection

The authoritative blueprint and daily todo snapshot still list Android L12
platform validation as the earliest open Android-owned cluster. This bounded
batch refreshed the host-side Android Gradle gates that can run without an
attached Android device:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.

`./gradlew projects` was also run first as the minimum Gradle sanity check.

No Android product source changes were required. No `ios/**`, shared `Docs/**`,
or `.cron/**` files were edited.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-host-gradle-validation-batch156-20260510.md`

Gradle refreshed generated Android-local build outputs under ignored `build/`
directories while running validation.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android`.

- Default `java -version`: blocked, macOS reported `Unable to locate a Java Runtime`.
- Default `JAVA_HOME`: unset.
- Default `ANDROID_HOME` / `ANDROID_SDK_ROOT`: unset in the shell environment.
- Android SDK path from `android/local.properties`:
  `/Users/wangweiyang/Library/Android/sdk`.
- Explicit JDK used for passing Gradle commands:
  `/Applications/Android Studio.app/Contents/jbr/Contents/Home`.
- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.

All passing Gradle commands used this scoped environment:

```text
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
PATH="/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin:$PATH"
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
| `JAVA_HOME=... PATH=... ./gradlew projects --no-daemon` | PASS | `BUILD SUCCESSFUL in 3s`; module graph included `:app`, `:core`, `:feature:reader`, `:feature:library`, and `:feature:settings`. |
| `JAVA_HOME=... PATH=... ./gradlew lint --no-daemon` | PASS | `BUILD SUCCESSFUL in 17s`; `201 actionable tasks: 15 executed, 186 up-to-date`; lint covered app, core, reader, library, and settings modules. |
| `JAVA_HOME=... PATH=... ./gradlew :core:testDebugUnitTest --no-daemon` | PASS | `BUILD SUCCESSFUL in 7s`; `17 actionable tasks: 1 executed, 16 up-to-date`. |
| `JAVA_HOME=... PATH=... ./gradlew :feature:reader:testDebugUnitTest --no-daemon` | PASS | `BUILD SUCCESSFUL in 5s`; `29 actionable tasks: 2 executed, 27 up-to-date`. |
| `JAVA_HOME=... PATH=... ./gradlew build --no-daemon` | PASS | `BUILD SUCCESSFUL in 1m 59s`; `474 actionable tasks: 14 executed, 460 up-to-date`; covered debug/release build, lint, unit tests, and Stage 1 renderer asset/request-blocking gates. |
| `JAVA_HOME=... PATH=... ./gradlew :app:assembleDebug --no-daemon` | PASS | `BUILD SUCCESSFUL in 4s`; `122 actionable tasks: 5 executed, 117 up-to-date`; debug APK present at `android/app/build/outputs/apk/debug/app-debug.apk`. |

## Generated Evidence Artifacts

- Debug APK:
  `android/app/build/outputs/apk/debug/app-debug.apk`
- Release APK from `build`:
  `android/app/build/outputs/apk/release/app-release-unsigned.apk`
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
- App debug unit-test report:
  `android/app/build/reports/tests/testDebugUnitTest/index.html`
- Core debug unit-test report:
  `android/core/build/reports/tests/testDebugUnitTest/index.html`
- Reader debug unit-test report:
  `android/feature/reader/build/reports/tests/testDebugUnitTest/index.html`
- Gradle problems report:
  `android/build/reports/problems/problems-report.html`

The debug unit-test XML scan found no nonzero failure/error attributes under:

- `android/app/build/test-results/testDebugUnitTest/`
- `android/core/build/test-results/testDebugUnitTest/`
- `android/feature/reader/build/test-results/testDebugUnitTest/`

Representative zero-failure debug unit-test XML suites:

- `app/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.session.FastMdReaderSessionViewModelTest.xml`
- `core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.contracts.CoreContractsTest.xml`
- `core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.document.MarkdownSaveIntegrityTest.xml`
- `core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.markdown.StructuredMarkdownParserTest.xml`
- `core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.render.RichRendererAssetPolicyTest.xml`
- `feature/reader/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.feature.reader.ReaderSearchHighlightPlannerTest.xml`

## Renderer Gate Evidence From `build`

The passing root `./gradlew build --no-daemon` run exercised the Android Stage 1
renderer gates wired into `check`:

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

## Remaining Runtime Scope

This batch did not run a connected/device-backed validation command and did not
claim runtime-device coverage. Keep these L12 items open unless covered by a
separate report from a matching attached device, emulator, or performance
capture batch:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.
- Capture Android performance report.

## Checklist Evidence For Supervisor

The supervising session can use this report as current Android-lane evidence for
marking these L12 checklist items complete if not already reconciled:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.

Use the `./gradlew projects` result in this report as minimum Android Gradle
sanity evidence. Do not use this report to newly claim completion for
connected-device, API 27 runtime, low-memory/small-screen runtime, modern-device
runtime, or Android performance report items.
