# Stage 1 Android L12 Host Gradle Validation - Batch 155

Date: 2026-05-10 CST

Worker scope: Android live lane, `android/**` only.

## Batch Selection

The authoritative blueprint and daily todo snapshot show Android L12 platform
validation as the earliest still-open Android-owned cluster. This bounded batch
refreshed the first host-side Android Gradle gates that can run without an
attached Android device:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.

No Android product source changes were required. No `ios/**`, shared `Docs/**`,
or `.cron/**` files were edited.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-host-gradle-validation-batch155-20260510.md`

Gradle refreshed generated Android-local build outputs under ignored `build/`
directories while running validation.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android`.

- Default `java -version`: blocked, macOS reported no Java Runtime.
- `/usr/libexec/java_home -V`: blocked, macOS reported no Java Runtime.
- Local Android Studio JBR discovered at
  `/Applications/Android Studio.app/Contents/jbr/Contents/Home`.
- Android Studio JBR version:
  `openjdk version "21.0.6" 2025-01-21`.
- Gradle commands used:
  `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"`.
- Android SDK path from `local.properties`:
  `/Users/wangweiyang/Library/Android/sdk`.
- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.

Gradle printed its standard deprecation warning during passing commands:

```text
Deprecated Gradle features were used in this build, making it incompatible with Gradle 10.
```

This warning did not fail any selected validation gate.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME=".../Android Studio.app/Contents/jbr/Contents/Home" ./gradlew projects --no-daemon` | PASS | `BUILD SUCCESSFUL in 3s`; module graph included `:app`, `:core`, `:feature:reader`, `:feature:library`, and `:feature:settings`. |
| `JAVA_HOME=".../Android Studio.app/Contents/jbr/Contents/Home" ./gradlew lint --no-daemon` | PASS | `BUILD SUCCESSFUL in 33s`; `201 actionable tasks: 35 executed, 166 up-to-date`; lint reports generated for app, core, reader, library, and settings modules. |
| `JAVA_HOME=".../Android Studio.app/Contents/jbr/Contents/Home" ./gradlew build --no-daemon` | PASS | `BUILD SUCCESSFUL in 2m 22s`; `474 actionable tasks: 39 executed, 435 up-to-date`; covered debug/release build, lint, app/core/reader unit tests, and renderer asset/request-blocking audit gates. |
| `JAVA_HOME=".../Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :core:testDebugUnitTest --no-daemon` | PASS | `BUILD SUCCESSFUL in 3s`; `17 actionable tasks: 1 executed, 16 up-to-date`. |
| `JAVA_HOME=".../Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :feature:reader:testDebugUnitTest --no-daemon` | PASS | `BUILD SUCCESSFUL in 4s`; `29 actionable tasks: 2 executed, 27 up-to-date`. |
| `JAVA_HOME=".../Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :app:assembleDebug --no-daemon` | PASS | `BUILD SUCCESSFUL in 4s`; `122 actionable tasks: 5 executed, 117 up-to-date`; debug APK present at `android/app/build/outputs/apk/debug/app-debug.apk`. |

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
- App unit-test report:
  `android/app/build/reports/tests/testDebugUnitTest/index.html`
- Core unit-test report:
  `android/core/build/reports/tests/testDebugUnitTest/index.html`
- Reader unit-test report:
  `android/feature/reader/build/reports/tests/testDebugUnitTest/index.html`
- Core test XML examples:
  `android/core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.contracts.CoreContractsTest.xml`,
  `android/core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.render.RichRendererAssetPolicyTest.xml`
- Reader test XML:
  `android/feature/reader/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.feature.reader.ReaderSearchHighlightPlannerTest.xml`
- Gradle problems report:
  `android/build/reports/problems/problems-report.html`

The refreshed debug-unit XML results show zero failures and zero errors for the
core contract, parser, save-integrity, block-edit, renderer-policy, search, and
reader search-highlight suites.

## Renderer Gate Evidence From `build`

`./gradlew build --no-daemon` also exercised the Android Stage 1 renderer gates
wired into `check`:

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

## Checklist Evidence For Supervisor

The supervising session can use this report as current Android-lane evidence for
marking these L12 checklist items complete:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.

Keep these L12 checklist items open; this batch did not run or complete
device-backed/platform-profile validation:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.
- Capture Android performance report.
