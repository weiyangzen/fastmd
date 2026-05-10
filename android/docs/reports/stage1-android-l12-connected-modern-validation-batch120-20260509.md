# Stage 1 Android L12 Connected Modern Validation Batch 120 - 2026-05-09

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
runtime validation cluster:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.
- Check Android API 27 validation readiness.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android product source changes were made. The only repository write in this
batch is this Android-local evidence report.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-connected-modern-validation-batch120-20260509.md`

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-09 / 2026-05-10 CST.

- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Explicit JDK:
  `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`.
- Android SDK path:
  `/Users/wangweiyang/Library/Android/sdk`.
- Maven resolution used local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.
- Booted emulator:
  `Medium_Phone`, ADB serial `emulator-5554`.

## Emulator Boot Evidence

The existing local AVD was booted headlessly:

```text
ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk \
ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk \
/Users/wangweiyang/Library/Android/sdk/emulator/emulator \
  -avd Medium_Phone \
  -no-snapshot \
  -no-boot-anim \
  -no-audio \
  -no-window \
  -gpu swiftshader_indirect \
  -netdelay none \
  -netspeed full
```

The emulator reported:

- `Boot completed in 20544 ms`.
- ADB device row:
  `emulator-5554 device product:sdk_gphone16k_arm64 model:sdk_gphone16k_arm64 device:emu64a16k`.

Runtime properties collected after boot:

- API level: `36`.
- Model: `sdk_gphone16k_arm64`.
- ABI: `arm64-v8a`.
- Physical size: `1080x2400`.
- Physical density: `420`.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true projects` | PASS | Project graph listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; Gradle reported `BUILD SUCCESSFUL in 14s`. |
| `ANDROID_HOME=... ANDROID_SDK_ROOT=... adb devices -l` before emulator boot | BLOCKED for runtime work | Printed `List of devices attached` with no attached device rows. |
| `ANDROID_HOME=... ANDROID_SDK_ROOT=... emulator -list-avds` | PASS | Listed one AVD: `Medium_Phone`. |
| `find /Users/wangweiyang/Library/Android/sdk/system-images -maxdepth 4 -type d` | BLOCKED for API 27 validation | Installed system images are Android 36 only; no `android-27` image is installed. |
| `ANDROID_HOME=... ANDROID_SDK_ROOT=... adb shell getprop sys.boot_completed` after boot | PASS | Returned `1` for the booted emulator. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true :app:connectedDebugAndroidTest --stacktrace` | PASS | Ran 3 instrumentation tests on `Medium_Phone(AVD) - 16`; Gradle reported `BUILD SUCCESSFUL in 31s`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... bash tools/device_validation_preflight.sh` | PARTIAL / BLOCKED | Found `emulator-5554` API 36 with `memMb=1999`; passed attached-device, low-memory, and API 34+ readiness checks; blocked on missing API 27 system image and no attached API 27 target. |

## Connected Test Coverage

The connected Android test run executed the Android document-entry intent smoke
suite:

- `com.fastmd.mobile.MainActivityIntentContractTest.markdownViewIntentResolvesToExportedMainActivity`
- `com.fastmd.mobile.MainActivityIntentContractTest.sharedTextIntentResolvesToExportedMainActivity`
- `com.fastmd.mobile.MainActivityIntentContractTest.launcherIntentResolvesToExportedMainActivity`

The generated JUnit XML recorded:

```text
tests="3" failures="0" errors="0" skipped="0"
device="Medium_Phone(AVD) - 16"
project=":app"
```

The UTP textproto recorded `test_status: PASSED` for all three test cases on
device id `emulator-5554`.

## Android-Local Evidence Artifacts

Connected Android test result artifacts:

- `android/app/build/outputs/androidTest-results/connected/debug/TEST-Medium_Phone(AVD) - 16-_app-.xml`
- `android/app/build/outputs/androidTest-results/connected/debug/Medium_Phone(AVD) - 16/test-result.textproto`
- `android/app/build/outputs/androidTest-results/connected/debug/Medium_Phone(AVD) - 16/testlog/test-results.log`
- `android/app/build/outputs/androidTest-results/connected/debug/Medium_Phone(AVD) - 16/device-info.pb`
- `android/app/build/outputs/androidTest-results/connected/debug/Medium_Phone(AVD) - 16/meminfo`
- `android/app/build/outputs/androidTest-results/connected/debug/Medium_Phone(AVD) - 16/cpuinfo`
- `android/app/build/reports/androidTests/connected/debug/index.html`
- `android/app/build/reports/androidTests/connected/debug/com.fastmd.mobile.MainActivityIntentContractTest.html`

Relevant APK artifacts:

- `android/app/build/outputs/apk/debug/app-debug.apk`
- `android/app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk`

## Device Matrix Findings

- `:app:connectedDebugAndroidTest` is now validated on the booted modern
  Android emulator.
- Modern-device validation has Android-local smoke evidence because the attached
  emulator is API 36, satisfying the project preflight's API 34+ readiness check.
- Low-memory/small-screen readiness has Android-local smoke evidence under the
  existing preflight definition because the attached emulator reported
  `memMb=1999`, which is at or below the preflight threshold of `2048`.
- Android API 27 validation remains blocked. No `android-27` SDK system image is
  installed and no attached API 27 device/emulator is available.

This batch did not perform a full reader workflow, API 27 runtime run, or
release-like performance timing run.

## Supervisor Checklist Recommendation

The supervising session can use this report as Android-lane evidence for
marking these L12 checklist items complete:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android modern device validation.

The supervisor can consider this report as evidence for the low-memory portion
of:

- Run Android low-memory/small-screen profile validation.

Reason: `tools/device_validation_preflight.sh` passed its attached low-memory
readiness check for `emulator-5554` with `memMb=1999`. Keep it open if the
intended interpretation requires an explicitly small-screen or watch-class AVD,
because this AVD is a `1080x2400` phone-sized profile.

Keep this L12 item open:

- Run Android API 27 validation.

Reason: no API 27 system image or attached API 27 runtime is available locally.
