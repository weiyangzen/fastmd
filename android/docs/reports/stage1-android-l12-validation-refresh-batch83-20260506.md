# Stage 1 Android L12 Validation Refresh Batch 83 - 2026-05-06

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned items
from `Docs/todos_20260506.md`: L12 platform validation and Android performance
report capture.

This batch stayed inside Android ownership. It did not edit shared `Docs/**`,
`ios/**`, or `.cron/**`. No Android product source changes were made because the
observed failures are validation-environment dependency cache / repository
access blockers, not Kotlin or Compose source failures.

## Environment

- Working directory: `/Users/wangweiyang/GitHub/fastmd/android`
- Batch timestamp: `2026-05-06 19:37:37 CST`
- Gradle entry point: checked-in wrapper `./gradlew`
- Explicit validation JDK:
  `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`
- Default shell Java posture: `/usr/bin/java` exists, but `java -version` fails
  with `Unable to locate a Java Runtime`
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
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew projects --no-daemon` | BLOCKED / INTERRUPTED | Online wrapper validation started a single-use Gradle daemon but produced no project output after several minutes. The local process was stopped to keep the batch bounded. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew projects --offline --no-daemon --stacktrace` | PASS | Root project `fastmd-android` evaluated and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 14s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew lint --offline --no-daemon --stacktrace` | BLOCKED | Gradle reached `:core:extractDebugAnnotations`, then failed resolving `com.android.tools.lint:lint-gradle:31.13.2`; offline mode reported `No cached version ... available`; `BUILD FAILED in 18s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew build --offline --no-daemon --stacktrace` | BLOCKED | Gradle reached `:feature:library:compileDebugKotlin`, then failed resolving `androidx.compose.compiler:compiler:1.5.14`; offline mode reported `No cached version ... available`; `BUILD FAILED in 19s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew :core:testDebugUnitTest --offline --no-daemon --stacktrace` | BLOCKED | Gradle reached `:core:testDebugUnitTest`, then failed resolving runtime jars `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0`; offline mode reported no cached artifacts; `BUILD FAILED in 16s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew :feature:reader:testDebugUnitTest --offline --no-daemon --stacktrace` | BLOCKED | Gradle reached `:feature:reader:compileDebugKotlin`, then failed resolving `androidx.compose.compiler:compiler:1.5.14`; offline mode reported no cached artifact; `BUILD FAILED in 16s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew :app:assembleDebug --offline --no-daemon --stacktrace` | BLOCKED | Gradle reached `:feature:library:compileDebugKotlin`, then failed resolving `androidx.compose.compiler:compiler:1.5.14`; offline mode reported no cached artifact; `BUILD FAILED in 17s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew stage1AndroidPerformanceReport --offline --no-daemon` | PASS | Ran `:auditPerformanceReport`; printed profile limits and fixture size matrix; completed with `PASS: Android performance report audit completed.` and `BUILD SUCCESSFUL in 14s`. |
| `ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk /Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices` | BLOCKED for connected/device validation | ADB ran successfully, but no attached devices or running emulators were listed. |
| `ls -d /Users/wangweiyang/Library/Android/sdk/platforms/android-35 /Users/wangweiyang/Library/Android/sdk/system-images/android-27 /Users/wangweiyang/Library/Android/sdk/system-images/android-35` | PARTIAL / BLOCKED | Android platform `android-35` is present. API 27 and API 35 system image directories are absent. |
| `ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk /Users/wangweiyang/Library/Android/sdk/cmdline-tools/latest/bin/avdmanager list avd` | BLOCKED | `avdmanager` is absent from the local SDK command-line tools path, so local AVD enumeration cannot run. |

## Performance Report Snapshot

`./gradlew stage1AndroidPerformanceReport --offline --no-daemon` printed these
profile limits:

```text
WatchCompact softLimitBytes=262144
LegacyEfficient softLimitBytes=1048576
ModernStandard softLimitBytes=5242880
LargeScreen softLimitBytes=5242880
```

The fixture matrix included:

```text
basic.md bytes=124 lines=7
rich-preview.md bytes=5050 lines=246
long-1mb.md bytes=328 lines=10
large-5mb.md bytes=296 lines=8
huge-table.md bytes=333 lines=9
huge-code-block.md bytes=176 lines=11
remote-image.md bytes=148 lines=5
local-image.md bytes=142 lines=5
```

## Preserved Blockers

- L12 `./gradlew lint` remains open because `com.android.tools.lint:lint-gradle:31.13.2`
  is not available in the local Gradle cache, and the online wrapper attempt did
  not make progress within this bounded batch.
- L12 `./gradlew build` remains open because `androidx.compose.compiler:compiler:1.5.14`
  is not available in the local Gradle cache.
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

The supervising session can use this report as Android-lane evidence for:

- L12: Run Android `./gradlew projects` as the minimum wrapper-backed Gradle
  validation required when deeper Gradle tasks are blocked.
- L12: Capture Android performance report.

Do not mark Android lint, build, unit-test, assemble, connected-device, API 27,
low-memory/small-screen, or modern-device validation complete from this batch.
