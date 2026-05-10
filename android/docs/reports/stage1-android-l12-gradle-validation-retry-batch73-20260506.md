# Stage 1 Android L12 Gradle Validation Retry Batch 73 - 2026-05-06

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
- Refresh Android performance-report evidence.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-gradle-validation-retry-batch73-20260506.md`

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
`2026-05-06` in the Android live lane.

- Default shell `java -version`: blocked with
  `Unable to locate a Java Runtime`.
- `JAVA_HOME`: unset in the default shell.
- Validation JVM used for Gradle retries:
  `/Applications/Android Studio.app/Contents/jbr/Contents/Home`.
- Gradle wrapper: `./gradlew`, Gradle `9.3.0`.
- Android SDK path from `local.properties`:
  `/Users/wangweiyang/Library/Android/sdk`.
- `adb devices`: command ran, but no attached devices or running emulators were
  listed.
- Android API 27 system image directory: absent at
  `/Users/wangweiyang/Library/Android/sdk/system-images/android-27`.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew projects --no-daemon` | PASS | Root project `fastmd-android` evaluated and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew lint --no-daemon` | BLOCKED | Gradle reached `:core:extractDebugAnnotations`, then failed resolving `com.android.tools.lint:lint-gradle:31.13.2` from `https://dl.google.com/dl/android/maven2/...` because the connection to `dl.google.com:443` timed out. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew build --no-daemon` | BLOCKED | Gradle reached `:feature:library:compileDebugKotlin`, then failed resolving `androidx.compose.compiler:compiler:1.5.14` from `https://dl.google.com/dl/android/maven2/...` because the connection to `dl.google.com:443` timed out. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew :core:testDebugUnitTest --no-daemon` | BLOCKED | Gradle reached `:core:testDebugUnitTest`, then failed resolving `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0` from `https://dl.google.com/dl/android/maven2/...` because the connection to `dl.google.com:443` timed out. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew :feature:reader:testDebugUnitTest --no-daemon` | BLOCKED | Gradle reached `:feature:reader:compileDebugKotlin`, then failed resolving `androidx.compose.compiler:compiler:1.5.14` from `https://dl.google.com/dl/android/maven2/...` because the connection to `dl.google.com:443` timed out. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew :app:assembleDebug --no-daemon` | BLOCKED | Gradle reached `:feature:library:compileDebugKotlin`, then failed resolving `androidx.compose.compiler:compiler:1.5.14` from `https://dl.google.com/dl/android/maven2/...` because the connection to `dl.google.com:443` timed out. |
| `bash tools/audit_performance_report.sh` | PASS | Printed Android runtime profile soft limits and fixture size matrix, then completed with `PASS: Android performance report audit completed.` |
| `/Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices` | BLOCKED for connected/device validation | `adb` is available, but the attached-device list is empty. |
| `ls -d /Users/wangweiyang/Library/Android/sdk/system-images/android-27` | BLOCKED for API 27 validation | The API 27 system image directory is absent locally. |

## Performance Report Snapshot

`bash tools/audit_performance_report.sh` printed:

- `WatchCompact softLimitBytes=262144`
- `LegacyEfficient softLimitBytes=1048576`
- `ModernStandard softLimitBytes=5242880`
- `LargeScreen softLimitBytes=5242880`
- Fixture matrix included `basic.md`, `rich-preview.md`, `long-1mb.md`,
  `large-5mb.md`, `huge-table.md`, `huge-code-block.md`, `remote-image.md`,
  and `local-image.md`.

## Preserved Blockers

- L12 `./gradlew lint` remains open because Google Maven timed out resolving
  `com.android.tools.lint:lint-gradle:31.13.2`.
- L12 `./gradlew build` remains open because Google Maven timed out resolving
  the Compose compiler artifact required by Compose feature modules.
- L12 `./gradlew :core:testDebugUnitTest` remains open because Google Maven
  timed out resolving AndroidX runtime artifacts after the test task was
  reached.
- L12 `./gradlew :feature:reader:testDebugUnitTest` remains open because Google
  Maven timed out resolving the Compose compiler artifact.
- L12 `./gradlew :app:assembleDebug` remains open because Google Maven timed
  out resolving the Compose compiler artifact.
- L12 `./gradlew :app:connectedDebugAndroidTest` remains open because no Android
  device or emulator is attached.
- Android API 27 validation remains open because no API 27 system image or
  attached API 27 target is present.
- Android low-memory/small-screen profile validation remains open because no
  matching device or emulator is attached.
- Android modern-device validation remains open because no attached device or
  emulator is available.
- The default shell Java/JDK posture remains incomplete: `java -version` cannot
  locate a runtime and `JAVA_HOME` is unset.

## Supervisor Checklist Recommendation

The supervising session can use this report as Android-lane evidence for:

- L12: Capture Android performance report.
- L13: Record validation reports under `android/docs/reports/`.

Do not mark Android lint, build, unit-test, assemble, connected-device, API 27,
low-memory/small-screen, or modern-device validation complete from this batch.
