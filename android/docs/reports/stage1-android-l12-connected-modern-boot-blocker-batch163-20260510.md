# Stage 1 Android L12 Connected Modern Boot Blocker - Batch 163

Date: 2026-05-10 CST

Worker scope: Android live lane, `android/**` only.

## Batch Selection

The authoritative blueprint and daily todo snapshot still show Android L12
platform validation as the remaining Android-owned work. Recent Android-local
reports already provide host-side evidence for lint, build, unit tests,
assemble, and source-level performance capture. This bounded batch therefore
targeted the next runtime-backed Android L12 path that could be advanced with
the local SDK: boot the available `Medium_Phone` AVD and run
`:app:connectedDebugAndroidTest` as modern-device validation evidence.

No Android product source changes were required. No `ios/**`, shared `Docs/**`,
or `.cron/**` files were edited.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-connected-modern-boot-blocker-batch163-20260510.md`

Gradle also read/refreshed generated Android-local build outputs under ignored
`build/` directories while preparing connected-test artifacts.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android`.

- Time captured during validation: `2026-05-10 06:29:57 CST +0800`.
- Explicit JDK used for Gradle commands:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
- Explicit Java version: OpenJDK `17.0.17`
  (`Homebrew 17.0.17+0`).
- Android SDK path:
  `/Users/wangweiyang/Library/Android/sdk`.
- Maven resolution used Android-local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.
- SDK command binaries present:
  `/Users/wangweiyang/Library/Android/sdk/platform-tools/adb` and
  `/Users/wangweiyang/Library/Android/sdk/emulator/emulator`.
- SDK command binaries missing:
  `sdkmanager` and `avdmanager`.
- Attached Android devices before validation: none.
- Available AVD: `Medium_Phone`.

The available AVD is a modern Android profile only:

```text
AvdId = Medium_Phone
target = android-36
image.sysdir.1 = system-images/android-36/google_apis_playstore_ps16k/arm64-v8a/
hw.ramSize = 2048
hw.lcd.width = 1080
hw.lcd.height = 2400
hw.lcd.density = 420
tag.display = 16 KB Page Size
```

Installed SDK platforms and images:

```text
/Users/wangweiyang/Library/Android/sdk/platforms/android-31
/Users/wangweiyang/Library/Android/sdk/platforms/android-32
/Users/wangweiyang/Library/Android/sdk/platforms/android-33
/Users/wangweiyang/Library/Android/sdk/platforms/android-34
/Users/wangweiyang/Library/Android/sdk/platforms/android-35
/Users/wangweiyang/Library/Android/sdk/platforms/android-36
/Users/wangweiyang/Library/Android/sdk/system-images/android-36
```

No Android API 27 platform or API 27 system image is installed.

## Validation Results

Passing Gradle commands used this environment prefix:

```bash
JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home \
ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk \
ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk \
./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true ...
```

| Command | Result | Evidence |
| --- | --- | --- |
| `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported OpenJDK `17.0.17`. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true projects` | PASS | Root project `fastmd-android` listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 13s`. |
| `emulator -list-avds` | PARTIAL | Listed one AVD: `Medium_Phone`. |
| `adb devices -l` | BLOCKED for connected validation | Printed only `List of devices attached`; no device rows. |
| `emulator -avd Medium_Phone -no-window -no-audio -no-boot-anim -gpu swiftshader_indirect -wipe-data` | BLOCKED | Emulator exited before boot: not enough space to create the userdata partition. Available: `5674.304688 MB`; required: `7372.800000 MB`. |
| `df -h ~/.android/avd/Medium_Phone.avd` | BLOCKED context | `/System/Volumes/Data` had `5.1Gi` available and was at `100%` capacity. |
| `bash tools/device_validation_preflight.sh` | BLOCKED | Reported 5 blockers: no attached runtime, no API 27 system image, no attached API 27 runtime, no low-memory/small-screen runtime, and no attached API 34+ runtime. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true :app:connectedDebugAndroidTest` | BLOCKED / FAIL | Debug app and androidTest APK tasks completed or were up to date, then `:app:connectedDebugAndroidTest` failed with `DeviceException: No connected devices!`; `BUILD FAILED in 21s`; `152 actionable tasks: 6 executed, 146 up-to-date`. |

Gradle printed its standard deprecation warning:

```text
Deprecated Gradle features were used in this build, making it incompatible with Gradle 10.
```

This warning did not affect project-graph validation. The connected test command
failed because no device or booted emulator was available.

## Emulator Boot Evidence

The modern `Medium_Phone` emulator was the only locally available runtime
candidate. It failed before Android boot completed:

```text
INFO         | Android emulator version 36.1.9.0 (build_id 13823996) (CL:N/A)
INFO         | Found systemPath /Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore_ps16k/arm64-v8a/
ERROR        | Not enough space to create userdata partition. Available: 5674.304688 MB at /Users/wangweiyang/.android/avd/../avd/Medium_Phone.avd, need 7372.800000 MB.
```

After the failed boot attempt, no emulator, qemu, or `adb wait-for-device`
process was left running.

## Device Preflight Evidence

`tools/device_validation_preflight.sh` reported:

```text
BLOCKED: No attached Android device or booted emulator is available for connectedDebugAndroidTest.
BLOCKED: No Android API 27 system image is installed under /Users/wangweiyang/Library/Android/sdk/system-images.
BLOCKED: No attached API 27 device/emulator is ready for Android 8.1 validation.
BLOCKED: No attached low-memory device/emulator was detected for low-memory/small-screen validation.
BLOCKED: No attached API 34+ device/emulator is ready for modern-device validation.
BLOCKED: Android device validation preflight found 5 blocker(s).
```

## Connected Test Evidence

The connected test Gradle task reached app and androidTest artifact preparation
before failing at device execution:

```text
> Task :app:packageDebug UP-TO-DATE
> Task :app:packageDebugAndroidTest UP-TO-DATE
> Task :app:connectedDebugAndroidTest FAILED

Execution failed for task ':app:connectedDebugAndroidTest'.
> com.android.builder.testing.api.DeviceException: No connected devices!

BUILD FAILED in 21s
152 actionable tasks: 6 executed, 146 up-to-date
```

Existing generated APK artifacts are present:

```text
app/build/outputs/apk/debug/app-debug.apk                       9.3M
app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk 945K
```

## Open Runtime Validation Blockers

Keep these Android L12 checklist items open:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

Current blockers:

- No Android device is attached.
- The only local AVD, `Medium_Phone`, cannot boot because the local volume has
  insufficient free space for its userdata partition.
- No API 27 platform or API 27 system image is installed.
- `sdkmanager` and `avdmanager` are absent, so this bounded batch could not
  provision missing API 27 tooling or a smaller runtime profile.

## Checklist Evidence For Supervisor

This batch provides fresh blocker evidence, not completion evidence, for the
runtime-backed Android L12 items listed above.

The supervising session can use the `./gradlew projects` result in this report
as current minimum Android Gradle sanity evidence. It should not mark the
connected, API 27, low-memory/small-screen, or modern-device validation items
complete from this batch.
