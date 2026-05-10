# Stage 1 Android L12 Validation Refresh Batch 85 - 2026-05-06

## Scope

Android live-lane bounded validation batch for the earliest still-open
Android-owned L12 platform validation gates in `Docs/todos_20260506.md`.

This batch stayed inside Android ownership. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`. No Android Kotlin or Compose product source changes
were made because the observed failures are dependency-resolution and device
availability blockers, not source-level implementation failures.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-validation-refresh-batch85-20260506.md`

## Environment

- Working directory: `/Users/wangweiyang/GitHub/fastmd/android`
- Batch timestamp: `2026-05-06 20:01:28 CST`
- Gradle entry point: checked-in wrapper `./gradlew`
- Explicit validation JDK:
  `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`
- Explicit JDK result:
  `openjdk version "17.0.17" 2025-10-21`
- Shell `java` default: blocked, prints "Unable to locate a Java Runtime"
- Android SDK path from `android/local.properties`:
  `/Users/wangweiyang/Library/Android/sdk`
- Android platform `android-35`: present
- Android API 27 system image directory: absent at
  `/Users/wangweiyang/Library/Android/sdk/system-images/android-27`
- Android API 35 system image directory: absent at
  `/Users/wangweiyang/Library/Android/sdk/system-images/android-35`
- Android command-line `avdmanager`: absent at
  `/Users/wangweiyang/Library/Android/sdk/cmdline-tools/latest/bin/avdmanager`
- Connected Android devices: none; `adb devices` printed only
  `List of devices attached`

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew projects --no-daemon --stacktrace` | PASS | Wrapper evaluated root project `fastmd-android` and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 3m 16s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew lint --no-daemon --stacktrace` | BLOCKED | Gradle reached real Android tasks and failed at `:core:extractDebugAnnotations` because Google Maven timed out resolving `com.android.application.gradle.plugin:8.13.2` and `com.android.tools.lint:lint-gradle:31.13.2`; `BUILD FAILED in 3m 19s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew build --offline --no-daemon --stacktrace` | BLOCKED | Gradle reached `:feature:library:compileDebugKotlin` and failed because `androidx.compose.compiler:compiler:1.5.14` is not cached locally for offline mode; `BUILD FAILED in 18s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew :core:testDebugUnitTest --offline --no-daemon --stacktrace` | BLOCKED | Gradle compiled/reused core test classes, then `:core:testDebugUnitTest` failed resolving runtime jars `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0`; offline mode reported no cached versions; `BUILD FAILED in 16s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew :feature:reader:testDebugUnitTest --offline --no-daemon --stacktrace` | BLOCKED | Gradle reached `:feature:reader:compileDebugKotlin` and failed because `androidx.compose.compiler:compiler:1.5.14` is not cached locally for offline mode; `BUILD FAILED in 15s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew :app:assembleDebug --offline --no-daemon --stacktrace` | BLOCKED | Gradle reached `:feature:library:compileDebugKotlin` and failed because `androidx.compose.compiler:compiler:1.5.14` is not cached locally for offline mode; `BUILD FAILED in 17s`. |
| `ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk /Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices` | BLOCKED for connected/device validation | ADB ran successfully, but no attached devices or running emulators were listed. |
| `ls -d /Users/wangweiyang/Library/Android/sdk/platforms/android-35 /Users/wangweiyang/Library/Android/sdk/system-images/android-27 /Users/wangweiyang/Library/Android/sdk/system-images/android-35` | PARTIAL / BLOCKED | Android platform `android-35` is present. API 27 and API 35 system image directories are absent. |
| `test -x /Users/wangweiyang/Library/Android/sdk/cmdline-tools/latest/bin/avdmanager ...` | BLOCKED | `avdmanager` is absent from the local SDK command-line tools path, so local AVD enumeration cannot run. |

## Preserved Blockers

- L12 `./gradlew lint` remains open because Google Maven access to
  `dl.google.com:443` timed out while resolving AGP/lint artifacts.
- L12 `./gradlew build` remains open because the Compose compiler artifact is
  not available in the local Gradle cache, and online Google Maven access is
  already blocked by the `lint` timeout.
- L12 `./gradlew :core:testDebugUnitTest` remains open because AndroidX runtime
  jars `collection-ktx:1.4.0` and `concurrent-futures:1.1.0` are not available
  in the local Gradle cache.
- L12 `./gradlew :feature:reader:testDebugUnitTest` remains open because
  `androidx.compose.compiler:compiler:1.5.14` is not available in the local
  Gradle cache.
- L12 `./gradlew :app:assembleDebug` remains open because
  `androidx.compose.compiler:compiler:1.5.14` is not available in the local
  Gradle cache.
- L12 `./gradlew :app:connectedDebugAndroidTest` remains open because no Android
  device or emulator is attached.
- Android API 27 validation remains open because no API 27 system image or
  attached API 27 target is present.
- Android low-memory/small-screen profile validation remains open because no
  matching device or emulator is attached.
- Android modern-device validation remains open because no attached Android
  device, emulator, API 35 system image, or local `avdmanager` is available.

## Supervisor Checklist Recommendation

The supervising session can use this report as fresh Android-lane evidence for:

- L12: Run Android `./gradlew projects` as the minimum wrapper-backed Gradle
  validation required when deeper Gradle tasks are blocked.

Do not mark Android lint, build, unit-test, assemble, connected-device, API 27,
low-memory/small-screen, or modern-device validation complete from this batch.
