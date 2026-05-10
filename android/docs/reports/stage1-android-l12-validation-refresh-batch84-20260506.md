# Stage 1 Android L12 Validation Refresh Batch 84 - 2026-05-06

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
platform validation items from `Docs/todos_20260506.md`.

This batch stayed inside Android ownership. It did not edit shared `Docs/**`,
`ios/**`, or `.cron/**`. No Android Kotlin or Compose product source changes
were made because the remaining failures are local validation environment and
dependency resolution blockers rather than implementation failures observed in
source.

## Environment

- Working directory: `/Users/wangweiyang/GitHub/fastmd/android`
- Batch timestamp: `2026-05-06 19:47:26 CST`
- Gradle entry point: checked-in wrapper `./gradlew`
- Explicit validation JDK:
  `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`
- Explicit JDK result:
  `openjdk version "17.0.17" 2025-10-21`
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
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew lint --no-daemon --stacktrace` | BLOCKED | Gradle reached real Android tasks and failed at `:core:extractDebugAnnotations` after `dl.google.com:443` timed out while resolving `com.android.application.gradle.plugin:8.13.2` and `com.android.tools.lint:lint-gradle:31.13.2`; `BUILD FAILED in 4m 52s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew projects --offline --no-daemon` | PASS | Root project `fastmd-android` evaluated and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 17s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew stage1AndroidPerformanceReport --offline --no-daemon` | PASS | Ran `:auditPerformanceReport`; printed Android performance profile limits and fixture size matrix; `PASS: Android performance report audit completed.`; `BUILD SUCCESSFUL in 17s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew :core:testDebugUnitTest --offline --no-daemon --stacktrace` | BLOCKED | Gradle reached `:core:testDebugUnitTest` and failed resolving runtime jars `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0`; offline mode reported no cached versions; `BUILD FAILED in 18s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew :app:assembleDebug --offline --no-daemon --stacktrace` | BLOCKED | Gradle reached `:feature:library:compileDebugKotlin` and failed resolving `androidx.compose.compiler:compiler:1.5.14`; offline mode reported no cached version; `BUILD FAILED in 21s`. |
| `ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk /Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices` | BLOCKED for connected/device validation | ADB ran successfully, but no attached devices or running emulators were listed. |
| `ls -d /Users/wangweiyang/Library/Android/sdk/platforms/android-35 /Users/wangweiyang/Library/Android/sdk/system-images/android-27 /Users/wangweiyang/Library/Android/sdk/system-images/android-35` | PARTIAL / BLOCKED | Android platform `android-35` is present. API 27 and API 35 system image directories are absent. |
| `test -x /Users/wangweiyang/Library/Android/sdk/cmdline-tools/latest/bin/avdmanager ...` | BLOCKED | `avdmanager` is absent from the local SDK command-line tools path, so local AVD enumeration cannot run. |

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

- L12 `./gradlew lint` remains open because Google Maven access to
  `dl.google.com:443` timed out while resolving AGP/lint artifacts.
- L12 `./gradlew build` remains open by implication from the assemble/debug
  dependency blocker and should be rerun when Google Maven/cache access is
  restored.
- L12 `./gradlew :core:testDebugUnitTest` remains open because AndroidX runtime
  jars `collection-ktx:1.4.0` and `concurrent-futures:1.1.0` are not available
  in the local Gradle cache.
- L12 `./gradlew :feature:reader:testDebugUnitTest` remains open by implication
  from the Compose compiler cache blocker and should be rerun when dependency
  resolution is available.
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
- L12: Capture Android performance report.

Do not mark Android lint, build, unit-test, assemble, connected-device, API 27,
low-memory/small-screen, or modern-device validation complete from this batch.
