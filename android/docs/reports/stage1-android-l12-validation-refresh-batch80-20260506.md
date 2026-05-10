# Stage 1 Android L12 Validation Refresh Batch 80 - 2026-05-06

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
platform validation items from `Docs/todos_20260506.md`.

This batch stayed inside Android ownership. It did not edit shared `Docs/**`,
`ios/**`, or `.cron/**`. No Android product source changes were made because the
reproduced failures are external Google Maven connectivity blockers, not source
or project-configuration failures.

## Environment

- Working directory: `/Users/wangweiyang/GitHub/fastmd/android`
- Timestamp: `2026-05-06 15:39:29 CST`
- Gradle entry point: checked-in wrapper `./gradlew`
- Explicit JDK: `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`
- JDK version: OpenJDK `17.0.17`
- Android SDK path: `/Users/wangweiyang/Library/Android/sdk`
- Android platform `android-35`: present
- Connected Android devices: none; `adb devices` printed only `List of devices attached`
- Android API 27 system image directory: absent at `/Users/wangweiyang/Library/Android/sdk/system-images/android-27`

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew projects --no-daemon` | PASS | Root project `fastmd-android` evaluated and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 12s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew lint --no-daemon` | BLOCKED | Gradle reached `:core:extractDebugAnnotations`, then failed resolving `com.android.tools.lint:lint-gradle:31.13.2` from Google Maven because `https://dl.google.com/dl/android/maven2/.../lint-gradle-31.13.2.pom` timed out; `BUILD FAILED in 3m 19s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew build --no-daemon` | BLOCKED | Gradle reached `:feature:library:compileDebugKotlin`, then failed resolving `androidx.compose.compiler:compiler:1.5.14` from Google Maven because `https://dl.google.com/dl/android/maven2/.../compiler-1.5.14.pom` timed out; `BUILD FAILED in 3m 21s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew :core:testDebugUnitTest --no-daemon` | BLOCKED | Gradle reached `:core:testDebugUnitTest`, then failed downloading `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0` runtime jars from Google Maven; `BUILD FAILED in 3m 19s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew :feature:reader:testDebugUnitTest --no-daemon` | BLOCKED | Gradle reached `:feature:reader:compileDebugKotlin`, then failed resolving `androidx.compose.compiler:compiler:1.5.14` from Google Maven because `https://dl.google.com/dl/android/maven2/.../compiler-1.5.14.pom` timed out; `BUILD FAILED in 3m 19s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew stage1AndroidPerformanceReport --no-daemon` | PASS | Ran `:auditPerformanceReport`; printed profile soft limits and fixture size matrix; completed with `PASS: Android performance report audit completed.` and `BUILD SUCCESSFUL in 13s`. |
| `ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk /Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices` | BLOCKED for connected/device validation | ADB ran successfully, but no attached devices or running emulators were listed. |
| `ls -d /Users/wangweiyang/Library/Android/sdk/system-images/android-27` | BLOCKED for API 27 validation | The API 27 system image directory is absent locally. |

## Performance Report Snapshot

`./gradlew stage1AndroidPerformanceReport --no-daemon` printed these profile
limits:

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

- L12 `./gradlew lint` remains open because Google Maven timed out resolving
  `com.android.tools.lint:lint-gradle:31.13.2`.
- L12 `./gradlew build` remains open because Google Maven timed out resolving
  `androidx.compose.compiler:compiler:1.5.14`.
- L12 `./gradlew :core:testDebugUnitTest` remains open because Google Maven
  timed out resolving AndroidX runtime dependencies after the test task was
  reached.
- L12 `./gradlew :feature:reader:testDebugUnitTest` remains open because Google
  Maven timed out resolving the Compose compiler artifact during reader module
  compilation.
- L12 `./gradlew :app:assembleDebug` remains open behind the same Compose
  compiler dependency-resolution blocker until retried successfully.
- L12 `./gradlew :app:connectedDebugAndroidTest` remains open because no Android
  device or emulator is attached.
- Android API 27 validation remains open because no API 27 system image or
  attached API 27 target is present.
- Android low-memory/small-screen profile validation remains open because no
  matching device or emulator is attached.
- Android modern-device validation remains open because no attached Android
  device or emulator is available.

## Supervisor Checklist Recommendation

The supervising session can use this report as Android-lane evidence for:

- L12: Run Android `./gradlew projects` as the minimum wrapper-backed Gradle
  validation required when deeper tasks are blocked.
- L12: Capture Android performance report.

Do not mark Android lint, build, unit-test, assemble, connected-device, API 27,
low-memory/small-screen, or modern-device validation complete from this batch.
