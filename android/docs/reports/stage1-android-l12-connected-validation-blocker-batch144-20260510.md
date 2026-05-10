# Stage 1 Android L12 Connected Validation Blocker Batch 144 - 2026-05-10

## Scope

Android live-lane bounded batch for the next still-open Android-owned L12
validation item in `Docs/Stage1_Mobile_Blueprint.md` and
`Docs/todos_20260506.md`:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android product source changes were required. The only intentional repository
write in this batch is this Android-local evidence report.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-connected-validation-blocker-batch144-20260510.md`

Gradle also refreshed generated Android-local build metadata under ignored
`build/` directories while preparing the connected test artifacts.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-10.

- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Android SDK path:
  `/Users/wangweiyang/Library/Android/sdk`.
- Explicit JDK used for Gradle validation:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
- Explicit Java version:
  `openjdk version "17.0.17" 2025-10-21`.
- Maven resolution used local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.
- ADB path:
  `/Users/wangweiyang/Library/Android/sdk/platform-tools/adb`.
- Available AVD:
  `Medium_Phone`.

The default shell still does not expose Java:

```text
./gradlew --version --console=plain --no-daemon
The operation couldn't be completed. Unable to locate a Java Runtime.
Please visit http://www.java.com for information on installing Java.
```

The checked-in Gradle wrapper works when `JAVA_HOME` is set to the explicit
Homebrew OpenJDK 17 path above.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `./gradlew --version --console=plain --no-daemon` | BLOCKED for default shell | macOS reported `Unable to locate a Java Runtime`. |
| `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported Homebrew OpenJDK `17.0.17`. |
| `JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk ./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true projects` | PASS | Project graph listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; Gradle reported `BUILD SUCCESSFUL in 16s`. |
| `ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk adb devices -l` | BLOCKED | `List of devices attached` was empty. |
| `ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk emulator -list-avds` | PASS | Listed `Medium_Phone`. |
| Headless boot attempt for `Medium_Phone` | BLOCKED | Emulator process exited before registering with ADB; no device appeared within the 360s boot wait. |
| `JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk bash tools/device_validation_preflight.sh` | BLOCKED | Reported no attached Android device or booted emulator, no installed API 27 system image, no attached API 27 device, no low-memory/small-screen device, and no attached API 34+ modern device. |
| `JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk ./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true :app:connectedDebugAndroidTest` | BLOCKED | Gradle compiled/packaged the debug app and androidTest APKs, then failed at `:app:connectedDebugAndroidTest` with `DeviceException: No connected devices!`; `152 actionable tasks: 6 executed, 146 up-to-date`. |

Gradle printed its standard deprecation warning:

```text
Deprecated Gradle features were used in this build, making it incompatible with Gradle 10.
```

This warning was not the blocker for the connected validation command.

## Connected Test Artifact Evidence

The blocked `:app:connectedDebugAndroidTest` run successfully prepared the
installable debug artifacts before failing at the device execution step:

- `android/app/build/outputs/apk/debug/app-debug.apk`
- `android/app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk`

Existing Android instrumentation coverage under `app/src/androidTest` includes:

- `MainActivityIntentContractTest`
- `MainActivityReaderScenarioTest`

These tests could not execute in this batch because no device or booted emulator
was available.

## Device And Emulator Evidence

`adb devices -l` returned no attached or booted devices:

```text
List of devices attached
```

`emulator -list-avds` returned:

```text
Medium_Phone
```

The configured `Medium_Phone` AVD is API 36, not API 27:

```text
target = android-36
image.sysdir.1 = system-images/android-36/google_apis_playstore_ps16k/arm64-v8a/
hw.ramSize = 2048
hw.lcd.width = 1080
hw.lcd.height = 2400
```

The headless emulator boot attempt used:

```text
emulator -avd Medium_Phone -no-window -no-audio -no-boot-anim -no-snapshot-load -no-snapshot-save -gpu swiftshader_indirect
```

The emulator log reached early startup and then the process exited before ADB
listed a device. The boot wait ended with:

```text
BLOCKED: emulator did not boot within 360s
```

A follow-up process check found no lingering `Medium_Phone` or `qemu-system`
emulator process, and a follow-up `adb devices -l` still showed no devices.

## Preflight Blockers

`tools/device_validation_preflight.sh` found five device-readiness blockers:

- No attached Android device or booted emulator is available for
  `connectedDebugAndroidTest`.
- No Android API 27 system image is installed under
  `/Users/wangweiyang/Library/Android/sdk/system-images`.
- No attached API 27 device/emulator is ready for Android 8.1 validation.
- No attached low-memory device/emulator was detected for low-memory/small-screen
  validation.
- No attached API 34+ device/emulator is ready for modern-device validation.

## Remaining Open Items

Keep these L12 checklist items open unless covered by a separate device-backed
report:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

The Android `lint`, `build`, `:core:testDebugUnitTest`,
`:feature:reader:testDebugUnitTest`, and `:app:assembleDebug` items have
separate passing evidence in
`android/docs/reports/stage1-android-l12-gradle-validation-refresh-batch140-20260510.md`.

## Supervisor Checklist Recommendation

Do not mark the connected or device-backed Android L12 checklist items complete
from this report. Use this report as fresh Android-lane blocker evidence for:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

Use this report as minimum Android host sanity evidence for:

- `./gradlew projects`.
