# Stage 1 Android L12 Gradle Validation Refresh Batch 100

Date: 2026-05-06

Worker: FastMD Stage 1 Mobile Android live lane

Ownership: Android-only. This batch wrote only under `android/docs/reports/**`
and did not edit shared `Docs/**`, `ios/**`, or `.cron/**`.

## Scope

Earliest still-open Android-owned cluster in `Docs/todos_20260506.md` is L12
Platform Validation. This bounded batch refreshed the non-device Android Gradle
gates and then attempted the next device-backed gate.

Primary checklist targets:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Run Android `./gradlew :app:connectedDebugAndroidTest`.

## Environment

- Android project: `/Users/wangweiyang/GitHub/fastmd/android`
- JDK used: `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`
- Android SDK used: `/Users/wangweiyang/Library/Android/sdk`
- Gradle wrapper: `./gradlew`, Gradle `9.3.0`
- Maven profile: `-Pfastmd.useChinaMavenMirror=true`
- Attached devices before connected test: none
- Local AVDs: `Medium_Phone`
- Installed system images: Android 36 arm64 Google APIs / Play Store variants only

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME=... ANDROID_SDK_ROOT=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon projects --stacktrace` | PASS | Root project `fastmd-android` evaluated and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 13s`. |
| `JAVA_HOME=... ANDROID_SDK_ROOT=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon lint --stacktrace` | PASS | Lint reports were written for app/core/feature modules; `BUILD SUCCESSFUL in 2m 31s`. |
| `JAVA_HOME=... ANDROID_SDK_ROOT=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon :core:testDebugUnitTest --stacktrace` | PASS | `:core:testDebugUnitTest` executed; `BUILD SUCCESSFUL in 36s`. |
| `JAVA_HOME=... ANDROID_SDK_ROOT=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon :feature:reader:testDebugUnitTest --stacktrace` | PASS | `:feature:reader:testDebugUnitTest` executed; `BUILD SUCCESSFUL in 24s`. |
| `JAVA_HOME=... ANDROID_SDK_ROOT=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon build --stacktrace` | PASS | Aggregate build completed debug/release assembly, lint, unit tests, and Android renderer asset/request-blocking gates; `BUILD SUCCESSFUL in 3m 44s`. |
| `JAVA_HOME=... ANDROID_SDK_ROOT=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon :app:assembleDebug --stacktrace` | PASS | Debug APK assembly completed directly; `BUILD SUCCESSFUL in 17s`. |
| `ANDROID_SDK_ROOT=... adb devices -l` | BLOCKED for device-backed validation | ADB printed `List of devices attached` with no attached device entries. |
| `ANDROID_SDK_ROOT=... emulator -list-avds` | PASS preflight | Listed `Medium_Phone`. |
| `find /Users/wangweiyang/Library/Android/sdk/system-images -maxdepth 3 -type d` | BLOCKED for API 27 validation | Only Android 36 system images are installed locally; no `system-images/android-27` directory is present. |
| `JAVA_HOME=... ANDROID_SDK_ROOT=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon :app:connectedDebugAndroidTest --stacktrace` | BLOCKED by no device | Gradle built/reused the debug app and androidTest APKs, then `:app:connectedDebugAndroidTest` failed with `com.android.builder.testing.api.DeviceException: No connected devices!`; `BUILD FAILED in 20s`. |

## Device Validation Blockers

- L12 `./gradlew :app:connectedDebugAndroidTest` remains open because no
  Android device or booted emulator is attached.
- Android API 27 validation remains open because this host currently has only
  Android 36 system images installed.
- Android low-memory/small-screen profile validation remains open because no
  matching attached device or emulator was available in this batch.
- Android modern-device validation remains open because the available
  `Medium_Phone` AVD was not booted for an instrumented validation run.

## Supervisor Checklist Recommendation

The supervising session can use this report as fresh Android-lane evidence for
marking these L12 checklist items complete:

- L12: Run Android `./gradlew lint`.
- L12: Run Android `./gradlew build`.
- L12: Run Android `./gradlew :core:testDebugUnitTest`.
- L12: Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- L12: Run Android `./gradlew :app:assembleDebug`.

Do not mark these device-backed items complete from this batch:

- L12: Run Android `./gradlew :app:connectedDebugAndroidTest`.
- L12: Run Android API 27 validation.
- L12: Run Android low-memory/small-screen profile validation.
- L12: Run Android modern device validation.

