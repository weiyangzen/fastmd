# Stage 1 Android L12 API 27 Validation Blocker Batch 142 - 2026-05-10

## Scope

Android live-lane bounded batch for the earliest Android-owned L12 validation
item that still lacks pass evidence in the local environment:

- Run Android API 27 validation.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android product source changes were made. The only intentional repository
write in this batch is this Android-local evidence report.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-api27-validation-blocker-batch142-20260510.md`

Gradle also refreshed generated Android-local metadata under `android/build/`
while running the project sanity command.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-10 at approximately 03:05 CST.

- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Explicit JDK used for Gradle sanity:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
- Explicit Java version:
  `openjdk version "17.0.17" 2025-10-21`.
- Android SDK path:
  `/Users/wangweiyang/Library/Android/sdk`.
- Maven resolution used local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported Homebrew OpenJDK `17.0.17`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true projects` | PASS | Project graph listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; Gradle reported `BUILD SUCCESSFUL in 14s`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... bash tools/device_validation_preflight.sh` | BLOCKED | No attached Android device or booted emulator, no Android API 27 system image, no attached API 27 runtime, no detected low-memory runtime, and no detected API 34+ runtime in the current device state. |
| `ANDROID_HOME=... ANDROID_SDK_ROOT=... adb devices -l` | BLOCKED for runtime validation | Printed `List of devices attached` with no attached device rows. |
| `ANDROID_HOME=... ANDROID_SDK_ROOT=... emulator -list-avds` | PARTIAL | Listed one local AVD: `Medium_Phone`. Installed system images are Android 36 only, so this is not usable for API 27 validation. |
| `ls -la /Users/wangweiyang/Library/Android/sdk/system-images` | BLOCKED for API 27 validation | The system image directory contains only `android-36`; no `android-27` directory is present. |
| `find /Users/wangweiyang/Library/Android/sdk -type f \( -name sdkmanager -o -name avdmanager -o -name adb -o -name emulator \)` | BLOCKED for local API 27 provisioning | Found `platform-tools/adb` and `emulator/emulator`; no `sdkmanager` or `avdmanager` binary was present under the SDK. |

Gradle printed its standard deprecation warning:

- Deprecated Gradle features were used in this build, making it incompatible
  with Gradle 10.

This warning did not fail the project graph sanity command.

## Device Preflight Output Summary

`tools/device_validation_preflight.sh` reported:

```text
BLOCKED: No attached Android device or booted emulator is available for connectedDebugAndroidTest.
BLOCKED: No Android API 27 system image is installed under /Users/wangweiyang/Library/Android/sdk/system-images.
BLOCKED: No attached API 27 device/emulator is ready for Android 8.1 validation.
BLOCKED: No attached low-memory device/emulator was detected for low-memory/small-screen validation.
BLOCKED: No attached API 34+ device/emulator is ready for modern-device validation.
BLOCKED: Android device validation preflight found 5 blocker(s).
```

The installed system image tree contains Android 36 only:

```text
/Users/wangweiyang/Library/Android/sdk/system-images/android-36
```

The AVD registry currently exposes only:

```text
Medium_Phone
```

## Supervisor Checklist Recommendation

Keep this L12 checklist item open:

- Run Android API 27 validation.

Reason: the local Android SDK has no API 27 system image, no attached API 27
device/emulator is available, and the local SDK does not include `sdkmanager` or
`avdmanager` for creating an API 27 AVD in this bounded batch.

Use this report as current Android-lane evidence that the API 27 validation item
was attempted and is environment-blocked.

Do not use this report to newly claim completion for connected-device,
low-memory/small-screen, modern-device, or performance-report checklist items.
Earlier Android-local reports may provide separate evidence for those items.
