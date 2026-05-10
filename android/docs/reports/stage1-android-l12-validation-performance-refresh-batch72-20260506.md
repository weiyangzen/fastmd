# Stage 1 Android L12 Validation And Performance Refresh Batch 72 - 2026-05-06

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
platform validation items. This batch stayed inside `android/**` and did not
edit shared `Docs/**`, `ios/**`, or `.cron/**`.

Primary targets:

- Run Android `./gradlew lint`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Refresh Android performance report evidence.
- Reconfirm minimum wrapper, SDK, manifest, fixture-render, API 27, and device
  validation posture.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-validation-performance-refresh-batch72-20260506.md`

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
`2026-05-06 13:22 CST`.

- Default shell `java -version`: blocked with `Unable to locate a Java Runtime`.
- `JAVA_HOME`: unset in the default shell.
- Validation JVM used for Gradle retry:
  `/Applications/Android Studio.app/Contents/jbr/Contents/Home`.
- Android Studio bundled JBR version: OpenJDK `21.0.6`.
- Gradle wrapper: `./gradlew`, Gradle `9.3.0`.
- Android SDK path from `local.properties`:
  `/Users/wangweiyang/Library/Android/sdk`.
- Android platform `android-35`: present.
- Android API 27 system image directory: absent at
  `/Users/wangweiyang/Library/Android/sdk/system-images/android-27`.
- `adb devices`: command ran, but no attached devices or running emulators were
  listed.

Note: Gradle compile-backed tasks can start when `JAVA_HOME` is pointed at the
Android Studio bundled JBR, but the local default shell still has no Java
runtime configured and no JDK 17 path is available through the default
environment. Kotlin compilation also logs a daemon failure caused by
`java.lang.IllegalArgumentException: 25.0.1`, then falls back to non-daemon
compilation before reaching dependency resolution.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew projects --no-daemon` | PASS | Root project `fastmd-android` evaluated and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew lint --no-daemon` | BLOCKED | Gradle reached `:core:extractDebugAnnotations`, then failed resolving `com.android.tools.lint:lint-gradle:31.13.2` from `https://dl.google.com/dl/android/maven2/...` because the connection to `dl.google.com:443` timed out. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew :core:testDebugUnitTest --no-daemon` | BLOCKED | Gradle reached `:core:testDebugUnitTest`, then failed resolving `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0` from `https://dl.google.com/dl/android/maven2/...` because the connection to `dl.google.com:443` timed out. |
| `bash tools/audit_performance_report.sh` | PASS | Printed Android runtime profile soft limits and fixture size matrix, then completed with `PASS: Android performance report audit completed.` |
| `bash tools/audit_stage1_manifest.sh` | PASS | Confirmed no `uses-permission` declarations, no broad storage, notification, or default `INTERNET` permission, `allowBackup=false`, cleartext disabled, only `MainActivity` exported, no Android WebView implementation, and release R8/resource-shrinking/non-debuggable posture. |
| `bash tools/audit_rich_fixture_render.sh` | PASS | Confirmed rich fixture coverage for Stage 1 Markdown block/inline features and native Kotlin/Compose rendering paths without a web app runtime. |
| `adb devices` | BLOCKED for connected/device validation | `adb` is available, but the attached-device list is empty. |
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
- L12 `./gradlew build` remains open behind the same Google Maven dependency
  resolution blocker until retried successfully.
- L12 `./gradlew :core:testDebugUnitTest` remains open because Google Maven
  timed out resolving AndroidX runtime dependencies after the task was reached.
- L12 `./gradlew :feature:reader:testDebugUnitTest` remains open; this batch did
  not rerun it after the confirmed shared Google Maven dependency-resolution
  blocker.
- L12 `./gradlew :app:assembleDebug` remains open behind the same Maven and
  compile-backed validation blocker until retried successfully.
- L12 `./gradlew :app:connectedDebugAndroidTest` remains open because no Android
  device or emulator is attached.
- Android API 27 validation remains open because no API 27 system image or
  attached API 27 target is present.
- Android low-memory/small-screen profile validation remains open because no
  matching device or emulator is attached.
- Android modern-device validation remains open because no attached device or
  emulator is available.
- The default shell Java/JDK posture remains incomplete: `java -version` cannot
  locate a runtime, `JAVA_HOME` is unset, and no default JDK 17 is configured.

## Supervisor Checklist Recommendation

The supervising session can use this report as Android-lane evidence for:

- L12: Capture Android performance report.
- L13: Record validation reports under `android/docs/reports/`.

Do not mark Android lint, build, unit-test, assemble, connected-device, API 27,
low-memory/small-screen, or modern-device validation complete from this batch.
