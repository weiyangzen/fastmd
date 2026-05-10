# Stage 1 Android L12 API 27 Validation Blocker - Batch 182

Date: 2026-05-10 09:06 CST

Worker scope: Android live lane, `android/**` only.

## Batch Selection

The earliest still-open Android-owned item in the authoritative blueprint and
daily snapshot is Android L12 platform validation. Host Gradle validation,
connected modern-emulator validation, constrained small-screen validation, and
the Android performance report already have Android-local evidence in earlier
reports. This bounded batch therefore targeted the remaining API 27 runtime
validation item:

- Run Android API 27 validation.

No Android product source changes were required. No `ios/**`, shared `Docs/**`,
or `.cron/**` files were edited.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-api27-validation-blocker-batch182-20260510.md`

Gradle refreshed generated Android-local metadata under ignored `build/`
directories while running the minimum host sanity gate.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android`.

- Timestamp: `2026-05-10 09:06:50 CST +0800`.
- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Default shell Java: blocked by macOS Java registration with
  `Unable to locate a Java Runtime`.
- Explicit JDK used for the passing Gradle command:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
- Explicit Java version: OpenJDK `17.0.17` (`Homebrew 17.0.17+0`).
- Android SDK path: `/Users/wangweiyang/Library/Android/sdk`.
- Available AVDs: `Medium_Phone`.

Passing Gradle command used this scoped environment:

```bash
JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home \
PATH=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin:$PATH \
ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk \
ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk
```

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED | macOS reported `Unable to locate a Java Runtime`. |
| `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported OpenJDK `17.0.17`. |
| `./gradlew projects --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true` with explicit JDK 17 and SDK env | PASS | `BUILD SUCCESSFUL in 13s`; project graph listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `adb devices -l` | BLOCKED for API 27 runtime validation | Printed only `List of devices attached`; no device rows. |
| `bash tools/device_validation_preflight.sh` with explicit JDK 17 and SDK env | BLOCKED | Reported 5 blockers: no attached Android device/emulator, no API 27 system image, no attached API 27 target, no attached low-memory/small-screen runtime, and no attached API 34+ runtime. |
| `sdkmanager --version` at expected SDK cmdline-tools path | BLOCKED | Missing `/Users/wangweiyang/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager`. |
| `avdmanager list avd` at expected SDK cmdline-tools path | BLOCKED | Missing `/Users/wangweiyang/Library/Android/sdk/cmdline-tools/latest/bin/avdmanager`. |
| `emulator -list-avds` | PARTIAL | Listed only `Medium_Phone`, which is an Android 36 AVD. |

Gradle printed the standard non-failing warning:

```text
Deprecated Gradle features were used in this build, making it incompatible with Gradle 10.
```

## Installed Android SDK State

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

No Android API 27 platform or system image is installed locally. No device or
booted emulator was attached during this batch.

## Device Preflight Output

`tools/device_validation_preflight.sh` reported:

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

## API 27 Status

Keep this Android L12 checklist item open:

- Run Android API 27 validation.

Current blockers:

- No Android API 27 platform is installed under the local SDK `platforms/`.
- No Android API 27 system image is installed under the local SDK
  `system-images/`.
- No attached API 27 Android device or booted API 27 emulator is available.
- SDK command-line tools are incomplete because `sdkmanager` and `avdmanager`
  are missing at `cmdline-tools/latest/bin/`, so this batch could not provision
  an API 27 image or AVD locally.

## Supervisor Checklist Recommendation

Do not mark any new Android L12 checklist item complete from this batch.

This report is blocker evidence only for:

- Run Android API 27 validation.

