# Stage 1 Android L12 Validation Refresh Batch 78 - 2026-05-06

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
validation items from `Docs/todos_20260506.md`.

This batch did not change product source. It refreshed wrapper-backed Android
validation evidence and captured the Android-local performance report under the
Android-owned report area.

## Environment

- Working directory: `/Users/wangweiyang/GitHub/fastmd/android`
- Gradle entry point: checked-in wrapper `./gradlew`
- Explicit JDK: `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`
- Android SDK path: `/Users/wangweiyang/Library/Android/sdk` from `android/local.properties`
- Default shell Java: blocked. `/usr/libexec/java_home -V` reported `Unable to locate a Java Runtime.`
- Connected Android devices: none. `adb devices` listed no device or emulator entries.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew projects --no-daemon` | PASS | Wrapper-backed Gradle evaluated root project `fastmd-android` and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 12s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew lint --no-daemon` | BLOCKED | Gradle reached `:core:extractDebugAnnotations`, then failed resolving `com.android.tools.lint:lint-gradle:31.13.2` from `https://dl.google.com/dl/android/maven2/...`; connection to `dl.google.com:443` timed out; `BUILD FAILED in 3m 55s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew :core:testDebugUnitTest --no-daemon` | BLOCKED | Gradle reached `:core:testDebugUnitTest`, then failed downloading `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0` runtime jars from Google Maven; `BUILD FAILED in 3m 37s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew :feature:reader:testDebugUnitTest --no-daemon` | BLOCKED | Gradle reached `:feature:reader:compileDebugKotlin`, then failed resolving `androidx.compose.compiler:compiler:1.5.14` from Google Maven; `BUILD FAILED in 3m 19s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew stage1AndroidPerformanceReport --no-daemon` | PASS | Ran `:auditPerformanceReport`; printed profile limits and fixture size matrix; reported `PASS: Android performance report audit completed.`; `BUILD SUCCESSFUL in 14s`. |

## Kotlin Daemon Note

During `lint` and `:core:testDebugUnitTest`, Gradle emitted the existing Kotlin
daemon warning caused by a stale daemon seeing Java `25.0.1`:

```text
Caused by: java.lang.IllegalArgumentException: 25.0.1
Using fallback strategy: Compile without Kotlin daemon
```

The Kotlin daemon warning did not become the terminal failure in this batch.
Both affected commands continued through fallback compilation and then stopped
on Google Maven dependency download timeouts.

## Performance Report Evidence

The Android-local performance report printed these source-level profile limits:

```text
WatchCompact softLimitBytes=262144
LegacyEfficient softLimitBytes=1048576
ModernStandard softLimitBytes=5242880
LargeScreen softLimitBytes=5242880
```

The report also scanned the Android fixture matrix and completed with:

```text
PASS: Android performance report audit completed.
```

## Checklist Recommendation

Supervisor can mark these Android checklist items complete from this report:

- L12: Run Android `./gradlew projects` as the minimum wrapper-backed Gradle validation.
- L12: Capture Android performance report.

Keep these Android L12 checklist items open:

- Run Android `./gradlew lint` because Google Maven timed out resolving `com.android.tools.lint:lint-gradle:31.13.2`.
- Run Android `./gradlew build` because lint and Compose-backed compile dependencies are still unresolved from Google Maven in this environment.
- Run Android `./gradlew :core:testDebugUnitTest` because runtime jars from Google Maven timed out.
- Run Android `./gradlew :feature:reader:testDebugUnitTest` because Compose compiler resolution from Google Maven timed out.
- Run Android `./gradlew :app:assembleDebug` because Compose compiler resolution from Google Maven blocked the reader module compile path.
- Run Android `./gradlew :app:connectedDebugAndroidTest` because no Android device or emulator is attached and compile-backed artifacts are not yet available.
- Run Android API 27 validation because no API 27 emulator/device was available in this batch.
- Run Android low-memory/small-screen profile validation because no matching emulator/device was available in this batch.
- Run Android modern device validation because no connected Android device or emulator was available in this batch.

