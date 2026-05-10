# Stage 1 Android L12 Gradle Validation Retry Batch 55

Date: 2026-05-06
Lane: Android live lane
Scope: `android/**`

## Batch Selection

This bounded batch advanced the earliest still-open Android-owned L12 validation
cluster without touching iOS or the authoritative Docs checklists:

- L12 `Run Android ./gradlew lint`.
- L12 `Run Android ./gradlew build`.
- L12 `Run Android ./gradlew :core:testDebugUnitTest`.
- L12 `Run Android ./gradlew :feature:reader:testDebugUnitTest`.
- L12 minimum wrapper sanity validation through `./gradlew projects`.

No Android product source changes were needed. The current failures are external
dependency-resolution blockers against Google Maven, not Kotlin/Compose source
failures observed in this batch.

## Environment

- Repository root: `/Users/wangweiyang/GitHub/fastmd`
- Android root: `/Users/wangweiyang/GitHub/fastmd/android`
- Gradle wrapper: Gradle `9.3.0`
- Explicit validation JDK: `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`
- Wrapper JVM: OpenJDK `17.0.17`
- Default shell `java -version`: blocked by macOS with `Unable to locate a Java Runtime.`
- Android SDK platform scan: `platforms/android-35` is present.
- Android API 27 scan: `platforms/android-27` and API 27 system images were not found.
- Device scan: `adb devices` printed only `List of devices attached`; no target was attached or running.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `cd android && ./gradlew --version --no-daemon` | BLOCKED without explicit JDK | Default shell Java is unavailable: macOS reported `Unable to locate a Java Runtime.` |
| `cd android && JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew --version --no-daemon` | PASS | Reported Gradle `9.3.0`, launcher JVM `17.0.17`, and daemon JVM at the Homebrew JDK 17 path. |
| `cd android && JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew projects --no-daemon` | PASS | `BUILD SUCCESSFUL in 13s`; module graph included root `fastmd-android`, `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `cd android && JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew lint --no-daemon` | BLOCKED | Reached `:core:extractDebugAnnotations`, then failed resolving `com.android.tools.lint:lint-gradle:31.13.2` because `https://dl.google.com/dl/android/maven2/com/android/tools/lint/lint-gradle/31.13.2/lint-gradle-31.13.2.pom` timed out. |
| `cd android && JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew :core:testDebugUnitTest --no-daemon` | BLOCKED | Reached `:core:testDebugUnitTest`, then failed resolving AndroidX runtime jars from Google Maven: `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0`, both connect timeouts to `dl.google.com:443`. Kotlin daemon first logged `IllegalArgumentException: 25.0.1` and fell back to non-daemon compilation before the dependency blocker. |
| `cd android && JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew :feature:reader:testDebugUnitTest --no-daemon` | BLOCKED | Reached `:feature:reader:compileDebugKotlin`, then failed resolving `androidx.compose.compiler:compiler:1.5.14` from Google Maven because the Compose compiler POM request to `dl.google.com:443` timed out. |
| `cd android && JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew build --no-daemon` | BLOCKED | Reached `:feature:library:compileDebugKotlin`, then failed resolving `androidx.compose.compiler:compiler:1.5.14` from Google Maven because the Compose compiler POM request to `dl.google.com:443` timed out. |
| `adb devices` | PASS with device blocker | Command ran, but no attached device or running emulator was listed. |
| `find "$HOME/Library/Android/sdk" ... platforms/android-27/system-images/android-27/platforms/android-35` | PASS with API 27 blocker | Found `platforms/android-35`; did not find `platforms/android-27` or API 27 system images. |
| `cd android && bash tools/audit_renderer_assets.sh && bash tools/audit_renderer_request_blocking.sh` | PASS | Confirmed no Android WebView/android.webkit implementation, no web app runtime dependency, no vendored JS/CSS/font renderer asset tree, and request-policy/unit-test coverage for bundled asset allowlisting plus network, navigation, dangerous URL, content URI, percent-encoded URL, and iframe blocking. |

## Checklist Evidence For Supervisor

The supervisor can keep this L12 item marked complete if not already reconciled:

- L12 `Run Android ./gradlew projects.`
  Evidence: the JDK 17 wrapper command above passed and printed the expected module graph.

The supervisor should keep these Android L12 items open from this batch:

- L12 `Run Android ./gradlew lint.`
  Blocker: Google Maven timed out resolving `com.android.tools.lint:lint-gradle:31.13.2`.
- L12 `Run Android ./gradlew build.`
  Blocker: Google Maven timed out resolving `androidx.compose.compiler:compiler:1.5.14`.
- L12 `Run Android ./gradlew :core:testDebugUnitTest.`
  Blocker: Google Maven timed out resolving `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0`.
- L12 `Run Android ./gradlew :feature:reader:testDebugUnitTest.`
  Blocker: Google Maven timed out resolving `androidx.compose.compiler:compiler:1.5.14`.
- L12 `Run Android ./gradlew :app:connectedDebugAndroidTest.`
  Blocker: no attached Android device or running emulator.
- L12 `Run Android API 27 validation.`
  Blocker: no local API 27 SDK platform or API 27 system image was found.
- L12 `Run Android low-memory/small-screen profile validation.`
  Blocker: no attached device or running emulator.
- L12 `Run Android modern device validation.`
  Blocker: no attached device or running emulator.

## Files Touched

- `android/docs/reports/stage1-android-l12-gradle-validation-retry-batch55-20260506.md`
