# Stage 1 Android L12 Validation Refresh Batch 87 - 2026-05-06

## Scope

Android live-lane bounded validation batch for the earliest still-open
Android-owned L12 platform validation gates in `Docs/todos_20260506.md`.

This batch stayed inside Android ownership. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`. No Kotlin or Compose product source changes were made
because the current Android-owned open work is L12 validation evidence and the
observed failures are local dependency-resolution and device-availability
blockers.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-validation-refresh-batch87-20260506.md`

## Environment

- Working directory: `/Users/wangweiyang/GitHub/fastmd/android`
- Batch timestamp: `2026-05-06 20:41:03 CST`
- Gradle entry point: checked-in wrapper `./gradlew`
- Explicit validation JDK:
  `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`
- Default shell Java discovery: blocked; `java -version` printed
  `Unable to locate a Java Runtime`.
- Explicit JDK check: `openjdk version "17.0.17" 2025-10-21`.
- Android SDK path from `android/local.properties`:
  `/Users/wangweiyang/Library/Android/sdk`
- Installed Android platforms observed: `android-31` through `android-36`,
  including required compile platform `android-35`.
- Android API 27 system image directory: absent at
  `/Users/wangweiyang/Library/Android/sdk/system-images/android-27`.
- Connected Android devices: none; `adb devices` printed only
  `List of devices attached`.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED without explicit JDK | Shell Java discovery failed with `Unable to locate a Java Runtime`; all wrapper-backed commands below used the explicit JDK 17 path. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew --offline --no-daemon projects` | PASS | Root project `fastmd-android` evaluated and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 13s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew --offline --no-daemon lint` | BLOCKED | Gradle reached `:core:extractDebugAnnotations` and failed resolving `com.android.tools.lint:lint-gradle:31.13.2`; offline mode reported no cached version; `BUILD FAILED in 16s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew --no-daemon lint` | BLOCKED / interrupted | Network-enabled lint printed the single-use daemon startup lines, then produced no additional output for more than two minutes. The wrapper process was terminated to keep the batch bounded. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew --offline --no-daemon build` | BLOCKED | Gradle reached `:feature:library:compileDebugKotlin` and failed resolving `androidx.compose.compiler:compiler:1.5.14`; offline mode reported no cached version; `BUILD FAILED in 19s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew --offline --no-daemon :core:testDebugUnitTest` | BLOCKED | Gradle compiled/reused core test classes, then `:core:testDebugUnitTest` failed resolving runtime jars `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0`; offline mode reported no cached versions; `BUILD FAILED in 15s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew --no-daemon :core:testDebugUnitTest` | BLOCKED / interrupted | Network-enabled core unit test printed the single-use daemon startup lines, then produced no additional output for more than two minutes. The wrapper process was terminated to keep the batch bounded. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew --offline --no-daemon :feature:reader:testDebugUnitTest` | BLOCKED | Gradle reached `:feature:reader:compileDebugKotlin` and failed resolving `androidx.compose.compiler:compiler:1.5.14`; offline mode reported no cached version; `BUILD FAILED in 15s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew --offline --no-daemon :app:assembleDebug` | BLOCKED | Gradle reached `:feature:library:compileDebugKotlin` and failed resolving `androidx.compose.compiler:compiler:1.5.14`; offline mode reported no cached version; `BUILD FAILED in 16s`. |
| `/Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices` | BLOCKED for connected/device validation | ADB ran successfully, but no attached Android device or running emulator was listed. |
| `ls /Users/wangweiyang/Library/Android/sdk/system-images/android-27` | BLOCKED for API 27 validation | API 27 system image directory is absent. |
| `bash tools/audit_performance_report.sh` | PASS | Printed Android performance profile limits and fixture size matrix; `PASS: Android performance report audit completed.` |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew --offline --no-daemon stage1AndroidPerformanceReport` | PASS | Ran `:auditPerformanceReport` and `:stage1AndroidPerformanceReport`; printed the performance profile limits and fixture matrix; `BUILD SUCCESSFUL in 14s`. |

## Missing Local Gradle Artifacts

Confirmed absent from the local Gradle cache:

```text
~/.gradle/caches/modules-2/files-2.1/androidx.collection/collection-ktx/1.4.0
~/.gradle/caches/modules-2/files-2.1/androidx.compose.compiler/compiler/1.5.14
~/.gradle/caches/modules-2/files-2.1/androidx.concurrent/concurrent-futures/1.1.0
~/.gradle/caches/modules-2/files-2.1/com.android.tools.lint/lint-gradle/31.13.2
```

## Performance Report Snapshot

The Android-local performance capture printed these profile limits:

```text
WatchCompact softLimitBytes=262144
LegacyEfficient softLimitBytes=1048576
ModernStandard softLimitBytes=5242880
LargeScreen softLimitBytes=5242880
```

The fixture matrix printed:

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

- L12 `./gradlew lint` remains open because
  `com.android.tools.lint:lint-gradle:31.13.2` is not available in the local
  Gradle cache, and the network-enabled wrapper attempt did not progress within
  the bounded validation window.
- L12 `./gradlew build` remains open because
  `androidx.compose.compiler:compiler:1.5.14` is not available in the local
  Gradle cache.
- L12 `./gradlew :core:testDebugUnitTest` remains open because AndroidX runtime
  jars `collection-ktx:1.4.0` and `concurrent-futures:1.1.0` are not available
  in the local Gradle cache, and the network-enabled wrapper attempt did not
  progress within the bounded validation window.
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
  matching Android device or emulator is attached.
- Android modern-device validation remains open because no attached Android
  device or emulator is present.

## Supervisor Checklist Recommendation

The supervising session can use this report as fresh Android-lane evidence for:

- L12: Capture Android performance report.
- Minimum required Android Gradle discovery evidence: `./gradlew projects`
  passes with explicit JDK 17 and offline dependency resolution.

Do not mark Android lint, build, unit-test, assemble, connected-device, API 27,
low-memory/small-screen, or modern-device validation complete from this batch.
