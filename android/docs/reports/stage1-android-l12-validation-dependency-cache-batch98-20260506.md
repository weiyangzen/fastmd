# Stage 1 Android L12 Validation Dependency Cache Batch 98

Date: 2026-05-06

Worker: FastMD Stage 1 Mobile Android live lane

Ownership: Android-only. This batch wrote only under `android/docs/reports/**`.

## Scope

The earliest still-open Android-owned cluster is L12 Platform Validation. This
batch targeted the first Android Gradle validation gates that remain open in the
authoritative blueprint and daily todo snapshot:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Recheck connected-device availability before attempting connected validation.

No production source change was made because the observed failures were local
environment/dependency-cache blockers, not Kotlin/Compose source failures.

## Environment

- Repository: `/Users/wangweiyang/GitHub/fastmd`
- Android project: `/Users/wangweiyang/GitHub/fastmd/android`
- Initial shell Java state: `./gradlew projects` without `JAVA_HOME` failed with
  macOS `Unable to locate a Java Runtime`.
- Android Studio JBR found at
  `/Applications/Android Studio.app/Contents/jbr/Contents/Home`.
- Homebrew JDK 17 found at
  `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`.
- JDK used for final reproducible probes:
  `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `./gradlew projects` | BLOCKED without explicit Java | macOS reported `Unable to locate a Java Runtime`. |
| `JAVA_HOME=/Applications/Android Studio.app/Contents/jbr/Contents/Home ./gradlew projects` | BLOCKED by dependency/network resolution | Daemon started under Java 21, then produced no Gradle task output for about 4 minutes. A thread dump showed the Gradle worker in `sun.nio.ch.NioSocketImpl.timedFinishConnect`; the hung client and daemon were stopped. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew --offline --no-daemon projects --stacktrace` | PASS | Listed root project `fastmd-android` with `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 14s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew --offline --no-daemon lint` | BLOCKED by uncached dependency | `:core:extractDebugAnnotations` failed because `com.android.tools.lint:lint-gradle:31.13.2` has no cached version for offline mode. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew --no-daemon lint` | BLOCKED by dependency/network resolution | Online retry started a JDK17 single-use daemon, then produced no Gradle task output for about 2 minutes. Process snapshot showed `gradlew --no-daemon lint` and Gradle daemon alive; this matched the earlier dependency-resolution stall and was stopped. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew --offline --no-daemon :core:testDebugUnitTest` | BLOCKED by uncached dependencies | `:core:testDebugUnitTest` failed resolving `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0`; both reported `No cached version available for offline mode`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew --offline --no-daemon :feature:reader:testDebugUnitTest` | BLOCKED by uncached dependency | `:feature:reader:compileDebugKotlin` failed resolving `androidx.compose.compiler:compiler:1.5.14`; no cached version available for offline mode. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew --offline --no-daemon :app:assembleDebug` | BLOCKED by uncached dependency | `:feature:library:compileDebugKotlin` failed resolving `androidx.compose.compiler:compiler:1.5.14`; no cached version available for offline mode. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew --offline --no-daemon build` | BLOCKED by uncached dependency | Same blocker as assemble: `:feature:library:compileDebugKotlin` cannot resolve cached `androidx.compose.compiler:compiler:1.5.14` in offline mode. |
| `adb devices` through `local.properties` SDK path | BLOCKED for connected validation | ADB ran and printed only `List of devices attached`; no Android device or booted emulator was attached. |

## Preserved Blockers

- The wrapper and project graph are valid when an explicit JDK17 is provided and
  Gradle stays offline.
- The normal shell still lacks a discoverable Java runtime unless `JAVA_HOME` is
  set explicitly.
- Full Gradle gates remain open because required Android/Compose/lint artifacts
  are not fully cached for offline mode and online dependency resolution stalls
  locally.
- Connected Android validation remains open because no device or emulator is
  attached.

## Supervisor Checklist Recommendation

The supervisor can treat this report as fresh blocker evidence, but should not
mark the targeted L12 Gradle gates complete from this batch:

- L12: Run Android `./gradlew lint`.
- L12: Run Android `./gradlew build`.
- L12: Run Android `./gradlew :core:testDebugUnitTest`.
- L12: Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- L12: Run Android `./gradlew :app:assembleDebug`.
- L12: Run Android `./gradlew :app:connectedDebugAndroidTest`.

No additional blueprint checklist item should be marked complete from this
batch. `./gradlew projects` is not an open L12 checklist item, but it satisfies
the minimum validation probe requirement for this worker run when deeper gates
are blocked.
