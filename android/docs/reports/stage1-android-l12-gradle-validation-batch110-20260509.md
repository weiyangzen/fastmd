# Stage 1 Android L12 Gradle Validation Batch 110 - 2026-05-09

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
platform validation items in `Docs/Stage1_Mobile_Blueprint.md` and
`Docs/todos_20260506.md`.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android product source changes were required. The open Android cluster is
validation and evidence capture.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-gradle-validation-batch110-20260509.md`

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-09 at about 22:17 CST.

- Default shell Java discovery is blocked:
  - `./gradlew projects` without `JAVA_HOME` exited 1 with
    `Unable to locate a Java Runtime`.
  - `/usr/libexec/java_home -V` exited 1 with the same Java runtime discovery
    blocker.
- Gradle validation used explicit Android Studio bundled JDK:
  `/Applications/Android Studio.app/Contents/jbr/Contents/Home`.
- Explicit JDK version:
  `openjdk version "21.0.6" 2025-01-21`.
- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Android SDK path observed for device probing:
  `/Users/wangweiyang/Library/Android/sdk`.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `./gradlew projects` | BLOCKED without explicit JDK | macOS reported `Unable to locate a Java Runtime`; explicit Android Studio JBR was used for Gradle commands below. |
| `JAVA_HOME=/Applications/Android Studio.app/Contents/jbr/Contents/Home ./gradlew projects` | PASS | Project graph listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 6s`. |
| `JAVA_HOME=/Applications/Android Studio.app/Contents/jbr/Contents/Home ./gradlew lint` | PASS | Lint completed for `app`, `core`, `feature:library`, `feature:reader`, and `feature:settings`; `BUILD SUCCESSFUL in 1m 6s`. |
| `JAVA_HOME=/Applications/Android Studio.app/Contents/jbr/Contents/Home ./gradlew build` | PASS | Full Android build completed, including debug/release assembly, unit tests, lint, R8 release packaging, renderer asset gates, and renderer request-blocking gates; `BUILD SUCCESSFUL in 2m 9s`. |
| `JAVA_HOME=/Applications/Android Studio.app/Contents/jbr/Contents/Home ./gradlew :core:testDebugUnitTest` | PASS | Core debug unit tests completed; `BUILD SUCCESSFUL in 514ms`. |
| `JAVA_HOME=/Applications/Android Studio.app/Contents/jbr/Contents/Home ./gradlew :feature:reader:testDebugUnitTest` | PASS | Reader feature debug unit tests completed; `BUILD SUCCESSFUL in 503ms`. |
| `JAVA_HOME=/Applications/Android Studio.app/Contents/jbr/Contents/Home ./gradlew :app:assembleDebug` | PASS | Debug APK assembly completed; `BUILD SUCCESSFUL in 602ms`. |
| `JAVA_HOME=/Applications/Android Studio.app/Contents/jbr/Contents/Home ./gradlew stage1AndroidPerformanceReport` | PASS | Source-level Android performance posture report completed; `BUILD SUCCESSFUL in 1s`. |
| `ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk adb devices -l` | BLOCKED for device work | ADB listed no attached devices. |

## Build Artifacts And Reports

Relevant Android-local evidence paths:

- `android/app/build/reports/lint-results-debug.html`
- `android/core/build/reports/lint-results-debug.html`
- `android/feature/reader/build/reports/lint-results-debug.html`
- `android/feature/library/build/reports/lint-results-debug.html`
- `android/feature/settings/build/reports/lint-results-debug.html`
- `android/core/build/test-results/testDebugUnitTest/`
- `android/feature/reader/build/test-results/testDebugUnitTest/`
- `android/app/build/outputs/apk/debug/app-debug.apk`
- `android/build/reports/problems/problems-report.html`

The direct `:app:assembleDebug` command left `app-debug.apk` at:

- `android/app/build/outputs/apk/debug/app-debug.apk`

The full `build` command also produced a release unsigned APK at:

- `android/app/build/outputs/apk/release/app-release-unsigned.apk`

## Renderer And Security Gate Details

The full `build` command exercised Android-local security and rich renderer
guardrails wired into module `check` tasks:

- `auditRendererAssets`
- `auditRendererRequestBlocking`
- `testRendererAssetAudit`
- `testRendererRequestBlockingAudit`
- `stage1AndroidRendererAssetGates`

Observed gate output included:

- No Android WebView or `android.webkit` implementation is present.
- No React Native, Flutter, Cordova, or equivalent web runtime dependency is
  present.
- No vendored JS/CSS/font renderer asset tree is present; Android rich blocks use
  native fallback paths.
- Renderer request policy blocks network requests, external navigation,
  `javascript:` URLs, `data:` URLs, content URI requests, non-renderer file
  requests, and iframe requests.
- Regression audits passed for native fallback, renderer asset manifest/hash
  requirements, request-blocking policy coverage, and WebView gating.

## Performance Report Details

`stage1AndroidPerformanceReport` produced the Android source-level performance
posture report:

| Profile | Soft Limit Bytes |
| --- | ---: |
| WatchCompact | 262144 |
| LegacyEfficient | 1048576 |
| ModernStandard | 5242880 |
| LargeScreen | 5242880 |

| Fixture | Bytes | Lines |
| --- | ---: | ---: |
| `basic.md` | 124 | 7 |
| `rich-preview.md` | 5050 | 246 |
| `long-1mb.md` | 328 | 10 |
| `large-5mb.md` | 296 | 8 |
| `huge-table.md` | 333 | 9 |
| `huge-code-block.md` | 176 | 11 |
| `remote-image.md` | 148 | 5 |
| `local-image.md` | 142 | 5 |

This is source-level Android performance evidence. It does not replace API 27
device/emulator timing, low-memory/small-screen runtime validation, or modern
device runtime validation.

## Remaining Blockers

Runtime/device validation remains blocked in the current local environment for
this batch:

- ADB listed no attached Android devices.
- No booted emulator was available for `connectedDebugAndroidTest`.
- No Android API 27 target was attached or booted during this batch.
- No attached low-memory or small-screen device/emulator was detected.
- No attached API 34+ device/emulator was ready for modern-device validation.

## Supervisor Checklist Recommendation

The supervising session can use this report as fresh Android-lane evidence for
marking these Android L12 checklist items complete:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Capture Android performance report.

Keep these runtime/device L12 items open until a matching device or booted
emulator is available:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.
