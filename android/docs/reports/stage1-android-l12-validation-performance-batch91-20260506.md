# Stage 1 Android L12 Validation And Performance Batch 91 - 2026-05-06

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
validation items in `Docs/Stage1_Mobile_Blueprint.md` and
`Docs/todos_20260506.md`.

This batch stayed inside `android/**`. It did not edit `Docs/**`, `ios/**`, or
`.cron/**`.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-validation-performance-batch91-20260506.md`

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-06.

- Default shell Java remains blocked: `./gradlew --version && ./gradlew projects`
  failed before Gradle startup with macOS `Unable to locate a Java Runtime`.
- Gradle validation used the Android Studio bundled JBR explicitly:
  `/Applications/Android Studio.app/Contents/jbr/Contents/Home`.
- Gradle wrapper: `./gradlew`, Gradle `9.3.0`.
- Android SDK path checked by command:
  `/Users/wangweiyang/Library/Android/sdk`.
- Maven resolution used `-Pfastmd.useChinaMavenMirror=true`.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `./gradlew --version && ./gradlew projects` | BLOCKED in default shell | macOS reported `Unable to locate a Java Runtime`; this confirms the default shell still lacks a discoverable Java runtime. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew projects --no-daemon -Pfastmd.useChinaMavenMirror=true --stacktrace` | PASS | `BUILD SUCCESSFUL in 4s`; project graph listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew lint --no-daemon -Pfastmd.useChinaMavenMirror=true --stacktrace` | PASS | `BUILD SUCCESSFUL in 4s`; lint tasks ran for app, core, library, reader, and settings modules. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew :core:testDebugUnitTest --no-daemon -Pfastmd.useChinaMavenMirror=true --stacktrace` | PASS | `BUILD SUCCESSFUL in 3s`; `:core:testDebugUnitTest` completed. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew :feature:reader:testDebugUnitTest --no-daemon -Pfastmd.useChinaMavenMirror=true --stacktrace` | PASS | `BUILD SUCCESSFUL in 4s`; `:feature:reader:testDebugUnitTest` completed. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew :app:assembleDebug --no-daemon -Pfastmd.useChinaMavenMirror=true --stacktrace` | PASS | `BUILD SUCCESSFUL in 4s`; `:app:assembleDebug` completed. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew build --no-daemon -Pfastmd.useChinaMavenMirror=true --stacktrace` | PASS | `BUILD SUCCESSFUL in 2m 1s`; aggregate build covered debug/release assembly, lint, unit tests, R8 release packaging, and the wired renderer asset/request-blocking gates. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew stage1AndroidPerformanceReport --no-daemon -Pfastmd.useChinaMavenMirror=true --stacktrace` | PASS | `BUILD SUCCESSFUL in 4s`; `auditPerformanceReport` printed profile limits and fixture size matrix, ending with `PASS: Android performance report audit completed.` |
| `ANDROID_SDK_ROOT='/Users/wangweiyang/Library/Android/sdk' /Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices` | BLOCKED for device-backed validation | Command ran successfully, but the attached-device list was empty. |
| `find /Users/wangweiyang/Library/Android/sdk/system-images -maxdepth 3 -type d` | BLOCKED for API 27 emulator validation | Local system images are Android 36 arm64 Google APIs / Play Store variants only; no `android-27` system image is installed. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ANDROID_SDK_ROOT='/Users/wangweiyang/Library/Android/sdk' ./gradlew :app:connectedDebugAndroidTest --no-daemon -Pfastmd.useChinaMavenMirror=true --stacktrace` | PASS as a Gradle command | `BUILD SUCCESSFUL in 4s`; the app has no Android instrumentation test source in this batch, so this does not prove real-device, API 27, low-memory, or modern-device behavior. |

## Performance Report Details

`stage1AndroidPerformanceReport` produced the following local source-level
profile and fixture summary:

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

This is a source-level Android performance posture report. It is not a
substitute for API 27 device/emulator timing, low-memory/small-screen runtime
validation, or modern-device runtime validation.

## Preserved Blockers

- The default shell still needs a discoverable Java runtime or explicit
  `JAVA_HOME`; without the Android Studio JBR path, Gradle cannot start.
- Android API 27 validation remains blocked locally because no API 27 system
  image or attached API 27 device is present.
- Android low-memory/small-screen profile validation remains blocked locally
  because no matching device or emulator is attached.
- Android modern-device validation remains blocked locally because `adb devices`
  reported no attached devices.
- The `:app:connectedDebugAndroidTest` command itself completed, but this batch
  does not provide device-backed functional evidence because the attached-device
  list is empty and the app has no instrumentation test source.

## Supervisor Checklist Recommendation

The supervising session can use this report as Android-lane evidence for marking
these L12 checklist items complete:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Capture Android performance report.

Do not mark these runtime/device matrix items complete from this batch:

- Android API 27 validation.
- Android low-memory/small-screen profile validation.
- Android modern device validation.
