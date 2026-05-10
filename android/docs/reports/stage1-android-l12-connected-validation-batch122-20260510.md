# Stage 1 Android L12 Connected Validation Batch 122 - 2026-05-10

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
runtime validation items from the authoritative blueprint:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Refresh modern Android runtime validation evidence.
- Refresh low-memory runtime readiness evidence.
- Re-check Android API 27 runtime blocker state.
- Run minimum Gradle project sanity evidence with `./gradlew projects`.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android product source changes were made. The only repository write in this
batch is this Android-local evidence report.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-connected-validation-batch122-20260510.md`

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-10.

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

Boot/runtime properties collected after `sys.boot_completed=1`:

```text
sys.boot_completed=1
ro.build.version.sdk=36
ro.product.model=sdk_gphone16k_arm64
wm size=Physical size: 1080x2400
wm density=Physical density: 420
MemTotal:        2047232 kB
```

ADB device row after boot:

```text
emulator-5554 device product:sdk_gphone16k_arm64 model:sdk_gphone16k_arm64 device:emu64a16k transport_id:2
```

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true projects` | PASS | Project graph listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; Gradle reported `BUILD SUCCESSFUL in 13s`. |
| `ANDROID_HOME=... ANDROID_SDK_ROOT=... adb wait-for-device shell ... getprop sys.boot_completed ...` | PASS | Booted emulator returned `sys.boot_completed=1`; device is API 36, model `sdk_gphone16k_arm64`, size `1080x2400`, density `420`, and `MemTotal` about 2 GB. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true :app:connectedDebugAndroidTest --stacktrace` | PASS | Ran 3 instrumentation tests on `Medium_Phone(AVD) - 16`; Gradle reported `BUILD SUCCESSFUL in 45s`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... bash tools/device_validation_preflight.sh` | PARTIAL / BLOCKED | Found one attached emulator, `emulator-5554`, API 36, `memMb=1999`; passed attached-device, low-memory readiness, and API 34+ modern readiness checks; blocked on missing API 27 system image and no attached API 27 target. |
| `find /Users/wangweiyang/Library/Android/sdk/system-images -maxdepth 4 -type d` | BLOCKED for API 27 validation | Installed system images are Android 36 only; no `android-27` image is installed. |

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

Gradle also refreshed:

- `android/build/reports/problems/problems-report.html`

## Device Matrix Findings

- `:app:connectedDebugAndroidTest` is validated on a booted Android emulator.
- Modern-device validation has current Android-local smoke evidence because the
  attached emulator is API 36, satisfying the project preflight's API 34+
  readiness check.
- Low-memory readiness has current Android-local smoke evidence under the
  existing preflight definition because the attached emulator reported
  `memMb=1999`, at or below the preflight threshold of `2048`.
- Small-screen/watch-class validation is not fully proven by this AVD because
  the runtime screen is `1080x2400`.
- Android API 27 validation remains blocked. No `android-27` SDK system image is
  installed and no attached API 27 device/emulator is available.

This batch did not perform a full reader workflow, API 27 runtime run, or
release-like performance timing run.

## Supervisor Checklist Recommendation

The supervising session can use this report as fresh Android-lane evidence for
marking these L12 checklist items complete if not already reconciled:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android modern device validation.

The supervisor can consider this report as evidence for the low-memory portion
of:

- Run Android low-memory/small-screen profile validation.

Keep it open if the intended interpretation requires an explicitly small-screen
or watch-class AVD, because this AVD is a `1080x2400` phone-sized profile.

Keep this L12 item open:

- Run Android API 27 validation.

Reason: no API 27 system image or attached API 27 runtime is available locally.
