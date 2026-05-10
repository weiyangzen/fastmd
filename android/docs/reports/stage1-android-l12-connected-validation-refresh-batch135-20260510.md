# Stage 1 Android L12 Connected Validation Refresh Batch 135 - 2026-05-10

## Scope

Android live-lane bounded batch for the next still-open Android-owned L12
runtime validation item from `Docs/Stage1_Mobile_Blueprint.md` and
`Docs/todos_20260506.md`:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android product source changes were made. The only intentional repository
write in this batch is this Android-local evidence report.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-connected-validation-refresh-batch135-20260510.md`

Gradle also refreshed generated Android-local build artifacts under
`android/build/`, `android/app/build/`, and module `build/` directories.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-10.

- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Android SDK path:
  `/Users/wangweiyang/Library/Android/sdk`.
- Explicit JDK used for Gradle commands:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
- Explicit Java version:
  `openjdk version "17.0.17" 2025-10-21`.
- Maven resolution used local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.

The default shell still does not expose Java:

```text
java -version
The operation couldn't be completed. Unable to locate a Java Runtime.
Please visit http://www.java.com for information on installing Java.
```

The checked-in Gradle wrapper works when `JAVA_HOME` and `PATH` are scoped to
the explicit Homebrew OpenJDK 17 path above.

## Device / Emulator Findings

ADB state before connected validation:

```text
List of devices attached
```

Available local AVDs:

```text
Medium_Phone
```

Installed Android SDK system images:

```text
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis/arm64-v8a
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore/arm64-v8a
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore_ps16k/arm64-v8a
```

No Android API 27 system image is installed. No `sdkmanager` or `avdmanager`
binary was found under the local Android SDK path, so this batch could not
provision an API 27 AVD locally.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED for default shell | macOS reported `Unable to locate a Java Runtime`. |
| `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported Homebrew OpenJDK `17.0.17`. |
| `ANDROID_HOME=... ANDROID_SDK_ROOT=... adb devices -l` | BLOCKED for runtime validation | Printed only `List of devices attached`, with no device rows. |
| `ANDROID_HOME=... ANDROID_SDK_ROOT=... emulator -list-avds` | PARTIAL | Listed one AVD: `Medium_Phone`. |
| `find $ANDROID_SDK_ROOT/system-images -maxdepth 4 -type d` | BLOCKED for API 27 validation | Installed images are Android 36 only; no `android-27` image exists. |
| `find $ANDROID_SDK_ROOT -maxdepth 3 -type f \( -name adb -o -name emulator -o -name sdkmanager -o -name avdmanager \)` | BLOCKED for local AVD provisioning | Found `adb` and `emulator`; no `sdkmanager` or `avdmanager`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true projects` | PASS | Project graph listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; Gradle reported `BUILD SUCCESSFUL in 22s`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... bash tools/device_validation_preflight.sh` | BLOCKED | No attached device/emulator, no API 27 system image, no attached API 27 runtime, no attached low-memory runtime, and no attached API 34+ runtime. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true :app:connectedDebugAndroidTest` | BLOCKED / FAIL | Gradle built the app and instrumentation APKs, then `:app:connectedDebugAndroidTest` failed with `DeviceException: No connected devices!`. |

Gradle printed its standard deprecation warning:

```text
Deprecated Gradle features were used in this build, making it incompatible with Gradle 10.
```

This warning did not fail the `projects` command. The connected test command
failed only because no Android runtime was connected.

## Connected Test Task Evidence

The connected test attempt reached task execution and produced debug app and
instrumentation test APK packaging work before failing at device discovery:

```text
> Task :app:packageDebug UP-TO-DATE
> Task :app:packageDebugAndroidTest UP-TO-DATE
> Task :app:connectedDebugAndroidTest FAILED

Execution failed for task ':app:connectedDebugAndroidTest'.
> com.android.builder.testing.api.DeviceException: No connected devices!

BUILD FAILED in 28s
152 actionable tasks: 6 executed, 146 up-to-date
```

Representative generated Android-local artifacts present for the connected
test attempt:

- `android/app/build/outputs/apk/debug/app-debug.apk`
- `android/app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk`
- `android/build/reports/problems/problems-report.html`

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

## Supervisor Checklist Recommendation

Do not mark this L12 checklist item complete from this batch:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.

Reason: the Gradle task was executed, and app/test APK preparation succeeded,
but the validation could not run on-device because no attached Android device
or booted emulator was available.

Use this report as fresh Android-lane blocker evidence for:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

Use this report as minimum Android validation sanity evidence for:

- `./gradlew projects`.

Keep the runtime/device validation checklist items open until a matching
attached device or booted emulator is available. Android API 27 validation also
requires an API 27 device/emulator or local SDK manager tools plus an API 27
system image.
