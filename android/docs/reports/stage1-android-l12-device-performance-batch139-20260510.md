# Stage 1 Android L12 Device And Performance Batch 139 - 2026-05-10

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
validation cluster that can be advanced without touching iOS or shared Docs:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.
- Capture Android performance report.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android product source changes were made. The only intentional repository
write in this batch is this Android-local evidence report.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-device-performance-batch139-20260510.md`

Gradle also refreshed generated Android-local build metadata under
`android/build/`, `android/app/build/`, and module `build/` directories while
preparing connected test artifacts.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-10 at approximately 02:50 CST.

- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Explicit JDK used for Gradle commands:
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
| `ANDROID_HOME=... ANDROID_SDK_ROOT=... adb devices -l` | BLOCKED for device validation | Printed only `List of devices attached`; no device or booted emulator rows were present. |
| `ANDROID_HOME=... ANDROID_SDK_ROOT=... emulator -list-avds` | PARTIAL | Listed one local AVD: `Medium_Phone`. |
| `find $ANDROID_SDK_ROOT -type f \( -name sdkmanager -o -name avdmanager -o -name adb -o -name emulator \)` | PARTIAL | Found `adb` and `emulator`; no `sdkmanager` or `avdmanager` binary was present for bounded local API 27 provisioning. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true projects` | PASS | Project graph listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; Gradle reported `BUILD SUCCESSFUL in 13s`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... bash tools/device_validation_preflight.sh` | BLOCKED | Reported 5 blockers: no attached runtime, no API 27 system image, no attached API 27 runtime, no attached low-memory runtime, and no attached API 34+ runtime. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true :app:connectedDebugAndroidTest` | BLOCKED / FAIL | Gradle reached debug app and androidTest APK preparation, then `:app:connectedDebugAndroidTest` failed with `com.android.builder.testing.api.DeviceException: No connected devices!`; Gradle reported `BUILD FAILED in 21s`. |
| `bash tools/audit_performance_report.sh` | PASS | Source-level Android performance posture audit completed and reported `PASS: Android performance report audit completed.` |

Gradle printed its standard deprecation warning:

```text
Deprecated Gradle features were used in this build, making it incompatible with Gradle 10.
```

This warning did not fail project graph validation. The connected test command
failed because no Android runtime was connected.

## Device Preflight Evidence

ADB device discovery printed:

```text
List of devices attached
```

Installed system images are Android 36 only:

```text
/Users/wangweiyang/Library/Android/sdk/system-images
/Users/wangweiyang/Library/Android/sdk/system-images/android-36
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis/arm64-v8a
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore/arm64-v8a
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore_ps16k
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore_ps16k/arm64-v8a
```

Available AVDs:

```text
Medium_Phone
```

The preflight summary was:

```text
BLOCKED: No attached Android device or booted emulator is available for connectedDebugAndroidTest.
BLOCKED: No Android API 27 system image is installed under /Users/wangweiyang/Library/Android/sdk/system-images.
BLOCKED: No attached API 27 device/emulator is ready for Android 8.1 validation.
BLOCKED: No attached low-memory device/emulator was detected for low-memory/small-screen validation.
BLOCKED: No attached API 34+ device/emulator is ready for modern-device validation.
BLOCKED: Android device validation preflight found 5 blocker(s).
```

## Connected Test Evidence

`./gradlew :app:connectedDebugAndroidTest` successfully reached Android test
artifact preparation before failing at device execution. Representative tasks
that completed or were up to date in this run:

- `:app:compileDebugKotlin`
- `:app:packageDebug`
- `:app:compileDebugAndroidTestKotlin`
- `:app:packageDebugAndroidTest`
- `:app:connectedDebugAndroidTest`

Failure:

```text
Execution failed for task ':app:connectedDebugAndroidTest'.
> com.android.builder.testing.api.DeviceException: No connected devices!
```

The command summary was:

```text
BUILD FAILED in 21s
152 actionable tasks: 6 executed, 146 up-to-date
```

## Performance Report Output

`tools/audit_performance_report.sh` produced:

```text
Android performance profile limits:
  WatchCompact softLimitBytes=262144
  LegacyEfficient softLimitBytes=1048576
  ModernStandard softLimitBytes=5242880
  LargeScreen softLimitBytes=5242880
Android fixture size matrix:
  basic.md bytes=124 lines=7
  rich-preview.md bytes=5050 lines=246
  long-1mb.md bytes=328 lines=10
  large-5mb.md bytes=296 lines=8
  huge-table.md bytes=333 lines=9
  huge-code-block.md bytes=176 lines=11
  remote-image.md bytes=148 lines=5
  local-image.md bytes=142 lines=5
PASS: Android performance report audit completed.
```

## Supervisor Checklist Recommendation

The supervising session can use this report as fresh Android-lane evidence for
marking this L12 checklist item complete if not already reconciled:

- Capture Android performance report.

Use this report as minimum Android validation sanity evidence for:

- `./gradlew projects`.

Keep these L12 runtime/device checklist items open:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

Reason: no attached Android device or booted emulator was available; no Android
API 27 system image is installed; and this Android SDK does not include
`sdkmanager` or `avdmanager`, so this bounded batch could not provision an API
27 emulator locally.
