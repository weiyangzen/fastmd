# Stage 1 Android L12 Validation Refresh Batch 106 - 2026-05-09

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
platform validation items in `Docs/Stage1_Mobile_Blueprint.md` and
`Docs/todos_20260506.md`.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android product source changes were required in this batch because the
current open Android cluster is validation and evidence capture.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-validation-refresh-batch106-20260509.md`

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-09 at about 21:48 CST.

- Default shell Java discovery remains blocked:
  - `java -version` exited 1 with `Unable to locate a Java Runtime`.
- Android Studio JBR is present, but it is JDK 21:
  `/Applications/Android Studio.app/Contents/jbr/Contents/Home`.
- Gradle validation used explicit JDK 17:
  `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`.
- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Maven resolution used the local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.
- Android SDK path from `local.properties`:
  `/Users/wangweiyang/Library/Android/sdk`.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED | macOS reported `Unable to locate a Java Runtime`; Gradle commands below used explicit JDK 17. |
| `JAVA_HOME=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true projects --stacktrace` | PASS | Project graph listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 14s`. |
| `JAVA_HOME=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true lint --stacktrace` | PASS | Lint reports were written for `app`, `core`, `feature:library`, `feature:reader`, and `feature:settings`; `BUILD SUCCESSFUL in 2m 46s`. |
| `JAVA_HOME=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true :core:testDebugUnitTest :feature:reader:testDebugUnitTest :app:assembleDebug stage1AndroidPerformanceReport --stacktrace` | PASS | `:core:testDebugUnitTest`, `:feature:reader:testDebugUnitTest`, `:app:assembleDebug`, and `stage1AndroidPerformanceReport` completed; `BUILD SUCCESSFUL in 37s`. |
| `JAVA_HOME=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true build --stacktrace` | PASS | Full Android build completed, including debug/release assembly, unit tests, lint/check tasks, R8 release packaging, and renderer asset/request-blocking gates; `BUILD SUCCESSFUL in 5m 55s`. |
| `JAVA_HOME=... ANDROID_SDK_ROOT=... bash tools/device_validation_preflight.sh` | BLOCKED | ADB printed an empty attached-device list; no API 27 system image is installed; only Android 36 system images are installed; one AVD named `Medium_Phone` exists but was not booted; preflight found 5 blocker(s). |
| `JAVA_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true :app:connectedDebugAndroidTest --stacktrace` | BLOCKED | Debug app and androidTest APK packaging reached `:app:connectedDebugAndroidTest`, then failed with `com.android.builder.testing.api.DeviceException: No connected devices!`; `BUILD FAILED in 44s`. |

## Performance Report Details

`stage1AndroidPerformanceReport` produced the Android source-level performance
posture report:

| Profile | Soft Limit Bytes |
| --- | ---: |
| WatchCompact | 262144 |
| LegacyEfficient | 1048576 |
| ModernStandard | 5242880 |
| LargeScreen | 5242880 |

| Fixture | Bytes | Lines |
| --- | ---: | ---: |
| `basic.md` | 124 | 7 |
| `rich-preview.md` | 5050 | 246 |
| `long-1mb.md` | 328 | 10 |
| `large-5mb.md` | 296 | 8 |
| `huge-table.md` | 333 | 9 |
| `huge-code-block.md` | 176 | 11 |
| `remote-image.md` | 148 | 5 |
| `local-image.md` | 142 | 5 |

This is source-level Android performance evidence. It does not replace API 27
device/emulator timing, low-memory/small-screen runtime validation, or modern
device runtime validation.

## Device Matrix Findings

The local Android SDK currently has these runtime validation blockers:

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
marking these Android L12 checklist items complete:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Capture Android performance report.

Keep these runtime/device L12 items open until a matching device or booted
emulator is available:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.
