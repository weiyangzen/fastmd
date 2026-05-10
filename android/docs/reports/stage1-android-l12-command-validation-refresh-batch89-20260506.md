# Stage 1 Android L12 Command Validation Refresh Batch 89 - 2026-05-06

## Scope

Android live-lane bounded validation batch for the earliest Android-owned L12
platform validation gates that can be advanced without touching iOS or shared
Docs reconciliation files.

This batch stayed inside Android ownership. It did not edit `ios/**`,
`Docs/Stage1_Mobile_Blueprint.md`, `Docs/todos_20260506.md`, or `.cron/**`.
No React Native, Flutter, Cordova, remote WebView shell, or web app runtime was
introduced. The Android implementation remains native Kotlin / Jetpack Compose.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-command-validation-refresh-batch89-20260506.md`

No Android source code changes were required in this batch.

## Environment

- Working directory: `/Users/wangweiyang/GitHub/fastmd/android`
- Batch timestamp: `2026-05-06 21:18:59 CST`
- Gradle entry point: checked-in wrapper `./gradlew`
- Explicit validation JDK:
  `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`
- Default shell Java discovery: blocked; `java -version` printed
  `Unable to locate a Java Runtime`.
- Gradle mirror flag used for this network environment:
  `-Pfastmd.useChinaMavenMirror=true`
- Android SDK platform tools were available from:
  `/Users/wangweiyang/Library/Android/sdk/platform-tools`
- Connected Android devices after validation: none; `adb devices` printed only
  `List of devices attached`.
- Android API 27 system image directory: absent at
  `/Users/wangweiyang/Library/Android/sdk/system-images/android-27`.
- Checked-in instrumentation test sources: none found under
  `app/src/androidTest`, `core/src/androidTest`, or
  `feature/reader/src/androidTest`.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED without explicit JDK | Shell Java discovery failed with `Unable to locate a Java Runtime`; wrapper-backed commands below used explicit JDK 17. |
| `JAVA_HOME=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon projects` | PASS | Root project `fastmd-android` evaluated and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 13s`. |
| `JAVA_HOME=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon lint` | PASS | All Android module lint tasks completed; `BUILD SUCCESSFUL in 20s`. |
| `JAVA_HOME=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon build` | PASS | Full Android build completed, including app/core/feature builds, unit tests, lint, R8 release minification, and renderer asset/request gates; `BUILD SUCCESSFUL in 2m 22s`. |
| `JAVA_HOME=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon :core:testDebugUnitTest` | PASS | Core debug unit-test task completed; `BUILD SUCCESSFUL in 24s`. |
| `JAVA_HOME=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon :feature:reader:testDebugUnitTest` | PASS | Reader feature debug unit-test task completed; `BUILD SUCCESSFUL in 23s`. |
| `JAVA_HOME=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon :app:assembleDebug` | PASS | Debug APK assembly completed; `BUILD SUCCESSFUL in 27s`. |
| `JAVA_HOME=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon :app:connectedDebugAndroidTest` | PASS / no-device caveat | Gradle task completed and packaged the empty debug Android test APK; `BUILD SUCCESSFUL in 19s`. ADB still listed no attached devices, and no checked-in `androidTest` sources were present, so this is command-level packaging evidence only, not device-backed validation evidence. |
| `/Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices` | BLOCKED for device validation | ADB ran successfully, but no attached Android device or running emulator was listed. |
| `ls /Users/wangweiyang/Library/Android/sdk/system-images/android-27` | BLOCKED for API 27 validation | API 27 system image directory is absent. |

## Preserved Blockers

- Default Java discovery remains blocked until a JDK is visible on `PATH` or
  `JAVA_HOME` is exported before wrapper use.
- Android API 27 validation remains open because no API 27 system image or
  attached API 27 device/emulator is present.
- Android low-memory/small-screen profile validation remains open because no
  matching Android device or emulator is attached.
- Android modern-device validation remains open because no attached Android
  device or emulator is present.
- Device-backed interpretation of `:app:connectedDebugAndroidTest` remains open:
  the Gradle task completed, but ADB listed no devices and there are no
  checked-in `androidTest` sources to execute.

## Supervisor Checklist Recommendation

The supervising session can use this report as fresh Android-lane evidence to
mark these L12 checklist items complete:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.

Treat Android `./gradlew :app:connectedDebugAndroidTest` as command-level
packaging evidence only. Do not mark Android API 27 validation,
low-memory/small-screen validation, or modern-device validation complete from
this batch.
