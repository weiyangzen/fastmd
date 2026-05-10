# Stage 1 Android L12 API 27 Validation Blocker - Batch 177

Date: 2026-05-10 08:38 CST

Worker scope: Android live lane, `android/**` only.

## Batch Selection

The authoritative blueprint and daily todo snapshot still leave Android L12
platform validation open. Recent Android-local reports already provide current
evidence for host Gradle validation, connected Android 36 instrumentation,
modern-device validation, constrained-emulator small-screen validation, and the
source-level Android performance report.

This bounded batch targeted the earliest remaining Android-owned L12 item:

- Run Android API 27 validation.

No Android product source changes were required. No `ios/**`, shared `Docs/**`,
or `.cron/**` files were edited.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-api27-validation-blocker-batch177-20260510.md`

Gradle refreshed Android-local generated output under ignored `build/`
directories while running validation.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android`.

- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Explicit JDK:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
- Java version: OpenJDK `17.0.17` (`Homebrew 17.0.17+0`).
- Android SDK path: `/Users/wangweiyang/Library/Android/sdk`.
- Maven resolution used local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.
- Available AVD observed: `Medium_Phone`.
- Attached Android devices: none.
- SDK command-line tools blocker:
  `/Users/wangweiyang/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager`
  is not executable or is missing.

Installed Android platforms observed:

```text
/Users/wangweiyang/Library/Android/sdk/platforms/android-31
/Users/wangweiyang/Library/Android/sdk/platforms/android-32
/Users/wangweiyang/Library/Android/sdk/platforms/android-33
/Users/wangweiyang/Library/Android/sdk/platforms/android-34
/Users/wangweiyang/Library/Android/sdk/platforms/android-35
/Users/wangweiyang/Library/Android/sdk/platforms/android-36
```

Installed Android system images observed:

```text
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis/arm64-v8a
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore/arm64-v8a
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore_ps16k/arm64-v8a
```

No Android API 27 platform or system image is installed locally.

## Validation Results

Passing Gradle commands used:

```bash
JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home \
ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk \
ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk \
./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true ...
```

| Command | Result | Evidence |
| --- | --- | --- |
| `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported OpenJDK `17.0.17`. |
| `./gradlew projects` | PASS | `BUILD SUCCESSFUL in 12s`; confirmed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `/Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices -l` | BLOCKED for device validation | Printed only `List of devices attached`; no attached device rows. |
| `/Users/wangweiyang/Library/Android/sdk/emulator/emulator -list-avds` | PARTIAL | Printed `Medium_Phone`; it is not an API 27 AVD. |
| `find /Users/wangweiyang/Library/Android/sdk/system-images -maxdepth 4 -type d` | BLOCKED for API 27 validation | Only Android 36 system images were present. |
| `test -x /Users/wangweiyang/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager` | BLOCKED | Exit code `1`; this batch could not install missing API 27 SDK components through the expected local SDK manager path. |
| `ANDROID_HOME=... ANDROID_SDK_ROOT=... bash tools/device_validation_preflight.sh` | BLOCKED | Found 5 blockers: no attached Android device/emulator, no API 27 system image, no attached API 27 target, no low-memory target currently attached, and no API 34+ target currently attached. |

Gradle printed the standard deprecation warning about future Gradle 10
compatibility. It did not fail `./gradlew projects`.

## Device Preflight Output

The project preflight reported:

```text
== Android Device Validation Preflight ==
INFO: Android project: /Users/wangweiyang/GitHub/fastmd/android
INFO: Android SDK: /Users/wangweiyang/Library/Android/sdk
INFO: JAVA_HOME: /usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home

== ADB Devices ==
List of devices attached

BLOCKED: No attached Android device or booted emulator is available for connectedDebugAndroidTest.

== System Images ==
/Users/wangweiyang/Library/Android/sdk/system-images
/Users/wangweiyang/Library/Android/sdk/system-images/android-36
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis/arm64-v8a
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis/arm64-v8a/data
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore/arm64-v8a
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore/arm64-v8a/data
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore_ps16k
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore_ps16k/arm64-v8a
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore_ps16k/arm64-v8a/data
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

## Checklist Evidence For Supervisor

Keep this L12 item open:

- Run Android API 27 validation.

Reason: no Android API 27 platform or system image is installed, no attached API
27 device/emulator is available, and the expected local `sdkmanager` path is
missing so this batch could not install the required Android 8.1 emulator
components.

This report is blocker evidence only. It does not supersede the recent passing
Android-local evidence for host Gradle validation, connected Android 36
instrumentation, modern-device validation, low-memory/small-screen constrained
emulator validation, or Android performance report capture.
