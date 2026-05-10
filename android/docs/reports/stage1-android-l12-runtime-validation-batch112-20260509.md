# Stage 1 Android L12 Runtime Validation Batch 112 - 2026-05-09

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
runtime validation items in `Docs/Stage1_Mobile_Blueprint.md` and
`Docs/todos_20260506.md`.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android product source changes were made. The batch attempted to refresh
runtime/device validation evidence using the only locally available AVD.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-runtime-validation-batch112-20260509.md`

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-09 at about 23:15 CST.

- Gradle validation used explicit JDK 17:
  `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`.
- Explicit JDK version:
  `openjdk version "17.0.17" 2025-10-21`.
- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Maven resolution used the local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.
- Android SDK path:
  `/Users/wangweiyang/Library/Android/sdk`.
- ADB initially listed no attached devices.
- Available AVD list contained one AVD: `Medium_Phone`.
- Installed system images were Android 36 only; no Android API 27 system image
  was installed under `/Users/wangweiyang/Library/Android/sdk/system-images`.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME=... java -version` | PASS | Reported Homebrew OpenJDK `17.0.17`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true projects --stacktrace` | PASS | Project graph listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 15s`. |
| `ANDROID_HOME=... ANDROID_SDK_ROOT=... adb devices -l` | BLOCKED for device work | Printed `List of devices attached` with no devices. |
| `ANDROID_HOME=... ANDROID_SDK_ROOT=... emulator -avd Medium_Phone -no-window -no-audio -no-boot-anim -gpu swiftshader_indirect -no-snapshot-save` | BLOCKED | Emulator process started as PID `87185`, loaded snapshot `default_boot`, then exited before registering a device with ADB. |
| `ANDROID_HOME=... ANDROID_SDK_ROOT=... adb wait-for-device shell getprop sys.boot_completed` | BLOCKED | Wait did not receive a device; after ADB restart it exited with `error: protocol fault (couldn't read status): Undefined error: 0`. |
| `ANDROID_HOME=... ANDROID_SDK_ROOT=... adb kill-server && adb start-server && adb devices -l` | PASS / BLOCKED | ADB restarted successfully, then still printed no attached devices. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... bash tools/device_validation_preflight.sh` | BLOCKED | No attached device or booted emulator; no API 27 system image; no attached API 27 target; no attached low-memory/small-screen target; no attached API 34+ target. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true :app:connectedDebugAndroidTest --stacktrace` | BLOCKED | App and androidTest APK packaging were up to date, then `:app:connectedDebugAndroidTest` failed with `com.android.builder.testing.api.DeviceException: No connected devices!`; `BUILD FAILED in 22s`. |

## Emulator Attempt Details

The AVD launch command wrote logs to `/tmp/fastmd-medium-phone-emulator.log`.
Important observed lines:

- `Android emulator version 36.1.9.0`
- `Found systemPath /Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore_ps16k/arm64-v8a/`
- `androidboot.qemu.avd_name=Medium_Phone`
- `Started GRPC server at 127.0.0.1:8554`
- `Loading snapshot 'default_boot'...`
- `Successfully loaded snapshot 'default_boot' using 1222 ms`

After that launch, `ps -p 87185` found no running emulator process and
`adb devices -l` still listed no devices. The AVD directory contained fresh
runtime artifacts and locks, but no connected ADB serial was available.

## Device Matrix Findings

Runtime/device validation remains blocked in the current local environment:

- No attached Android device is available.
- The only available AVD, `Medium_Phone`, did not remain running or attach to
  ADB during this batch.
- No booted emulator was available for `connectedDebugAndroidTest`.
- No Android API 27 system image is installed, so Android 8.1/API 27 validation
  cannot run locally.
- No attached low-memory or small-screen device/emulator was detected.
- No attached API 34+ device/emulator is currently ready for modern-device
  validation.

## Build Artifacts And Reports

The blocked connected-test command still reused or prepared Android-local
debug/test packaging artifacts before device-provider initialization failed:

- `android/app/build/outputs/apk/debug/app-debug.apk`
- `android/app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk`
- `android/build/reports/problems/problems-report.html`

No new connected Android test result XML was produced in this batch because no
device was available to execute instrumentation.

## Supervisor Checklist Recommendation

Use this report as fresh Android-lane evidence that local Gradle project
discovery still works:

- Minimum Android validation sanity: `./gradlew projects`.

Keep these runtime/device L12 items open:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

Previously captured Android-lane reports remain the stronger evidence for the
already-passable local Gradle gates and source-level performance report. This
batch does not supersede those pass reports.
