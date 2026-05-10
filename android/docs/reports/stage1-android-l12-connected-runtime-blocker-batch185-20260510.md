# Stage 1 Android L12 Connected Runtime Blocker - Batch 185

Date: 2026-05-10 09:59 CST

Worker scope: Android live lane, `android/**` only.

## Batch Selection

The authoritative blueprint and daily todo snapshot leave Android L12 platform
validation as the earliest Android-owned open cluster. Existing Android-local
reports already provide host-side Gradle and source-level performance evidence,
so this bounded batch targeted the next still-open Android runtime item:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.

No Android product source changes were required. This batch did not edit
`ios/**`, shared `Docs/**`, or `.cron/**`.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-connected-runtime-blocker-batch185-20260510.md`

Gradle also refreshed generated Android-local build metadata and APK outputs
under ignored `build/` directories while preparing the connected test task.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android`.

- Gradle entry point: checked-in wrapper `./gradlew`.
- Android SDK path: `/Users/wangweiyang/Library/Android/sdk`.
- Explicit JDK used for Gradle commands:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
- Explicit Java version: OpenJDK `17.0.17`.
- Maven resolution opt-in used for Gradle commands:
  `-Pfastmd.useChinaMavenMirror=true`.
- Attached Android devices at validation time: none.
- Available AVD: `Medium_Phone`.
- `Medium_Phone` target: Android 36, arm64-v8a, 2048 MB RAM.
- Installed SDK platforms: API 31, 32, 33, 34, 35, and 36.
- Installed SDK system images: Android 36 only.
- SDK command-line tools status: no `sdkmanager` or `avdmanager` binary found
  under `/Users/wangweiyang/Library/Android/sdk/cmdline-tools`.

Passing Gradle commands used this scoped environment:

```bash
JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
PATH=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin:$PATH
ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk
ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk
```

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `date '+%Y-%m-%d %H:%M:%S %Z %z'` | PASS | Printed `2026-05-10 09:59:18 CST +0800`. |
| `java -version` with explicit JDK 17 env | PASS | Reported OpenJDK `17.0.17`. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true projects` with explicit JDK 17 and SDK env | PASS | `BUILD SUCCESSFUL in 14s`; module graph listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `adb devices -l` | BLOCKED | Printed only `List of devices attached`; no device rows. |
| `emulator -list-avds` through explicit SDK path | PARTIAL | Listed `Medium_Phone`. |
| `sed -n '1,220p' ~/.android/avd/Medium_Phone.avd/config.ini` | PARTIAL | AVD is Android 36, arm64-v8a, 2048 MB RAM, `image.sysdir.1=system-images/android-36/google_apis_playstore_ps16k/arm64-v8a/`. |
| `df -h ~/.android/avd/Medium_Phone.avd ~/Library/Android/sdk` | BLOCKED for emulator boot | Filesystem reported `926Gi` size, `900Gi` used, `2.4Gi` available, `100%` capacity. |
| `emulator -avd Medium_Phone -no-window -no-audio -no-boot-anim -gpu swiftshader_indirect -no-snapshot -wipe-data` | BLOCKED / FAIL | Emulator exited before boot: `Not enough space to create userdata partition. Available: 2642.609375 MB ... need 7372.800000 MB.` |
| `bash tools/device_validation_preflight.sh` with SDK env | BLOCKED | Reported 5 blockers: no attached device/emulator, no API 27 system image, no attached API 27 target, no low-memory/small-screen target, and no attached API 34+ modern target. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true :app:connectedDebugAndroidTest` with explicit JDK 17 and SDK env | BLOCKED / FAIL | Debug app and androidTest APK preparation completed, then `:app:connectedDebugAndroidTest` failed with `DeviceException: No connected devices!`; `BUILD FAILED in 23s`; `152 actionable tasks: 6 executed, 146 up-to-date`. |

Gradle printed its standard non-failing deprecation warning about future Gradle
10 compatibility during wrapper-backed commands.

## Connected Test Preparation Evidence

The connected test task could build or reuse the required APK artifacts before
failing at the device boundary:

- `android/app/build/outputs/apk/debug/app-debug.apk` (`9.3M`)
- `android/app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk`
  (`945K`)

The failure is environmental, not an instrumentation compile/package failure:

```text
Execution failed for task ':app:connectedDebugAndroidTest'.
> com.android.builder.testing.api.DeviceException: No connected devices!
```

## Current Runtime Validation Blockers

Keep these Android L12 checklist items open until a device-backed report covers
them:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

Current blockers:

- No Android device or booted emulator is attached.
- The only listed AVD, `Medium_Phone`, cannot currently boot because the host
  data volume has only about 2.4 GiB available and the emulator needs about
  7.2 GiB for its userdata partition.
- No Android API 27 platform is installed under
  `/Users/wangweiyang/Library/Android/sdk/platforms`.
- No Android API 27 system image is installed under
  `/Users/wangweiyang/Library/Android/sdk/system-images`.
- No SDK `sdkmanager` or `avdmanager` binary was found under
  `/Users/wangweiyang/Library/Android/sdk/cmdline-tools`, so this batch could
  not install missing API 27 tooling or create a matching API 27 emulator.
- No attached API 27, low-memory/small-screen, or API 34+ modern runtime was
  available during this batch.

## Supervisor Checklist Recommendation

Do not mark new Android runtime validation checklist items complete from this
batch. This report is blocker evidence for keeping the following L12 items open:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

Earlier Android-local reports remain the evidence source for already-passing
host-side Gradle and source-level performance items.
