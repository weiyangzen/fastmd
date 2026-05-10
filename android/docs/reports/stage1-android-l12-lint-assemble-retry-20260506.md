# Stage 1 Android L12 Lint And Assemble Retry - 2026-05-06

## Scope

Android live-lane bounded validation batch for the earliest still-open
Android-owned L12 platform gates:

- Run Android `./gradlew lint`.
- Run Android `./gradlew :app:assembleDebug`.
- Preserve minimum wrapper, device, API 27, security, and renderer posture
  evidence when those compile-backed gates are blocked.

This batch did not edit `ios/**`, shared `Docs/**`, or `.cron/**`.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-lint-assemble-retry-20260506.md`

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android`.

- Gradle entry point: `./gradlew`
- `JAVA_HOME`: `/Applications/Android Studio.app/Contents/jbr/Contents/Home`
- Gradle wrapper: Gradle `9.3.0`
- Launcher JVM: Android Studio bundled JBR
- Android SDK path from `local.properties`: `/Users/wangweiyang/Library/Android/sdk`
- `adb devices`: command ran, but no attached devices or running emulators were
  listed.
- API 27 system image directory: not present at
  `/Users/wangweiyang/Library/Android/sdk/system-images/android-27`

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew lint --no-daemon` | BLOCKED | Gradle reached `:core:extractDebugAnnotations`, then failed resolving `com.android.tools.lint:lint-gradle:31.13.2` from `https://dl.google.com/dl/android/maven2/...` because the connection to `dl.google.com:443` timed out. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew :app:assembleDebug --no-daemon` | BLOCKED | Gradle reached `:feature:library:compileDebugKotlin`, then failed resolving `androidx.compose.compiler:compiler:1.5.14` from `https://dl.google.com/dl/android/maven2/...` because the connection to `dl.google.com:443` timed out. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew projects --no-daemon` | PASS | Wrapper evaluated root project `fastmd-android` and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `bash tools/audit_stage1_manifest.sh` | PASS | No manifest permissions are declared; no broad storage, notification, or default `INTERNET` permission is present; `allowBackup=false`; cleartext disabled; only `MainActivity` exported; no Android WebView implementation; release R8/resource-shrinking/non-debuggable posture verified. |
| `bash tools/audit_renderer_assets.sh` | PASS | No Android `WebView` or `android.webkit` implementation, no React Native/Flutter/Cordova runtime dependency, and no vendored JS/CSS/font renderer asset tree are present. |
| `adb devices` | BLOCKED for device validation | `adb` is available, but the attached-device list is empty. |
| `ls -d /Users/wangweiyang/Library/Android/sdk/system-images/android-27` | BLOCKED for API 27 validation | The API 27 system image directory is absent locally. |

## Preserved Blockers

- L12 `./gradlew lint` remains open because Google Maven timed out resolving the
  Android lint artifact.
- L12 `./gradlew :app:assembleDebug` remains open because Google Maven timed out
  resolving the Compose compiler artifact.
- L12 `./gradlew build`, `./gradlew :core:testDebugUnitTest`, and
  `./gradlew :feature:reader:testDebugUnitTest` should remain open behind the
  same Google Maven dependency-resolution blocker until retried successfully.
- L12 `./gradlew :app:connectedDebugAndroidTest` remains open because no Android
  device or emulator is attached.
- Android API 27 validation remains open because no API 27 system image or
  attached API 27 target is present.
- Android low-memory/small-screen and modern-device validation remain open
  because no attached device or emulator is available.

## Supervisor Checklist Recommendation

The supervising session can use this report as Android-lane evidence for:

- L13: Record validation reports under `android/docs/reports/`.

Do not mark Android lint, build, unit-test, assemble, connected-device, API 27,
low-memory/small-screen, or modern-device validation complete from this batch.
