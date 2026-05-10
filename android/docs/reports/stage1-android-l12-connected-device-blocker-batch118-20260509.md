# Stage 1 Android L12 Connected Device Blocker Batch 118 - 2026-05-09

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
runtime validation item:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android product source changes were made. The only repository write in this
batch is this Android-local evidence report.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-connected-device-blocker-batch118-20260509.md`

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-09.

- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Explicit JDK:
  `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`.
- Explicit Java version:
  `openjdk version "17.0.17" 2025-10-21`.
- Android SDK path:
  `/Users/wangweiyang/Library/Android/sdk`.
- Maven resolution used local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported Homebrew OpenJDK `17.0.17`. |
| `JAVA_HOME=... ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true projects --stacktrace` | PASS | Project graph listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; Gradle reported `BUILD SUCCESSFUL in 13s`. |
| `ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk /Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices -l` | BLOCKED for device work | Printed `List of devices attached` with no attached device rows. |
| `ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk /Users/wangweiyang/Library/Android/sdk/emulator/emulator -list-avds` | PASS | Listed one AVD: `Medium_Phone`. |
| `find /Users/wangweiyang/Library/Android/sdk/system-images -maxdepth 4 -type d` | BLOCKED for API 27 validation | Installed system images are Android 36 only; no Android API 27 system image is installed. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true :app:connectedDebugAndroidTest --stacktrace` | BLOCKED | Gradle reached `:app:connectedDebugAndroidTest` after debug app and androidTest packaging, then failed with `com.android.builder.testing.api.DeviceException: No connected devices!`; `BUILD FAILED in 20s`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... bash tools/device_validation_preflight.sh` | BLOCKED | Preflight found 5 blockers: no attached Android device or booted emulator; no API 27 system image; no attached API 27 target; no low-memory/small-screen target; no API 34+ target. |

## Device Matrix Findings

The local Android SDK/runtime state still blocks device-backed L12 validation:

- No attached Android device or booted emulator is available for
  `connectedDebugAndroidTest`.
- The only listed AVD is `Medium_Phone`, and it was not booted during this
  batch.
- Installed system images are Android 36 only under
  `/Users/wangweiyang/Library/Android/sdk/system-images`.
- No Android API 27 system image is installed, so Android 8.1/API 27 validation
  cannot run locally.
- No attached low-memory or small-screen device/emulator was detected.
- No attached API 34+ device/emulator is ready for modern-device validation.

## Supervisor Checklist Recommendation

Do not mark any new Android L12 runtime/device checklist item complete from this
batch.

Keep these Android L12 items open until a matching attached device or booted
emulator is available:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.
