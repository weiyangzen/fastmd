# Stage 1 Android L12 Runtime Validation Batch 115 - 2026-05-09

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
runtime validation cluster:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android product source changes were made. The only repository write in this
batch is this Android-local evidence report.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-runtime-validation-batch115-20260509.md`

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-09 at about 23:33 CST.

- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Explicit JDK:
  `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`.
- Explicit JDK version:
  `openjdk version "17.0.17" 2025-10-21`.
- Android SDK path:
  `/Users/wangweiyang/Library/Android/sdk`.
- Maven resolution used local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.
- ADB listed no attached devices.
- Available AVD list contained one AVD: `Medium_Phone`.
- Installed Android SDK system images were Android 36 only; no Android API 27
  system image was installed under
  `/Users/wangweiyang/Library/Android/sdk/system-images`.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home java -version` | PASS | Reported Homebrew OpenJDK `17.0.17`. |
| `ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk /Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices -l` | BLOCKED for device work | Printed `List of devices attached` with no attached device rows. |
| `ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk /Users/wangweiyang/Library/Android/sdk/emulator/emulator -list-avds` | PASS | Listed one AVD: `Medium_Phone`. |
| `find /Users/wangweiyang/Library/Android/sdk/system-images -maxdepth 4 -type d \| sort` | BLOCKED for API 27 validation | Only Android 36 system images were present; no `android-27` image was available. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true projects --stacktrace` | PASS | Project graph listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; Gradle reported `BUILD SUCCESSFUL in 14s`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... bash tools/device_validation_preflight.sh` | BLOCKED | Preflight found 5 blockers: no attached Android device or booted emulator; no API 27 system image; no attached API 27 target; no low-memory/small-screen target; no API 34+ target. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true :app:connectedDebugAndroidTest --stacktrace` | BLOCKED | Gradle prepared/reused debug and androidTest APK packaging, then `:app:connectedDebugAndroidTest` failed with `com.android.builder.testing.api.DeviceException: No connected devices!`; `BUILD FAILED in 20s`. |

## Device Matrix Findings

Runtime/device validation remains blocked in the current local environment:

- No attached Android device is available through ADB.
- No booted emulator is currently attached to ADB.
- No Android API 27 system image is installed, so Android 8.1/API 27 validation
  cannot run locally.
- No attached API 27 device/emulator is ready for Android 8.1 validation.
- No attached low-memory or small-screen device/emulator was detected.
- No attached API 34+ device/emulator is ready for modern-device validation.

## Build Artifacts And Reports

The blocked connected-test command still reached packaging state before the
device provider failed. Relevant Android-local artifacts:

- `android/app/build/outputs/apk/debug/app-debug.apk`
- `android/app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk`
- `android/build/reports/problems/problems-report.html`

No connected Android test result XML was produced in this batch because no
device was available to execute instrumentation.

## Supervisor Checklist Recommendation

Use this report as fresh Android-lane evidence that the local Gradle project
sanity check still passes:

- Minimum Android validation sanity: `./gradlew projects`.

Keep these L12 runtime/device checklist items open:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

Previously captured Android-lane reports remain the stronger pass evidence for
the already-passable Gradle gates and source-level performance report. This
batch does not supersede those pass reports.
