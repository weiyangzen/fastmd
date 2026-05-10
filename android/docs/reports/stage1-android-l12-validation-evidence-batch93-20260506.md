# Stage 1 Android L12 Validation Evidence Batch 93 - 2026-05-06

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
platform validation items in `Docs/Stage1_Mobile_Blueprint.md` and
`Docs/todos_20260506.md`.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android app source changes were required in this batch because the current
open Android cluster is validation and evidence capture.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-validation-evidence-batch93-20260506.md`

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-06.

- Default shell Java discovery remains blocked: `java -version` reported
  `Unable to locate a Java Runtime`.
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
| `java -version` | BLOCKED without explicit JDK | macOS reported `Unable to locate a Java Runtime`; all Gradle commands below used explicit JDK 17. |
| `JAVA_HOME=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon projects lint :core:testDebugUnitTest :feature:reader:testDebugUnitTest :app:assembleDebug stage1AndroidPerformanceReport --stacktrace` | PASS | Project graph listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; lint completed across Android modules; core and reader debug unit tests completed; app debug assembly completed; `stage1AndroidPerformanceReport` printed profile limits and fixture matrix; `BUILD SUCCESSFUL in 23s`. |
| `JAVA_HOME=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon build --stacktrace` | PASS | Full Android build completed, including debug/release assembly, unit tests, lint/check tasks, R8 release packaging, and wired renderer asset/request-blocking gates; `BUILD SUCCESSFUL in 2m 20s`. |
| `ANDROID_SDK_ROOT=... /Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices` | BLOCKED for device-backed validation | ADB ran successfully, but printed only `List of devices attached`; no Android device or emulator was connected. |
| `JAVA_HOME=... ANDROID_SDK_ROOT=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon :app:connectedDebugAndroidTest --stacktrace` | PASS as Gradle packaging/task execution | Debug APK and debug Android test APK packaging completed and `:app:connectedDebugAndroidTest` returned `BUILD SUCCESSFUL in 20s`; this is not device-backed functional evidence because ADB listed no attached devices and `:app:compileDebugAndroidTestKotlin` was `NO-SOURCE`. |
| `find /Users/wangweiyang/Library/Android/sdk/system-images -maxdepth 3 -type d` | BLOCKED for API 27 emulator validation | Installed system images are Android 36 arm64 Google APIs / Play Store variants only; no `android-27` system image is installed. |
| `git diff --check -- android` | PASS | No whitespace errors were reported for Android files. |

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

## Preserved Blockers

- Default shell Java discovery remains incomplete until a JDK is visible on
  `PATH` or `JAVA_HOME` is exported before wrapper use.
- Android API 27 validation remains blocked locally because no API 27 system
  image or attached API 27 device/emulator is present.
- Android low-memory/small-screen profile validation remains blocked locally
  because no matching device or emulator is attached.
- Android modern-device validation remains blocked locally because `adb devices`
  reported no attached devices.
- Device-backed interpretation of `:app:connectedDebugAndroidTest` remains open:
  the Gradle task completed, but no Android device was attached and no
  instrumentation test source was present in the app module.

## Supervisor Checklist Recommendation

The supervising session can use this report as fresh Android-lane evidence for
marking these L12 checklist items complete:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Run Android `./gradlew :app:connectedDebugAndroidTest` as command-level
  packaging/task execution evidence only.
- Capture Android performance report.

Do not mark these runtime/device matrix items complete from this batch:

- Android API 27 validation.
- Android low-memory/small-screen profile validation.
- Android modern device validation.
