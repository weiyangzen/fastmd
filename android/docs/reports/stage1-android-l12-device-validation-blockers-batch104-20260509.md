# Stage 1 Android L12 Device Validation Blockers Batch 104 - 2026-05-09

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
platform validation items in `Docs/Stage1_Mobile_Blueprint.md` and
`Docs/todos_20260506.md`.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android source implementation changes were required in this batch because
the current open Android cluster is runtime/device validation evidence.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-device-validation-blockers-batch104-20260509.md`

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-09.

- Default shell Java discovery remains blocked:
  - `java -version` exited 1 with `Unable to locate a Java Runtime`.
- Gradle validation used explicit JDK 17:
  `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`.
- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Maven resolution used the local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.
- Android SDK path:
  `/Users/wangweiyang/Library/Android/sdk`.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED | macOS reported `Unable to locate a Java Runtime`; Gradle commands below used explicit JDK 17. |
| `JAVA_HOME=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon projects --stacktrace` | PASS | Project graph listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 13s`. |
| `JAVA_HOME=... ANDROID_SDK_ROOT=... bash tools/device_validation_preflight.sh` | BLOCKED | ADB printed `List of devices attached` with no devices; no API 27 system image is installed; only Android 36 system images are installed; one AVD named `Medium_Phone` exists but was not booted; preflight found 5 blocker(s). |
| `JAVA_HOME=... ANDROID_SDK_ROOT=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon :app:connectedDebugAndroidTest --stacktrace` | BLOCKED | Debug app and androidTest packaging reached `:app:connectedDebugAndroidTest`, then failed with `com.android.builder.testing.api.DeviceException: No connected devices!`; `BUILD FAILED in 19s`. |

## Device Matrix Findings

The local Android SDK currently has these device validation blockers:

- No attached Android device or booted emulator is available for
  `connectedDebugAndroidTest`.
- No Android API 27 system image is installed under
  `/Users/wangweiyang/Library/Android/sdk/system-images`.
- No attached API 27 device/emulator is ready for Android 8.1 validation.
- No attached low-memory device/emulator was detected for low-memory or
  small-screen validation.
- No attached API 34+ device/emulator is ready for modern-device validation.
- The only listed AVD is `Medium_Phone`, and it was not booted during this
  batch.

## Supervisor Checklist Recommendation

The supervising session can use this report as fresh Android-lane evidence for
the still-open runtime/device L12 items, but should keep them open until a
matching device or booted emulator is available:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

This report also reconfirms the minimum wrapper validation requirement:

- `./gradlew projects` passed with explicit JDK 17.

