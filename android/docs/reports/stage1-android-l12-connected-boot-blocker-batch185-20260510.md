# Stage 1 Android L12 Connected Boot Blocker - Batch 185

Date: 2026-05-10 09:35 CST

Worker scope: Android live lane, `android/**` only.

## Batch Selection

The authoritative blueprint and daily todo snapshot still leave Android L12
platform validation as the earliest Android-owned open cluster. Host Gradle
validation already has prior Android-local pass reports, so this bounded batch
targeted the next runtime-facing validation item that could be advanced on this
machine:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Re-check API 27, low-memory/small-screen, and modern runtime readiness.

No Android product source changes were required. No `ios/**`, shared `Docs/**`,
or `.cron/**` files were edited.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-connected-boot-blocker-batch185-20260510.md`

Gradle also refreshed generated Android-local build outputs and the Gradle
problems report under ignored `build/` directories while preparing connected
test artifacts.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android`.

- Timestamp: `2026-05-10 09:35:01 CST +0800`.
- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Explicit JDK used for Gradle commands:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
- Explicit Java version: OpenJDK `17.0.17` (`Homebrew 17.0.17+0`).
- Android SDK path: `/Users/wangweiyang/Library/Android/sdk`.
- Maven resolution used local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.
- Available AVDs: `Medium_Phone`.
- Attached Android devices at batch start: none.
- Filesystem free space at the AVD, SDK, and worktree volume: `3.3Gi`.

Passing Gradle commands used this scoped environment:

```bash
JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
PATH=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin:$PATH
ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk
ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk
```

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported OpenJDK `17.0.17`. |
| `/Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices -l` | BLOCKED for device validation | Printed only `List of devices attached`; no device rows. |
| `/Users/wangweiyang/Library/Android/sdk/emulator/emulator -list-avds` | PARTIAL | Listed one available AVD: `Medium_Phone`. |
| `/Users/wangweiyang/Library/Android/sdk/emulator/emulator -avd Medium_Phone -no-snapshot-load -no-snapshot-save -no-boot-anim -netdelay none -netspeed full` | BLOCKED | Emulator exited before boot because the AVD userdata partition could not be created with current disk space. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true projects` | PASS | `BUILD SUCCESSFUL in 14s`; project graph listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `bash tools/device_validation_preflight.sh` | BLOCKED | Reported 5 blockers: no attached Android device/emulator, no API 27 system image, no attached API 27 target, no low-memory/small-screen runtime, and no attached API 34+ modern runtime. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true :app:connectedDebugAndroidTest` | BLOCKED / FAIL | Debug app and androidTest APK preparation completed, then `:app:connectedDebugAndroidTest` failed with `DeviceException: No connected devices!`; `BUILD FAILED in 1m 21s`; `152 actionable tasks: 12 executed, 140 up-to-date`. |
| `find /Users/wangweiyang/Library/Android/sdk/platforms -maxdepth 1 -type d -name 'android-*'` | PARTIAL | Installed platforms are API 31, 32, 33, 34, 35, and 36; no API 27 platform is installed. |
| `find /Users/wangweiyang/Library/Android/sdk/system-images -maxdepth 4 -type d` | PARTIAL | Installed system images are Android 36 only; no Android API 27 system image is installed. |
| `ls -l /Users/wangweiyang/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager /Users/wangweiyang/Library/Android/sdk/cmdline-tools/latest/bin/avdmanager` | BLOCKED | Both expected SDK command-line tools are missing at that path. |

Gradle printed its standard non-failing deprecation warning about future Gradle
10 compatibility during wrapper-backed commands.

## Emulator Boot Attempt

`Medium_Phone` did not become available for connected validation. The emulator
found the Android 36 Play Store 16 KB page-size image, passed basic host
compatibility checks, and then exited with this blocker:

```text
ERROR | Not enough space to create userdata partition. Available: 3135.328125 MB at /Users/wangweiyang/.android/avd/../avd/Medium_Phone.avd, need 7372.800000 MB.
```

`df -h` reported only `3.3Gi` available on `/System/Volumes/Data`, the volume
holding the AVD, SDK, and FastMD worktree paths.

## Connected Test Attempt

The connected test command prepared the debug app and androidTest APK inputs
before failing at device execution:

```text
> Task :app:connectedDebugAndroidTest FAILED

Execution failed for task ':app:connectedDebugAndroidTest'.
> com.android.builder.testing.api.DeviceException: No connected devices!

BUILD FAILED in 1m 21s
152 actionable tasks: 12 executed, 140 up-to-date
```

This confirms the current blocker is runtime availability, not Kotlin
compilation, resource processing, app packaging, or androidTest packaging.

## Device Preflight Output

`tools/device_validation_preflight.sh` reported:

```text
BLOCKED: No attached Android device or booted emulator is available for connectedDebugAndroidTest.
BLOCKED: No Android API 27 system image is installed under /Users/wangweiyang/Library/Android/sdk/system-images.
BLOCKED: No attached API 27 device/emulator is ready for Android 8.1 validation.
BLOCKED: No attached low-memory device/emulator was detected for low-memory/small-screen validation.
BLOCKED: No attached API 34+ device/emulator is ready for modern-device validation.
BLOCKED: Android device validation preflight found 5 blocker(s).
```

Installed SDK platforms:

```text
/Users/wangweiyang/Library/Android/sdk/platforms/android-31
/Users/wangweiyang/Library/Android/sdk/platforms/android-32
/Users/wangweiyang/Library/Android/sdk/platforms/android-33
/Users/wangweiyang/Library/Android/sdk/platforms/android-34
/Users/wangweiyang/Library/Android/sdk/platforms/android-35
/Users/wangweiyang/Library/Android/sdk/platforms/android-36
```

Installed system images:

```text
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis/arm64-v8a
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore/arm64-v8a
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore_ps16k/arm64-v8a
```

## Current Runtime Blockers

Keep these Android L12 checklist items open from this batch:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

Current blockers:

- No attached Android device is available.
- `Medium_Phone` is the only listed AVD, and it cannot boot with current disk
  space because the emulator needs about `7372.8 MB` for userdata while about
  `3135.3 MB` is available at the AVD path.
- No Android API 27 platform is installed under the local SDK.
- No Android API 27 system image is installed under the local SDK.
- The expected SDK command-line tools `sdkmanager` and `avdmanager` are missing
  under `cmdline-tools/latest/bin`, so this batch could not install API 27
  tooling or create a matching API 27 emulator locally.
- No attached API 27, low-memory/small-screen, or API 34+ modern runtime was
  available during this batch.

## Supervisor Checklist Recommendation

Do not mark any new Android L12 runtime checklist item complete from this
batch. This report is blocker evidence for:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

Use the `./gradlew projects` result here only as the required minimum host
sanity check for a blocked Android validation batch.
