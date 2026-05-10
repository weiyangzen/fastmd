# Stage 1 Android L12 Validation Refresh Batch 107 - 2026-05-09

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
platform validation items in `Docs/Stage1_Mobile_Blueprint.md` and
`Docs/todos_20260506.md`.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android product source changes were required. The open Android cluster is
platform validation and evidence capture.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-validation-refresh-batch107-20260509.md`

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-09 at about 21:55 CST.

- Default shell Java discovery remains blocked:
  - `java -version` exited 1 with `Unable to locate a Java Runtime`.
  - `./gradlew --version` without `JAVA_HOME` exited 1 with the same Java
    runtime discovery blocker.
- Gradle validation used explicit JDK 17:
  `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`.
- Explicit JDK version:
  `openjdk version "17.0.17" 2025-10-21`.
- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Maven resolution used the local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.
- Android SDK path used for device preflight:
  `/Users/wangweiyang/Library/Android/sdk`.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED | macOS reported `Unable to locate a Java Runtime`; explicit JDK 17 was used for Gradle commands. |
| `./gradlew --version` | BLOCKED | Without `JAVA_HOME`, wrapper launch failed with the same missing Java Runtime message. |
| `JAVA_HOME=... java -version` | PASS | Reported Homebrew OpenJDK `17.0.17`. |
| `JAVA_HOME=... ./gradlew --version` | PASS | Reported Gradle `9.3.0`, launcher JVM `17.0.17`, macOS `26.3.1 x86_64`. |
| `JAVA_HOME=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true projects --stacktrace` | PASS | Project graph listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 13s`. |
| `JAVA_HOME=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true lint --stacktrace` | PASS | Lint completed for `app`, `core`, `feature:library`, `feature:reader`, and `feature:settings`; `BUILD SUCCESSFUL in 20s`. |
| `JAVA_HOME=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true :core:testDebugUnitTest :feature:reader:testDebugUnitTest :app:assembleDebug stage1AndroidPerformanceReport --stacktrace` | PASS | Core and reader debug unit tests, debug app assembly, and source-level performance report completed; `BUILD SUCCESSFUL in 20s`. |
| `JAVA_HOME=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true build --stacktrace` | PASS | Full Android build completed, including debug/release assembly, release R8/minify path, module checks, lint, unit tests, and renderer asset/request-blocking regression gates; `BUILD SUCCESSFUL in 2m 28s`. |
| `ANDROID_HOME=... ANDROID_SDK_ROOT=... bash tools/device_validation_preflight.sh` | BLOCKED | ADB listed no attached devices; no API 27 system image is installed; only Android 36 system images are installed; one AVD named `Medium_Phone` exists but was not booted; preflight found 5 blocker(s). |

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

## Build Gate Details

The full `build` command also exercised Android-local security and rich renderer
guardrails that are wired into module `check` tasks:

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

## Device Matrix Findings

The local Android SDK still has runtime validation blockers:

- No attached Android device or booted emulator is available for
  `connectedDebugAndroidTest`.
- No Android API 27 system image is installed under
  `/Users/wangweiyang/Library/Android/sdk/system-images`.
- No attached API 27 device/emulator is ready for Android 8.1 validation.
- No attached low-memory device/emulator was detected for low-memory or
  small-screen validation.
- No attached API 34+ device/emulator is ready for modern-device validation.
- The only listed AVD is `Medium_Phone`, and it was not booted during this
  batch.

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
