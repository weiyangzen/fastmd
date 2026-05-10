# Stage 1 Android L12 Instrumentation Smoke Batch 95 - 2026-05-06

## Scope

Android live-lane bounded implementation and validation batch for the earliest
still-open Android-owned L12 platform validation items in the authoritative
Stage 1 Mobile blueprint and the 2026-05-06 todo snapshot.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

## Implementation

Added a native Android instrumentation smoke test for the app entry contract:

- Launcher `ACTION_MAIN` / `CATEGORY_LAUNCHER` resolves to exported
  `MainActivity`.
- Markdown `ACTION_VIEW` with `text/markdown` resolves to exported
  `MainActivity`.
- Shared text `ACTION_SEND` with `text/plain` resolves to exported
  `MainActivity`.

The test uses Android platform `PackageManager` APIs plus AndroidX test runner
support already declared by the app. It does not add React Native, Flutter,
Cordova, a remote WebView shell, or any web runtime.

## Changed Android Files

- `android/app/src/androidTest/java/com/fastmd/mobile/MainActivityIntentContractTest.kt`
- `android/docs/reports/stage1-android-l12-instrumentation-smoke-batch95-20260506.md`

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-06 at approximately 22:24 CST.

- Default shell Java discovery remains blocked: `java -version` reported
  `Unable to locate a Java Runtime`.
- Gradle validation used explicit JDK 17:
  `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`.
- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Maven resolution used the existing mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.
- Android SDK path used for device checks:
  `/Users/wangweiyang/Library/Android/sdk`.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED without explicit JDK | macOS reported `The operation couldn’t be completed. Unable to locate a Java Runtime.` |
| `JAVA_HOME=... ANDROID_SDK_ROOT=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon projects :app:compileDebugAndroidTestKotlin :app:assembleDebugAndroidTest --stacktrace` | PASS | Project graph listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; the new `MainActivityIntentContractTest` compiled via `:app:compileDebugAndroidTestKotlin`; `:app:assembleDebugAndroidTest` packaged the debug androidTest APK; `BUILD SUCCESSFUL in 29s`. |
| `ANDROID_SDK_ROOT=... /Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices` | BLOCKED for runtime execution | ADB ran successfully, but printed only `List of devices attached`; no Android device or emulator was connected. |
| `find /Users/wangweiyang/Library/Android/sdk/system-images -maxdepth 3 -type d` | BLOCKED for API 27 emulator validation | Installed system images are Android 36 arm64 Google APIs / Play Store variants only; no `android-27` system image is installed. |
| `JAVA_HOME=... ANDROID_SDK_ROOT=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon :app:connectedDebugAndroidTest --stacktrace` | BLOCKED by no device | App APK and androidTest APK tasks were up to date, then `:app:connectedDebugAndroidTest` failed with `com.android.builder.testing.api.DeviceException: No connected devices!`; `BUILD FAILED in 20s`. |
| `JAVA_HOME=... ANDROID_SDK_ROOT=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon :app:lintDebug --stacktrace` | PASS | App debug lint included `:app:lintAnalyzeDebugAndroidTest` for the new instrumentation source and completed with `BUILD SUCCESSFUL in 31s`. |
| `git diff --check -- android` | PASS | No whitespace errors were reported after the test and report were added. |

## Preserved Blockers

- Default shell Java discovery remains incomplete until a JDK is visible on
  `PATH` or `JAVA_HOME` is exported before wrapper use.
- Device-backed `:app:connectedDebugAndroidTest` remains open because no
  Android device or emulator is attached. Unlike prior no-source runs, this
  batch now provides a real androidTest APK with entry-contract smoke coverage
  ready to execute when a device is available.
- Android API 27 validation remains blocked locally because no API 27 system
  image or attached API 27 device/emulator is present.
- Android low-memory/small-screen profile validation remains blocked locally
  because no matching device or emulator is attached.
- Android modern-device validation remains blocked locally because `adb devices`
  reported no attached devices.

## Supervisor Checklist Recommendation

The supervising session can use this report as implementation plus validation
evidence that Android now has device-backed smoke coverage prepared for:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.

Do not mark the connected/device runtime item complete from this batch because
execution is blocked by no attached Android device or emulator. Do not mark
these runtime/device matrix items complete from this batch:

- Android API 27 validation.
- Android low-memory/small-screen profile validation.
- Android modern device validation.
