# Stage 1 Android L12 Host And Runtime Validation Batch 168 - 2026-05-10

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
platform validation items from `Docs/Stage1_Mobile_Blueprint.md` and
`Docs/todos_20260506.md`.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android product source changes were required. The only intentional repository
write in this batch is this Android-local evidence report.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-host-and-runtime-validation-batch168-20260510.md`

Gradle also refreshed Android-local generated build metadata, reports, and APK
outputs under ignored `build/` directories while running validation.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-10 around 07:12 CST.

- Gradle entry point: checked-in wrapper `./gradlew`.
- Android SDK path: `/Users/wangweiyang/Library/Android/sdk`.
- Default shell Java: blocked by macOS Java registration.
- JDK actually used for this batch's Gradle commands:
  `/Applications/Android Studio.app/Contents/jbr/Contents/Home`.
- Android Studio JBR version: OpenJDK `21.0.6`.
- Homebrew OpenJDK 17 is also available at
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home` and reports
  OpenJDK `17.0.17`.
- Maven mirror opt-in used for Gradle commands:
  `-Pfastmd.useChinaMavenMirror=true`.

The default shell Java command still fails before Gradle can start:

```text
The operation couldn't be completed. Unable to locate a Java Runtime.
Please visit http://www.java.com for information on installing Java.
```

The checked-in Gradle wrapper works when `JAVA_HOME` and `PATH` are scoped to an
available local JDK.

## Host Gradle Validation Results

Passing Gradle commands below used this environment prefix:

```bash
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" \
PATH="/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin:$PATH" \
ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk \
ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk
```

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED | macOS reported `Unable to locate a Java Runtime`. |
| `"/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/java" -version` | PASS | Reported OpenJDK `21.0.6`. |
| `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported Homebrew OpenJDK `17.0.17`. |
| `./gradlew projects --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true` | PASS | `BUILD SUCCESSFUL in 3s`; module graph includes `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `./gradlew lint build :core:testDebugUnitTest :feature:reader:testDebugUnitTest :app:assembleDebug --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true` | PASS | `BUILD SUCCESSFUL in 2m 14s`; `474 actionable tasks: 56 executed, 418 up-to-date`. |

The combined host Gradle command covered these L12 checklist items:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.

The root `build` task also ran the Android Stage 1 renderer asset/request
blocking audit gates wired into `check`; those gates passed without WebView,
web-runtime, remote-subresource, dynamic-code, or renderer request-policy
violations.

Generated test XML under `build/test-results/testDebugUnitTest` summarizes to:

```text
tests=82 skipped=0 failures=0 errors=0
```

Representative Android-local artifacts present after this batch:

- `android/app/build/outputs/apk/debug/app-debug.apk`
- `android/app/build/reports/lint-results-debug.html`
- `android/core/build/reports/lint-results-debug.html`
- `android/feature/library/build/reports/lint-results-debug.html`
- `android/feature/reader/build/reports/lint-results-debug.html`
- `android/feature/settings/build/reports/lint-results-debug.html`
- `android/app/build/reports/tests/testDebugUnitTest/index.html`
- `android/core/build/reports/tests/testDebugUnitTest/index.html`
- `android/feature/reader/build/reports/tests/testDebugUnitTest/index.html`
- `android/build/reports/problems/problems-report.html`

Gradle printed its standard non-failing deprecation warning:

```text
Deprecated Gradle features were used in this build, making it incompatible with Gradle 10.
```

## Runtime And Device Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `adb devices -l` | BLOCKED for device validation | Printed only `List of devices attached`; no device rows. |
| `emulator -list-avds` | PARTIAL | Printed `Medium_Phone`. |
| `emulator -avd Medium_Phone -no-snapshot-save -no-boot-anim -gpu swiftshader_indirect -no-audio -no-window` | BLOCKED | Emulator exited before ADB attach because there was not enough host disk space to create the userdata partition. |
| `df -m /Users/wangweiyang/.android/avd/Medium_Phone.avd` | BLOCKED context | Reported `5223` MiB available on `/System/Volumes/Data`, 100% capacity. |
| `bash tools/device_validation_preflight.sh` | BLOCKED | Found 5 blockers: no attached runtime, no API 27 system image, no attached API 27 runtime, no attached low-memory runtime, and no attached API 34+ runtime. |
| `./gradlew :app:connectedDebugAndroidTest --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true` | BLOCKED / FAIL | Gradle reached debug app and androidTest APK preparation, then failed with `com.android.builder.testing.api.DeviceException: No connected devices!`; `BUILD FAILED in 13s`. |

ADB device discovery printed:

```text
List of devices attached
```

The `Medium_Phone` AVD exists, but it is an Android 36 modern profile, not API
27:

```text
target = android-36
image.sysdir.1 = system-images/android-36/google_apis_playstore_ps16k/arm64-v8a/
hw.ramSize = 2048
disk.dataPartition.size = 6442450944
```

The bounded boot attempt failed before a device appeared in ADB:

```text
ERROR        | Not enough space to create userdata partition. Available: 5651.781250 MB at /Users/wangweiyang/.android/avd/../avd/Medium_Phone.avd, need 7372.800000 MB.
```

Fresh disk context after the failed boot attempt:

```text
Filesystem   1M-blocks   Used Available Capacity iused    ifree %iused  Mounted on
/dev/disk3s5    948584 918564      5223   100% 9950387 53491560   16%   /System/Volumes/Data
```

The device preflight summary was:

```text
BLOCKED: No attached Android device or booted emulator is available for connectedDebugAndroidTest.
BLOCKED: No Android API 27 system image is installed under /Users/wangweiyang/Library/Android/sdk/system-images.
BLOCKED: No attached API 27 device/emulator is ready for Android 8.1 validation.
BLOCKED: No attached low-memory device/emulator was detected for low-memory/small-screen validation.
BLOCKED: No attached API 34+ device/emulator is ready for modern-device validation.
BLOCKED: Android device validation preflight found 5 blocker(s).
```

The connected instrumentation command reached app/test APK preparation before
device execution failed:

```text
Execution failed for task ':app:connectedDebugAndroidTest'.
> com.android.builder.testing.api.DeviceException: No connected devices!
```

## Remaining Device Validation Blockers

Keep these Android L12 checklist items open until separate device-backed
evidence exists:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

Current blockers:

- No Android device is attached.
- The only listed AVD, `Medium_Phone`, failed to boot because the AVD path does
  not have enough free disk space for the userdata partition.
- No Android API 27 system image is installed under
  `/Users/wangweiyang/Library/Android/sdk/system-images`.
- The only listed AVD targets Android 36, so it cannot satisfy API 27
  validation even after disk space is freed.
- No attached low-memory target was detected.

## Supervisor Checklist Recommendation

The supervising session can use this report as fresh Android-lane evidence for
marking these L12 Android checklist items complete if not already reconciled:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.

Do not use this report to newly claim completion for connected-device, API 27
runtime, low-memory/small-screen runtime, modern-device runtime, or Android
performance report items.
