# Stage 1 Android L12 Small-Screen Validation Batch 124 - 2026-05-10

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
runtime validation item that could be advanced on the local machine:

- Run Android low-memory/small-screen profile validation.
- Refresh minimum Gradle project sanity evidence with `./gradlew projects`.
- Refresh connected instrumentation smoke evidence on the constrained runtime.
- Re-check Android API 27 availability and keep that checklist item open if the
  runtime is still unavailable.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android product source changes were made. The only repository write in this
batch is this Android-local evidence report.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-small-screen-validation-batch124-20260510.md`

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

Before booting the AVD, `adb devices -l` listed no attached devices. The only
available AVD was `Medium_Phone`.

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
boot_completed=1
emulator-5554 device product:sdk_gphone16k_arm64 model:sdk_gphone16k_arm64 device:emu64a16k transport_id:3
ro.build.version.sdk=36
ro.product.model=sdk_gphone16k_arm64
wm size=Physical size: 1080x2400
wm density=Physical density: 420
MemTotal:        2047232 kB
```

## Small-Screen Runtime Constraint

The emulator display was temporarily constrained before the connected test run:

```text
adb shell wm size 320x320
adb shell wm density 220
adb shell wm size
Physical size: 1080x2400
Override size: 320x320
adb shell wm density
Physical density: 420
Override density: 220
```

The same constrained runtime reported:

```text
ro.build.version.sdk=36
ro.product.model=sdk_gphone16k_arm64
MemTotal:        2047232 kB
```

`2047232 kB` is about `1999 MB`, which satisfies the Android preflight's
low-memory threshold of `<= 2048 MB`.

After validation, the display override was restored:

```text
adb shell wm size reset
adb shell wm density reset
adb shell wm size
Physical size: 1080x2400
adb shell wm density
Physical density: 420
```

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true projects` | PASS | Project graph listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; Gradle reported `BUILD SUCCESSFUL in 19s`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... bash tools/device_validation_preflight.sh` | PARTIAL / BLOCKED | Found one attached emulator, `emulator-5554`, API 36, `memMb=1999`; passed attached-device, low-memory readiness, and API 34+ modern readiness checks; blocked on missing API 27 system image and no attached API 27 target. The script prints physical display size, so direct `adb shell wm size` evidence above is the source of truth for the temporary 320x320 small-screen override. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true :app:connectedDebugAndroidTest --stacktrace` | PASS | Ran 3 instrumentation tests on `Medium_Phone(AVD) - 16` while the runtime had the 320x320 display override; Gradle reported `BUILD SUCCESSFUL in 31s`. |
| `find /Users/wangweiyang/Library/Android/sdk/system-images -maxdepth 4 -type d` | BLOCKED for API 27 validation | Installed system images are Android 36 only; no `android-27` image is installed. |

Gradle printed its standard deprecation warning:

- Deprecated Gradle features were used in this build, making it incompatible
  with Gradle 10.

This warning did not fail the validation command.

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

Connected Android test result artifacts refreshed by this batch:

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

- Low-memory/small-screen runtime validation has current Android-local smoke
  evidence: the emulator reported about 2 GB RAM and the connected test run was
  performed under an explicit `320x320` display override.
- Modern-device readiness remains supported by this run because the attached
  runtime is API 36 and the preflight passed its API 34+ readiness check.
- This batch does not prove watch hardware behavior or full reader workflow
  behavior; it is a bounded connected smoke validation on a constrained AVD.
- Android API 27 validation remains blocked. No `android-27` SDK system image is
  installed and no attached API 27 device/emulator is available.

## Supervisor Checklist Recommendation

The supervising session can use this report as fresh Android-lane evidence for
marking this L12 checklist item complete if the acceptance threshold is a
constrained low-memory/small-screen emulator smoke:

- Run Android low-memory/small-screen profile validation.

This report also refreshes supporting evidence for:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android modern device validation.
- Minimum Android Gradle sanity with `./gradlew projects`.

Keep this L12 item open:

- Run Android API 27 validation.

Reason: no API 27 system image or attached API 27 runtime is available locally.
