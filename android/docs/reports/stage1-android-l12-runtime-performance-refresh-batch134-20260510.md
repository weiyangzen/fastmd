# Stage 1 Android L12 Runtime Performance Refresh Batch 134 - 2026-05-10

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
runtime/performance validation work that could be advanced without touching iOS
or shared Docs:

- Re-check Android API 27 availability.
- Attempt connected modern-runtime validation on the only local AVD,
  `Medium_Phone`.
- Run minimum Gradle project sanity.
- Refresh the Android performance report audit.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android product source changes were made. The only intentional repository
write in this batch is this Android-local evidence report.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-runtime-performance-refresh-batch134-20260510.md`

Gradle also refreshed generated Android-local build artifacts under
`android/build/`, `android/app/build/`, and module `build/` directories.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-10.

- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Explicit JDK used for Gradle commands:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
- Explicit Java version:
  `openjdk version "17.0.17" 2025-10-21`.
- Android Studio bundled JBR also exists:
  `/Applications/Android Studio.app/Contents/jbr/Contents/Home`, OpenJDK
  `21.0.6`.
- Android SDK path:
  `/Users/wangweiyang/Library/Android/sdk`.
- Maven resolution used local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.

## Device / Emulator Findings

Initial ADB state:

```text
List of devices attached
```

Available local AVDs:

```text
Medium_Phone
```

Installed system images:

```text
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis/arm64-v8a
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore/arm64-v8a
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore_ps16k/arm64-v8a
```

No Android API 27 system image is installed. No `sdkmanager` or `avdmanager`
binary was found under the local Android SDK path, so this batch could not
install or create an API 27 AVD locally.

The existing `Medium_Phone` AVD was attempted twice:

1. Snapshot boot with `-no-snapshot-save`.
2. Clean boot with `-no-snapshot-load -no-snapshot-save`.

Both attempts started the emulator process and logged Android emulator
`36.1.9.0` with the Android 36 Play Store PS16K ARM64 image, but neither attempt
registered a device row in `adb devices -l` within the bounded boot window. The
retry log ended its useful startup evidence with:

```text
USER_INFO | Emulator is performing a full startup. This may take upto two minutes, or more.
```

After stopping the emulator/wait processes and restarting ADB, final ADB state
was still:

```text
List of devices attached
```

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported Homebrew OpenJDK `17.0.17`. |
| `/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/java -version` | PASS | Reported Android Studio JBR OpenJDK `21.0.6`. |
| `ANDROID_HOME=... ANDROID_SDK_ROOT=... adb devices -l` | BLOCKED for runtime validation | Printed `List of devices attached` with no device rows before and after emulator attempts. |
| `ANDROID_HOME=... ANDROID_SDK_ROOT=... emulator -list-avds` | PARTIAL | Listed one AVD: `Medium_Phone`. |
| `find $ANDROID_SDK_ROOT/system-images -maxdepth 4 -type d` | BLOCKED for API 27 validation | Installed system images are Android 36 only; no `android-27` image exists. |
| `find $ANDROID_SDK_ROOT -type f \( -name sdkmanager -o -name avdmanager \)` | BLOCKED for local API 27 AVD creation | No `sdkmanager` or `avdmanager` binary was found. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true projects` | PASS | Project graph listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; Gradle reported `BUILD SUCCESSFUL in 13s`. |
| `bash tools/audit_performance_report.sh` | PASS | Source-level Android performance posture audit completed and reported `PASS: Android performance report audit completed.` |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... bash tools/device_validation_preflight.sh` | BLOCKED | No attached device/emulator, no API 27 system image, no attached API 27 runtime, no attached low-memory runtime, and no attached API 34+ runtime. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true :app:connectedDebugAndroidTest` | BLOCKED / FAIL | Gradle built the app and test APKs, then `:app:connectedDebugAndroidTest` failed with `DeviceException: No connected devices!`. |

Gradle printed its standard deprecation warning:

```text
Deprecated Gradle features were used in this build, making it incompatible with Gradle 10.
```

This warning did not fail the `projects` command. The connected test command
failed only because no Android runtime was connected.

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

The supervising session can use this report as fresh Android-lane evidence for
marking this L12 checklist item complete if not already reconciled:

- Capture Android performance report.

Use this report as minimum Android validation sanity evidence for:

- `./gradlew projects`.

Keep these L12 runtime/device items open for this batch:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

Reason: no attached Android device or booted emulator was available at the end
of the batch; the only local AVD did not become visible to ADB during two
bounded headless boot attempts; API 27 validation is still blocked by missing
`android-27` system image and missing SDK manager tools for local provisioning.
