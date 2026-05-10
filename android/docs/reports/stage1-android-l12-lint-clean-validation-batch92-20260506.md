# Stage 1 Android L12 Lint Clean Validation Batch 92 - 2026-05-06

## Scope

Android live-lane bounded implementation and validation batch for the earliest
still-open Android-owned L12 platform validation items in the authoritative
Stage 1 Mobile blueprint and the 2026-05-06 todo snapshot.

This batch stayed inside `android/**`. It did not edit `ios/**`,
`Docs/Stage1_Mobile_Blueprint.md`, `Docs/todos_20260506.md`, or `.cron/**`.

## Implementation

This batch made a small Android-only lint hardening change before rerunning the
Gradle validation gates:

- Replaced deprecated Material 3 `Divider` usage in the reader with
  `HorizontalDivider`.
- Replaced the deprecated generic parcelable extra read for shared document
  `Uri` values with an API-level helper that uses the Android 13 typed
  overload when available and a locally suppressed legacy fallback on API 27-32.

The Android implementation remains native Kotlin / Jetpack Compose. No React
Native, Flutter, Cordova, remote WebView shell, or web app runtime was added.

## Changed Android Files

- `android/app/src/main/java/com/fastmd/mobile/document/AndroidDocumentEntry.kt`
- `android/feature/reader/src/main/java/com/fastmd/mobile/feature/reader/ReaderScreen.kt`
- `android/docs/reports/stage1-android-l12-lint-clean-validation-batch92-20260506.md`

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-06.

- Default shell Java discovery remains blocked: `java -version` printed
  `Unable to locate a Java Runtime`.
- Gradle validation used explicit JDK 17:
  `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`.
- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Maven resolution used the local-network mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.
- Android SDK path used for device checks:
  `/Users/wangweiyang/Library/Android/sdk`.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED without explicit JDK | macOS reported `Unable to locate a Java Runtime`; Gradle commands below used explicit JDK 17. |
| `JAVA_HOME=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon projects` | PASS | Root project `fastmd-android` evaluated and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 13s`. |
| `JAVA_HOME=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon lint --stacktrace` | PASS | All Android module lint tasks completed; lint reports were written for app, core, library, reader, and settings; `BUILD SUCCESSFUL in 2m 29s`. |
| `JAVA_HOME=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon :core:testDebugUnitTest :feature:reader:testDebugUnitTest :app:assembleDebug --stacktrace` | PASS | Core debug unit tests, reader debug unit tests, and app debug assembly completed; `BUILD SUCCESSFUL in 37s`. |
| `JAVA_HOME=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon build --stacktrace` | PASS | Full Android build completed, including debug/release packaging, unit tests, lint, R8 release packaging, and the wired renderer asset/request-blocking gates; `BUILD SUCCESSFUL in 5m 5s`. |
| `JAVA_HOME=... ANDROID_SDK_ROOT=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon :app:connectedDebugAndroidTest --stacktrace` | PASS / no-device caveat | Gradle packaged and ran the command-level connected test task; `BUILD SUCCESSFUL in 19s`. No checked-in Android instrumentation test source exists in `app`, `core`, or `feature/reader`, and ADB listed no attached devices, so this is not device-backed runtime evidence. |
| `ANDROID_SDK_ROOT=... /Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices` | BLOCKED for runtime device validation | ADB ran successfully, but printed only `List of devices attached`; no device or emulator was connected. |
| `find /Users/wangweiyang/Library/Android/sdk/system-images -maxdepth 3 -type d` | BLOCKED for API 27 emulator validation | Installed system images are Android 36 arm64 Google APIs / Play Store variants only; no `android-27` system image is installed. |
| `find app core feature/reader -path '*/src/androidTest/*' -type f` | BLOCKED for device-backed instrumentation coverage | No Android instrumentation test source files were present in the checked modules. |
| `rg -n "Divider\\(\|getParcelableExtra<\|HorizontalDivider\|fun Intent.getUriExtra" android/app/src/main/java android/feature/reader/src/main/java` | PASS | No deprecated `Divider(` or generic `getParcelableExtra<...>` use remains in app/reader/core main source; the expected `HorizontalDivider` and `getUriExtra` helper were found. |
| `git diff --check -- android` | PASS | No whitespace errors were reported for Android changes. |

## Preserved Blockers

- Default shell Java discovery remains incomplete until a JDK is visible on
  `PATH` or `JAVA_HOME` is exported before wrapper use.
- Android API 27 validation remains open because no API 27 system image or
  attached API 27 device/emulator is present.
- Android low-memory/small-screen profile validation remains open because no
  matching device or emulator is attached.
- Android modern-device validation remains open because no attached Android
  device or emulator is present.
- Device-backed interpretation of `:app:connectedDebugAndroidTest` remains open:
  the Gradle task completed, but ADB listed no devices and the checked modules
  have no instrumentation test sources to execute.

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

Do not mark these runtime/device matrix items complete from this batch:

- Android API 27 validation.
- Android low-memory/small-screen profile validation.
- Android modern device validation.
