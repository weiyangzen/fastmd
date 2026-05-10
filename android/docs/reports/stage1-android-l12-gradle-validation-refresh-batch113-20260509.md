# Stage 1 Android L12 Gradle Validation Refresh Batch 113 - 2026-05-09

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
platform validation items in `Docs/Stage1_Mobile_Blueprint.md` and
`Docs/todos_20260506.md`.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android product source changes were made. The batch refreshed local Gradle
gate evidence and current runtime/device blockers.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-gradle-validation-refresh-batch113-20260509.md`

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-09.

- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Explicit JDK:
  `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`.
- Explicit Java version:
  `openjdk version "17.0.17" 2025-10-21`.
- Android SDK path:
  `/Users/wangweiyang/Library/Android/sdk`.
- Maven resolution used local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME=... java -version` | PASS | Reported Homebrew OpenJDK `17.0.17`. |
| `ANDROID_HOME=... ANDROID_SDK_ROOT=... adb devices -l` | BLOCKED for device work | Printed `List of devices attached` with no attached devices. |
| `ANDROID_HOME=... ANDROID_SDK_ROOT=... emulator -list-avds` | PASS | Listed one AVD: `Medium_Phone`. |
| `find /Users/wangweiyang/Library/Android/sdk/system-images -maxdepth 3 -type d` | PARTIAL / BLOCKED | Installed system images are Android 36 only; no Android API 27 system image is installed. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true projects --stacktrace` | PASS | Project graph listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 12s`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true lint --stacktrace` | PASS | Lint completed for `app`, `core`, `feature:library`, `feature:reader`, and `feature:settings`; `BUILD SUCCESSFUL in 18s`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true :core:testDebugUnitTest :feature:reader:testDebugUnitTest :app:assembleDebug stage1AndroidPerformanceReport --stacktrace` | PASS | Core and reader unit tests, debug APK assembly, and source-level performance report completed; `BUILD SUCCESSFUL in 18s`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true build --stacktrace` | PASS | Full Android build completed, including lint, debug/release assembly, unit tests, R8 release packaging, renderer asset gates, and renderer request-blocking gates; `BUILD SUCCESSFUL in 2m 31s`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... bash tools/device_validation_preflight.sh` | BLOCKED | No attached Android device or booted emulator; no API 27 system image; no attached API 27 target; no attached low-memory/small-screen target; no attached API 34+ target. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true :app:connectedDebugAndroidTest --stacktrace` | BLOCKED | App and androidTest packaging tasks completed or were up to date, then `:app:connectedDebugAndroidTest` failed with `com.android.builder.testing.api.DeviceException: No connected devices!`; `BUILD FAILED in 21s`. |

## Build Artifacts And Reports

Relevant Android-local evidence paths after this batch:

- `android/app/build/reports/lint-results-debug.html`
- `android/core/build/reports/lint-results-debug.html`
- `android/feature/reader/build/reports/lint-results-debug.html`
- `android/feature/library/build/reports/lint-results-debug.html`
- `android/feature/settings/build/reports/lint-results-debug.html`
- `android/core/build/test-results/testDebugUnitTest/`
- `android/feature/reader/build/test-results/testDebugUnitTest/`
- `android/app/build/outputs/apk/debug/app-debug.apk`
- `android/app/build/outputs/apk/release/app-release-unsigned.apk`
- `android/build/reports/problems/problems-report.html`

The blocked connected-test command also prepared or reused Android-local
instrumentation packaging artifacts before device-provider initialization
failed:

- `android/app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk`

No new connected Android test result XML was produced in this batch because no
device was available to execute instrumentation.

## Renderer And Performance Gate Details

The full `build` command exercised the Android-local renderer/security gates
wired into module `check` tasks:

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
  requirements, request-blocking policy coverage, SVG active-content rejection,
  dynamic-code rejection, network API rejection, and WebView gating.

`stage1AndroidPerformanceReport` completed and printed the source-level Android
performance posture:

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

This remains source-level Android performance evidence. It does not replace API
27 device/emulator timing, low-memory/small-screen runtime validation, or manual
modern-device runtime validation.

## Remaining Runtime Blockers

Runtime/device validation remains blocked in the current local environment:

- `adb devices -l` lists no attached Android device or booted emulator.
- The SDK has Android 36 system images only under
  `/Users/wangweiyang/Library/Android/sdk/system-images`.
- No Android API 27 system image is installed, so Android 8.1/API 27 validation
  cannot run locally.
- No attached low-memory or small-screen device/emulator was detected.
- No attached API 34+ device/emulator is currently ready for modern-device
  validation.
- `:app:connectedDebugAndroidTest` cannot execute until a device or booted
  emulator is available.

## Supervisor Checklist Recommendation

The supervising session can use this report as fresh Android-lane evidence for
marking these Android L12 checklist items complete:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Capture Android performance report.

Use this report as minimum Android validation sanity evidence for:

- `./gradlew projects`.

Keep these L12 runtime/device items open until a matching device or booted
emulator is available:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.
