# Stage 1 Android L12 Device Boot Blocker - Batch 156

Date: 2026-05-10 05:01 CST

Worker scope: Android live lane, `android/**` only.

## Batch Selection

The authoritative blueprint and daily todo snapshot still leave Android L12
device-backed validation open. This bounded batch attempted to advance the
earliest Android-owned device validation item by booting the only local AVD,
then running connected instrumentation validation.

No Android product source changes were made. No `ios/**`, shared `Docs/**`, or
`.cron/**` files were edited.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-device-boot-blocker-batch156-20260510.md`

Gradle refreshed generated Android-local build outputs under ignored `build/`
directories while preparing connected test artifacts.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android`.

- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Explicit JDK used for Gradle commands:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
- Android SDK path:
  `/Users/wangweiyang/Library/Android/sdk`.
- Maven resolution used local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.
- Attached Android devices before the boot attempt: none.
- Available AVDs: `Medium_Phone`.
- `Medium_Phone` target: Android 36, ARM64, Google APIs Play Store 16 KB page
  size image.
- `Medium_Phone` configured RAM: `2048` MB.
- Host free disk space at validation time:
  `2.9Gi` available on `/System/Volumes/Data`.
- Existing `Medium_Phone.avd` directory size: `3.9G`.
- SDK command-line tools blocker remains: no executable
  `/Users/wangweiyang/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager`.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `adb devices -l` | BLOCKED for device validation | Printed only `List of devices attached`; no device rows. |
| `emulator -list-avds` | PARTIAL | Printed `Medium_Phone`. |
| `emulator -avd Medium_Phone -no-window -no-audio -no-boot-anim -gpu swiftshader_indirect` | BLOCKED | Emulator exited before boot with `FATAL | Your device does not have enough disk space to run avd: Medium_Phone`. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true projects` | PASS | `BUILD SUCCESSFUL in 13s`; project graph listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `bash tools/device_validation_preflight.sh` | BLOCKED | Reported 5 blockers: no attached device/emulator, no API 27 system image, no attached API 27 runtime, no attached low-memory/small-screen runtime, and no attached API 34+ runtime. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true :app:connectedDebugAndroidTest` | BLOCKED / FAIL | Debug app and androidTest APK preparation completed, then `:app:connectedDebugAndroidTest` failed with `DeviceException: No connected devices!`; `152 actionable tasks: 11 executed, 141 up-to-date`; `BUILD FAILED in 1m 7s`. |

Gradle printed its standard deprecation warning during the selected Gradle
commands:

```text
Deprecated Gradle features were used in this build, making it incompatible with Gradle 10.
```

This warning did not fail `projects`; the connected test command failed because
there was no booted Android runtime.

## AVD Boot Evidence

The attempted headless AVD launch reported:

```text
INFO         | Android emulator version 36.1.9.0 (build_id 13823996) (CL:N/A)
INFO         | Graphics backend: gfxstream
INFO         | Found systemPath /Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore_ps16k/arm64-v8a/
WARNING      | Please update the emulator to one that supports the feature(s): VulkanVirtualQueue
INFO         | Checking system compatibility:
INFO         |   Checking: hasSufficientDiskSpace
INFO         |      Error: Your device does not have enough disk space to run avd: `Medium_Phone`
INFO         |   Checking: hasSufficientHwGpu
INFO         |      Ok: Hardware GPU compatibility checks are not required
INFO         |   Checking: hasSufficientSystem
INFO         |      Ok: System requirements to run avd: `Medium_Phone` are met
FATAL        | Your device does not have enough disk space to run avd: `Medium_Phone`.
```

Disk evidence captured immediately after the failed launch:

```text
Filesystem        Size    Used   Avail Capacity Mounted on
/dev/disk3s1s1   926Gi    12Gi   2.9Gi    81%   /
/dev/disk3s5     926Gi   899Gi   2.9Gi   100%   /System/Volumes/Data
3.9G    /Users/wangweiyang/.android/avd/Medium_Phone.avd
```

The only local AVD cannot currently boot because the host lacks enough free
disk space for the emulator runtime.

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

Installed system images remain Android 36 only. No API 27 system image is
present, and `sdkmanager` is not installed at the expected command-line tools
path, so this bounded batch could not provision API 27 locally.

## Connected Test Evidence

`./gradlew :app:connectedDebugAndroidTest` reached test artifact preparation:

- `:app:packageDebug`
- `:app:compileDebugAndroidTestKotlin`
- `:app:packageDebugAndroidTest`
- `:app:connectedDebugAndroidTest`

Failure:

```text
Execution failed for task ':app:connectedDebugAndroidTest'.
> com.android.builder.testing.api.DeviceException: No connected devices!
```

## Supervisor Checklist Recommendation

Do not mark any new Android L12 device-backed checklist item complete from this
batch.

Keep these items open:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

Current blockers:

- No attached Android device is present.
- The only local AVD, `Medium_Phone`, fails to boot because the host has
  insufficient free disk space.
- No Android API 27 system image is installed.
- `sdkmanager` is missing, so the batch could not install missing API 27
  tooling or create a fresh API 27 emulator.

Use this report only as fresh blocker evidence and minimum Android host sanity
evidence for `./gradlew projects`.
