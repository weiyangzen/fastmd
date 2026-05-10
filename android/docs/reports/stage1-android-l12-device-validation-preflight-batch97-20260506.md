# Stage 1 Android L12 Device Validation Preflight Batch 97

Date: 2026-05-06

Worker: FastMD Stage 1 Mobile Android live lane

Ownership: Android-only. This batch wrote only under `android/docs/reports/**`.

## Scope

Earliest still-open Android-owned checklist cluster is L12 Platform Validation.
Pure Gradle gates and the Android performance report already have prior Android
evidence. This batch targeted the next device-backed validation item:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Recheck whether the existing local AVD can cover Android modern-device
  validation.

## Environment

- Repository: `/Users/wangweiyang/GitHub/fastmd`
- Android project: `/Users/wangweiyang/GitHub/fastmd/android`
- Android SDK: `/Users/wangweiyang/Library/Android/sdk`
- Explicit JDK used for Gradle:
  `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`
- JDK version: OpenJDK `17.0.17`
- Existing AVD: `Medium_Phone`
- Existing AVD target: `android-36`
- Existing AVD image:
  `system-images/android-36/google_apis_playstore_ps16k/arm64-v8a/`
- Existing AVD profile: 1080x2400, density 420, 2048 MB RAM, 4 CPU cores

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `ANDROID_SDK_ROOT=... adb devices -l` | BLOCKED for device validation | ADB ran successfully but printed only `List of devices attached`; no device or emulator was attached. |
| `emulator -list-avds` | PASS | Listed `Medium_Phone`. |
| Read `~/.android/avd/Medium_Phone.ini` and `config.ini` | PASS | Confirms the existing AVD targets `android-36`; this can only serve modern-device validation, not API 27 or low-memory/small-screen validation. |
| `emulator -avd Medium_Phone -no-window -no-audio -no-boot-anim -no-snapshot-save` | BLOCKED | Emulator exited before boot: `Not enough space to create userdata partition. Available: 5633.777344 MB ... need 7372.800000 MB.` |
| `emulator -avd Medium_Phone -no-window -no-audio -no-boot-anim -no-snapshot-load -no-snapshot-save -partition-size 2048` | BLOCKED | Emulator exited before boot with the same userdata allocation requirement: `Available: 5140.957031 MB ... need 7372.800000 MB.` |
| `df -m /Users/wangweiyang/.android/avd/Medium_Phone.avd /Users/wangweiyang/GitHub/fastmd/android` | BLOCKED context | `/System/Volumes/Data` had about `5139` MB available and was reported at `100%` capacity. |
| `JAVA_HOME=... ANDROID_SDK_ROOT=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon projects --stacktrace` | PASS | Root project `fastmd-android` evaluated and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 13s`. |
| `JAVA_HOME=... ANDROID_SDK_ROOT=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon :app:connectedDebugAndroidTest --stacktrace` | BLOCKED by no device | Gradle built or reused the debug app and androidTest APKs, then `:app:connectedDebugAndroidTest` failed with `com.android.builder.testing.api.DeviceException: No connected devices!`; `BUILD FAILED in 20s`. |

## Preserved Blockers

- `./gradlew :app:connectedDebugAndroidTest` remains open because no Android
  device or booted emulator is available.
- The existing `Medium_Phone` Android 36 AVD cannot boot in the current local
  disk state because the emulator needs about 7372.8 MB for userdata allocation
  and only about 5.1-5.6 GB was available during this batch.
- Android API 27 validation remains open because the installed SDK system images
  only include Android 36 images and the existing AVD targets Android 36.
- Android low-memory/small-screen profile validation remains open because the
  existing AVD is a medium phone profile with 2048 MB RAM, not a matching
  low-memory or small-screen target.
- Android modern-device validation remains open because the Android 36 AVD did
  not boot and no physical modern Android device was attached.

## Supervisor Checklist Recommendation

Do not mark any additional L12 Android device-backed checklist item complete
from this batch.

Keep these checklist items open:

- L12: Run Android `./gradlew :app:connectedDebugAndroidTest`.
- L12: Run Android API 27 validation.
- L12: Run Android low-memory/small-screen profile validation.
- L12: Run Android modern device validation.

This report is fresh blocker evidence for those open Android L12 items.
