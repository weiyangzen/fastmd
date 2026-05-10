# Stage 1 Android L12 Device Preflight Tool Batch 102

Date: 2026-05-06

Worker: FastMD Stage 1 Mobile Android live lane

Ownership: Android-only. This batch wrote only under `android/**` and did not
edit shared `Docs/**`, `ios/**`, or `.cron/**`.

## Scope

The earliest still-open Android-owned cluster is L12 Platform Validation. Recent
Android report
`android/docs/reports/stage1-android-l12-gradle-validation-refresh-batch100-20260506.md`
already captured PASS evidence for non-device Gradle gates. This bounded batch
advanced the next device-backed validation items by adding a repeatable
Android-local preflight tool and rerunning the connected instrumentation gate.

Targeted open checklist items:

- L12: Run Android `./gradlew :app:connectedDebugAndroidTest`.
- L12: Run Android API 27 validation.
- L12: Run Android low-memory/small-screen profile validation.
- L12: Run Android modern device validation.

## Implementation

Added:

- `android/tools/device_validation_preflight.sh`

The tool checks:

- Android SDK, ADB, emulator, and system image paths.
- Attached `adb devices -l` targets.
- Attached target API level, model, screen size, and memory when available.
- Local Android API 27 system image availability.
- Local AVD list.
- Readiness for connected instrumentation, API 27 validation,
  low-memory/small-screen validation, and modern-device validation.

The script is Bash 3-compatible for macOS default shell environments.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `bash -n tools/device_validation_preflight.sh` | PASS | Shell syntax check completed with exit code 0. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon projects --stacktrace` | PASS | Root project `fastmd-android` evaluated and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 18s`. |
| `JAVA_HOME=... ANDROID_SDK_ROOT=... bash tools/device_validation_preflight.sh` | BLOCKED for device-backed validation | Exited 2 after reporting blockers. ADB printed only `List of devices attached`; system images contain Android 36 only; local AVD list contains `Medium_Phone`; no attached API 27, low-memory, or API 34+ device/emulator is ready. |
| `./tools/device_validation_preflight.sh` | BLOCKED for device-backed validation | Exited 2 after reporting the same readiness blockers with default SDK discovery and no `JAVA_HOME`: no attached device, no API 27 system image, no attached API 27 target, no attached low-memory target, and no attached API 34+ target. |
| `JAVA_HOME=... ANDROID_SDK_ROOT=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon :app:connectedDebugAndroidTest --stacktrace` | BLOCKED by no device | Gradle built or reused debug app and androidTest APK artifacts, then `:app:connectedDebugAndroidTest` failed with `com.android.builder.testing.api.DeviceException: No connected devices!`; `BUILD FAILED in 21s`. |

## Device Preflight Output Summary

```text
== ADB Devices ==
List of devices attached

BLOCKED: No attached Android device or booted emulator is available for connectedDebugAndroidTest.

== System Images ==
/Users/wangweiyang/Library/Android/sdk/system-images/android-36
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis/arm64-v8a
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore/arm64-v8a
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore_ps16k/arm64-v8a
BLOCKED: No Android API 27 system image is installed under /Users/wangweiyang/Library/Android/sdk/system-images.

== AVDs ==
Medium_Phone

== Checklist Readiness ==
BLOCKED: No attached API 27 device/emulator is ready for Android 8.1 validation.
BLOCKED: No attached low-memory device/emulator was detected for low-memory/small-screen validation.
BLOCKED: No attached API 34+ device/emulator is ready for modern-device validation.

== Summary ==
BLOCKED: Android device validation preflight found 5 blocker(s).
```

## Blockers Preserved

- `./gradlew :app:connectedDebugAndroidTest` remains open because no Android
  device or booted emulator is attached.
- Android API 27 validation remains open because no API 27 system image is
  installed and no attached API 27 device/emulator is present.
- Android low-memory/small-screen validation remains open because no attached
  low-memory or small-screen Android target is present.
- Android modern-device validation remains open because no attached API 34+
  target is present.

## Supervisor Checklist Recommendation

Do not mark new L12 device-backed checklist items complete from this batch.
This batch adds repeatable Android-local evidence tooling and refreshes blocker
evidence for:

- L12: Run Android `./gradlew :app:connectedDebugAndroidTest`.
- L12: Run Android API 27 validation.
- L12: Run Android low-memory/small-screen profile validation.
- L12: Run Android modern device validation.

Evidence path:

- `android/docs/reports/stage1-android-l12-device-preflight-tool-batch102-20260506.md`
