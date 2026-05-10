# Stage 1 Android L12 API 27 Validation Blocker - Batch 179

Date: 2026-05-10 08:47 CST

Worker scope: Android live lane, `android/**` only.

## Batch Selection

The authoritative blueprint and daily todo snapshot leave Android L12 platform
validation open. Recent Android-local reports already provide passing evidence
for host Gradle validation, connected Android 36 instrumentation, modern-device
validation, constrained small-screen validation, and the source-level Android
performance report.

This bounded batch targeted the earliest remaining Android-owned L12 item
without passing local evidence:

- Run Android API 27 validation.

No Android product source changes were required. No `ios/**`, shared `Docs/**`,
or `.cron/**` files were edited.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-api27-validation-blocker-batch179-20260510.md`

Gradle refreshed Android-local generated metadata under ignored `build/`
directories while running `projects`.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android`.

- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Default shell Java: blocked by macOS Java registration.
- Explicit JDK used for Gradle validation:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
- Explicit Java version: OpenJDK `17.0.17` (`Homebrew 17.0.17+0`).
- Android SDK path: `/Users/wangweiyang/Library/Android/sdk`.
- Maven resolution used local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.
- Available AVD observed: `Medium_Phone`.
- Attached Android devices: none.
- Free space on the shared SDK/AVD/repository volume: `4.3 GiB`.
- SDK command-line tools blocker: no local `sdkmanager` or `avdmanager`
  executable was found under the expected SDK path or on `PATH`.

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
PATH=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin:$PATH \
ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk \
ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk \
./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true ...
```

| Command | Result | Evidence |
| --- | --- | --- |
| `date '+%Y-%m-%d %H:%M:%S %Z %z'` | PASS | Printed `2026-05-10 08:47:09 CST +0800`. |
| `java -version` | BLOCKED | macOS reported `Unable to locate a Java Runtime`. |
| `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported OpenJDK `17.0.17`. |
| `./gradlew projects --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true` with explicit JDK 17 and SDK env | PASS | `BUILD SUCCESSFUL in 13s`; confirmed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `/Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices -l` | BLOCKED for API 27 runtime validation | Printed only `List of devices attached`; no device rows. |
| `/Users/wangweiyang/Library/Android/sdk/emulator/emulator -list-avds` | PARTIAL | Printed `Medium_Phone`; it is not an API 27 AVD. |
| `find /Users/wangweiyang/Library/Android/sdk/platforms -maxdepth 1 -type d -name 'android-*'` | BLOCKED for API 27 runtime validation | Installed platforms are Android 31 through Android 36 only. |
| `find /Users/wangweiyang/Library/Android/sdk/system-images -maxdepth 3 -type d` | BLOCKED for API 27 runtime validation | Installed system images are Android 36 only. |
| `command -v sdkmanager` and expected SDK `cmdline-tools/latest/bin/sdkmanager` check | BLOCKED | No `sdkmanager` executable found. |
| `command -v avdmanager` and expected SDK `cmdline-tools/latest/bin/avdmanager` check | BLOCKED | No `avdmanager` executable found. |
| `ANDROID_HOME=... ANDROID_SDK_ROOT=... JAVA_HOME=... bash tools/device_validation_preflight.sh` | BLOCKED | Found 5 blockers: no attached Android device/emulator, no API 27 system image, no attached API 27 target, no low-memory target currently attached, and no API 34+ target currently attached. |

Gradle printed the standard deprecation warning about future Gradle 10
compatibility. It did not fail `./gradlew projects`.

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

## Checklist Evidence For Supervisor

Keep this L12 item open:

- Run Android API 27 validation.

Reason: no Android API 27 platform or system image is installed, no attached API
27 device/emulator is available, no local `sdkmanager` or `avdmanager`
executable was found, and the host has only `4.3 GiB` free on the shared
SDK/AVD/repository volume.

This report is blocker evidence only. It does not supersede recent passing
Android-local evidence for host Gradle validation, connected Android 36
instrumentation, modern-device validation, low-memory/small-screen constrained
emulator validation, or Android performance report capture.
