# Stage 1 Android L12 Connected Runtime Blocker - Batch 183

Date: 2026-05-10 09:13 CST

Worker scope: Android live lane, `android/**` only.

## Batch Selection

The authoritative blueprint and daily todo snapshot still leave Android L12
platform validation open. Recent Android-local reports already provide passing
host evidence for `lint`, `build`, `:core:testDebugUnitTest`,
`:feature:reader:testDebugUnitTest`, `:app:assembleDebug`, modern connected
validation, constrained small-screen validation, and the source-level Android
performance report. This bounded batch therefore targeted the earliest
remaining runtime-sensitive Android item that could be rechecked locally:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Re-check Android API 27 validation readiness.
- Re-check low-memory/small-screen and modern-device runtime availability.

No Android product source changes were required. No `ios/**`, shared `Docs/**`,
or `.cron/**` files were edited.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-connected-runtime-blocker-batch183-20260510.md`

Gradle also refreshed generated Android-local build outputs under ignored
`build/` directories while preparing the connected test APKs.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android`.

- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Explicit JDK used for Gradle validation:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
- Java version: OpenJDK `17.0.17` (`Homebrew 17.0.17+0`).
- Android SDK path: `/Users/wangweiyang/Library/Android/sdk`.
- Maven resolution used local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.
- Listed AVDs: `Medium_Phone`.
- Attached Android devices at batch time: none.

The default shell still does not expose a Java runtime unless `JAVA_HOME` is
pinned for Gradle commands.

## Validation Results

Passing or attempted Gradle commands used:

```bash
JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home \
ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk \
ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk \
./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true ...
```

| Command | Result | Evidence |
| --- | --- | --- |
| `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported OpenJDK `17.0.17`. |
| `./gradlew projects` | PASS | `BUILD SUCCESSFUL in 13s`; project graph listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `/Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices -l` | BLOCKED for device validation | Printed only `List of devices attached`; no device rows. |
| `/Users/wangweiyang/Library/Android/sdk/emulator/emulator -list-avds` | PASS | Listed one available AVD: `Medium_Phone`. No emulator was running. |
| `./gradlew :app:connectedDebugAndroidTest` | BLOCKED / FAIL | Gradle prepared the app and androidTest APKs, then `:app:connectedDebugAndroidTest` failed with `DeviceException: No connected devices!`; `BUILD FAILED in 19s`; `152 actionable tasks: 6 executed, 146 up-to-date`. |
| `bash tools/device_validation_preflight.sh` with Android SDK env | BLOCKED | Reported 5 blockers: no attached Android device/emulator, no API 27 system image, no attached API 27 target, no attached low-memory/small-screen runtime, and no attached API 34+ modern runtime. |
| `find /Users/wangweiyang/Library/Android/sdk/platforms -maxdepth 1 -type d -name 'android-*'` | PARTIAL | Installed platforms are API 31, 32, 33, 34, 35, and 36; no API 27 platform is installed. |
| `find /Users/wangweiyang/Library/Android/sdk/system-images -maxdepth 4 -type d` | PARTIAL | Installed system images are Android 36 only. No `android-27` system image is installed. |
| `ls -l /Users/wangweiyang/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager /Users/wangweiyang/Library/Android/sdk/cmdline-tools/latest/bin/avdmanager` | BLOCKED | Both expected SDK command-line tools are missing at that path, so this batch could not install or create an API 27 emulator image locally. |

Gradle printed its standard non-failing deprecation warning about future Gradle
10 compatibility during the wrapper-backed commands.

## Connected Test Attempt

The connected test command reached APK preparation successfully before device
execution failed. Existing generated artifacts are present:

- `android/app/build/outputs/apk/debug/app-debug.apk`
- `android/app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk`
- `android/build/reports/problems/problems-report.html`

The actionable blocker is the runtime environment, not Kotlin compilation,
resource processing, app packaging, or androidTest packaging:

```text
Execution failed for task ':app:connectedDebugAndroidTest'.
> com.android.builder.testing.api.DeviceException: No connected devices!
```

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

Installed system images remain Android 36 only:

```text
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis/arm64-v8a
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore/arm64-v8a
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore_ps16k/arm64-v8a
```

## Checklist Evidence For Supervisor

This report is current Android-lane evidence that the remaining API 27 runtime
validation is still blocked locally:

- Run Android API 27 validation.

Reason: no Android API 27 platform or system image is installed, no attached API
27 device/emulator is available, and local SDK command-line tools are missing at
`cmdline-tools/latest/bin/sdkmanager` and `cmdline-tools/latest/bin/avdmanager`.

Do not use this report to newly mark `:app:connectedDebugAndroidTest`,
low-memory/small-screen runtime validation, or modern-device validation complete.
Those items already have separate prior Android-local evidence when a temporary
modern constrained emulator was running, but the current batch found no attached
runtime and did not produce a new passing device-backed run.
