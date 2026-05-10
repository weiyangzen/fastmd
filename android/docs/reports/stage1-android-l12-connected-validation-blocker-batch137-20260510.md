# Stage 1 Android L12 Connected Validation Blocker Batch 137 - 2026-05-10

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
runtime validation cluster from `Docs/Stage1_Mobile_Blueprint.md` and
`Docs/todos_20260506.md`:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android product source changes were made. The only intentional repository
write in this batch is this Android-local evidence report.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-connected-validation-blocker-batch137-20260510.md`

Gradle also refreshed generated Android-local build metadata under
`android/build/`, `android/app/build/`, and module `build/` directories while
preparing the connected test APKs.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-10 at approximately 02:37 CST.

- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Android SDK path: `/Users/wangweiyang/Library/Android/sdk`.
- Explicit JDK used for Gradle commands:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
- Explicit Java version:
  `openjdk version "17.0.17" 2025-10-21`.
- Maven resolution used local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported Homebrew OpenJDK `17.0.17`. |
| `ANDROID_HOME=... ANDROID_SDK_ROOT=... adb devices -l` | BLOCKED | Printed only `List of devices attached`; no connected device or booted emulator rows were present. |
| `find /Users/wangweiyang/Library/Android/sdk -type f \( -name emulator -o -name adb -o -name sdkmanager -o -name avdmanager \)` | PARTIAL | Found `emulator` and `adb`; no `sdkmanager` or `avdmanager` binary was present for local API 27 provisioning. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true projects` | PASS | Project graph listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; Gradle reported `BUILD SUCCESSFUL in 14s`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... bash tools/device_validation_preflight.sh` | BLOCKED | Reported 5 blockers: no attached runtime, no API 27 system image, no attached API 27 runtime, no low-memory runtime, and no API 34+ runtime. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true :app:connectedDebugAndroidTest` | BLOCKED / FAIL | Gradle prepared app and androidTest APK tasks, then `:app:connectedDebugAndroidTest` failed with `com.android.builder.testing.api.DeviceException: No connected devices!`; Gradle reported `BUILD FAILED in 20s`. |

Gradle printed its standard deprecation warning:

```text
Deprecated Gradle features were used in this build, making it incompatible with Gradle 10.
```

That warning did not block project graph resolution. The connected test command
failed because no Android runtime was connected.

## Device Preflight Evidence

`tools/device_validation_preflight.sh` printed:

```text
== ADB Devices ==
List of devices attached

BLOCKED: No attached Android device or booted emulator is available for connectedDebugAndroidTest.
```

Installed system images are Android 36 only:

```text
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis/arm64-v8a
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore/arm64-v8a
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore_ps16k/arm64-v8a
```

The preflight also listed one AVD:

```text
Medium_Phone
```

Checklist readiness from the same preflight:

```text
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
BUILD FAILED in 20s
152 actionable tasks: 6 executed, 146 up-to-date
```

## Supervisor Checklist Recommendation

Use this report as fresh Android-lane evidence that the connected/device L12
cluster was attempted in this environment.

Keep these Android L12 checklist items open:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

Reason: no attached Android device or booted emulator was available; no API 27
system image is installed; and the local SDK lacks `sdkmanager`/`avdmanager`
binaries needed for local API 27 provisioning in this bounded batch.

Do not mark runtime validation complete from this report alone. A future batch
needs a visible attached runtime or booted emulator in `adb devices -l`, plus an
API 27 runtime for the Android 8.1 checklist item.
