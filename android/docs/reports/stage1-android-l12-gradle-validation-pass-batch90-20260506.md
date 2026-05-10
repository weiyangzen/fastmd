# Stage 1 Android L12 Gradle Validation Pass Batch 90 - 2026-05-06

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
platform validation items. This batch stayed inside `android/**` and did not
edit shared `Docs/**`, `ios/**`, or `.cron/**`.

Primary targets:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Reconfirm connected-device, API 27, low-memory/small-screen, and modern-device
  blockers without marking them complete.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-gradle-validation-pass-batch90-20260506.md`

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
`2026-05-06` in the Android live lane.

- Default shell `JAVA_HOME`: unset.
- Default shell `java -version`: blocked with `Unable to locate a Java Runtime`.
- Validation JVM used for Gradle:
  `/Applications/Android Studio.app/Contents/jbr/Contents/Home`.
- Gradle wrapper: `./gradlew`, Gradle `9.3.0`.
- Android SDK path from `local.properties`:
  `/Users/wangweiyang/Library/Android/sdk`.
- Maven resolution: default Google Maven run hung during initial online
  `./gradlew projects`; offline mode proved the project graph from cache, and
  `-Pfastmd.useChinaMavenMirror=true` allowed the compile/lint/test/build gates
  to complete.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED in default shell | macOS reported `Unable to locate a Java Runtime`; `JAVA_HOME` was unset. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew projects --no-daemon` | BLOCKED/HUNG | Started Gradle daemon and produced no further output for more than 6 minutes; the validation process was terminated and no Gradle daemon was left running. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew projects --no-daemon --offline --stacktrace` | PASS | Root project `fastmd-android` evaluated and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 4s`. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew lint --no-daemon --offline --stacktrace` | BLOCKED | Reached `:core:extractDebugAnnotations`, then failed because `com.android.tools.lint:lint-gradle:31.13.2` was not cached for offline mode. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew :core:testDebugUnitTest --no-daemon --offline --stacktrace` | BLOCKED | Reached `:core:testDebugUnitTest`, then failed because `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0` jars were not cached for offline mode. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew :feature:reader:testDebugUnitTest --no-daemon --offline --stacktrace` | BLOCKED | Reached `:feature:reader:compileDebugKotlin`, then failed because `androidx.compose.compiler:compiler:1.5.14` was not cached for offline mode. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew lint --no-daemon -Pfastmd.useChinaMavenMirror=true --stacktrace` | PASS | `BUILD SUCCESSFUL in 48s`; lint reports were written for `app`, `core`, `feature:library`, `feature:reader`, and `feature:settings`. Kotlin warnings were deprecations only: Material `Divider` rename in `ReaderScreen.kt` and `getParcelableExtra(String)` deprecation in `AndroidDocumentEntry.kt`. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew :core:testDebugUnitTest --no-daemon -Pfastmd.useChinaMavenMirror=true --stacktrace` | PASS | `BUILD SUCCESSFUL in 5s`; `:core:testDebugUnitTest` executed. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew :feature:reader:testDebugUnitTest --no-daemon -Pfastmd.useChinaMavenMirror=true --stacktrace` | PASS | `BUILD SUCCESSFUL in 8s`; `:feature:reader:testDebugUnitTest` executed. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew build --no-daemon -Pfastmd.useChinaMavenMirror=true --stacktrace` | PASS | `BUILD SUCCESSFUL in 2m 45s`; build included debug/release assembly, lint, debug/release unit tests, and the wired Android renderer asset/request-blocking gates. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew :app:assembleDebug --no-daemon -Pfastmd.useChinaMavenMirror=true --stacktrace` | PASS | `BUILD SUCCESSFUL in 4s`; `:app:assembleDebug` completed directly after the aggregate build. |
| `ANDROID_SDK_ROOT='/Users/wangweiyang/Library/Android/sdk' /Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices` | BLOCKED for connected/device validation | Command ran, but the attached-device list was empty. |
| `ls -d /Users/wangweiyang/Library/Android/sdk/system-images/android-27` | BLOCKED for API 27 validation | No API 27 system image directory exists locally. Installed system images are Android 36 arm64 Google APIs / Play Store variants only. |
| `git diff --check -- android` | PASS | No whitespace errors were reported. |

## Preserved Blockers

- The default shell Java/JDK posture remains incomplete: `java -version` cannot
  locate a runtime and `JAVA_HOME` is unset. This batch used the Android Studio
  bundled JBR explicitly for Gradle.
- Default Google Maven online resolution remained unreliable in this batch: the
  initial online `./gradlew projects` invocation hung after daemon startup.
- Offline mode alone is insufficient for lint and some unit-test gates because
  required Android lint, AndroidX, and Compose compiler artifacts were not fully
  cached before the mirror-backed retry.
- L12 `./gradlew :app:connectedDebugAndroidTest` remains open because no Android
  device or emulator is attached.
- Android API 27 validation remains open because no API 27 system image or
  attached API 27 target is present.
- Android low-memory/small-screen profile validation remains open because no
  matching device or emulator is attached.
- Android modern-device validation remains open because no attached device or
  emulator is available.

## Supervisor Checklist Recommendation

The supervising session can use this report as Android-lane evidence for marking
these Android L12 checklist items complete:

- L12: Run Android `./gradlew lint`.
- L12: Run Android `./gradlew build`.
- L12: Run Android `./gradlew :core:testDebugUnitTest`.
- L12: Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- L12: Run Android `./gradlew :app:assembleDebug`.

Do not mark Android connected-device, API 27, low-memory/small-screen, or
modern-device validation complete from this batch.
