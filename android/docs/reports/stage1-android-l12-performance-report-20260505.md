# Stage 1 Android L12 Performance Report - 2026-05-05

## Scope

This bounded Android live-lane batch advanced the L12 Android performance report
cluster and the Android-local validation documentation surface. It did not edit
`ios/**`, shared `Docs/**`, or `.cron/**`.

## Implementation Changes

- Moved reader search summarization out of the Compose input callback path:
  `MainActivity` now runs `ReaderSearchEngine.summarize` in a cancellable
  `lifecycleScope` job on `Dispatchers.Default`.
- Kept search input responsive by publishing a pending `ReaderUiState.Searching`
  state immediately while the background result count is computed.
- Added a search generation guard plus render model `sourceRevision` check so
  stale background search results cannot overwrite a newer document/search state.
- Moved local image stream reads and bounded bitmap decode out of composition:
  `ImageBlock` now uses `produceState` and dispatches `decodeBoundedBitmap` to
  `Dispatchers.IO`.
- Added `tools/audit_performance_report.sh`, an Android-local performance report
  audit that checks:
  - document load/save IO is dispatched away from the main thread;
  - Markdown parsing and reader search summarization run on `Dispatchers.Default`;
  - local image decode runs on `Dispatchers.IO`;
  - the reader uses block virtualization with stable block ids;
  - Compose reader surfaces do not parse/search Markdown directly;
  - expensive animation surfaces are absent before profile gating;
  - remote media is disabled by default in every Android runtime profile;
  - diagnostics expose redacted parse/render/search/save timing fields;
  - the platform fixture matrix required for performance validation is present.
- Added Gradle task `stage1AndroidPerformanceReport`, backed by the same script.
- Updated `android/README.md` with the performance report commands.

## Changed Android Files

- `android/app/src/main/java/com/fastmd/mobile/MainActivity.kt`
- `android/feature/reader/src/main/java/com/fastmd/mobile/feature/reader/ReaderScreen.kt`
- `android/build.gradle.kts`
- `android/tools/audit_performance_report.sh`
- `android/README.md`
- `android/docs/reports/stage1-android-l12-performance-report-20260505.md`

## Validation Results

All commands were run from `/Users/wangweiyang/GitHub/fastmd/android` unless noted.

| Command | Result | Evidence |
| --- | --- | --- |
| `bash tools/audit_performance_report.sh` | PASS | Confirmed Android source-level performance posture and printed runtime profile limits plus fixture matrix. Profile limits: WatchCompact 262144 bytes, LegacyEfficient 1048576 bytes, ModernStandard 5242880 bytes, LargeScreen 5242880 bytes. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle stage1AndroidPerformanceReport` | PASS | Ran `:auditPerformanceReport` and the aggregate `:stage1AndroidPerformanceReport` task successfully. |
| `bash tools/audit_stage1_manifest.sh` | PASS | No permissions, no broad storage/notification/default `INTERNET`, `allowBackup=false`, cleartext disabled, only `MainActivity` exported, no WebView implementation, and release hardening present. |
| `bash tools/audit_rich_fixture_render.sh` | PASS | Native rich fixture coverage audit passed for block/inline coverage, local wide-surface scrolling, remote image placeholder posture, Mermaid/math source-card fallback, and no web runtime. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew projects` | BLOCKED | Wrapper attempted to download `https://services.gradle.org/distributions/gradle-9.3.0-bin.zip` and failed with `java.net.UnknownHostException: services.gradle.org`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle projects` | PASS | System Gradle resolved root project `fastmd-android` with `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle :core:testDebugUnitTest --tests com.fastmd.mobile.core.search.ReaderSearchEngineTest` | BLOCKED | Reached `:core:compileDebugKotlin`, then failed resolving Android/Kotlin dependencies from `https://dl.google.com/dl/android/maven2/`; DNS reported `dl.google.com: nodename nor servname provided, or not known`. |
| `bash -n android/tools/audit_performance_report.sh` from repo root | PASS | Bash syntax validation completed with no output. |
| `git diff --check -- android` from repo root | PASS | No whitespace errors were reported. |

## Blockers Preserved

- Wrapper-backed Gradle validation remains blocked by DNS resolution for
  `services.gradle.org`.
- Compile-backed Android validation remains blocked by DNS resolution for
  `dl.google.com`, so the Kotlin/Compose changes in this batch have not been
  compile-validated locally.
- `./gradlew lint`, `./gradlew build`,
  `./gradlew :core:testDebugUnitTest`,
  `./gradlew :feature:reader:testDebugUnitTest`,
  `./gradlew :app:assembleDebug`, and
  `./gradlew :app:connectedDebugAndroidTest` remain open until wrapper and
  Android dependency resolution are available.
- API 27, low-memory/small-screen, and modern-device validation remain open
  because no debug APK can be assembled in this environment.
- Release-like measured performance timing remains blocked by the same
  dependency/device validation blockers. This report captures the Android-local
  source-level performance posture and fixture/profile matrix only.

## Supervisor Checklist Recommendation

The supervisor can use this report as Android-lane evidence for:

- L12: Capture Android performance report, if the source-level Android performance
  posture report plus Gradle-backed report task is accepted as the Stage 1 report
  capture while release-like timing remains blocked.
- L13: Update `android/README.md` with final build/test commands after Android
  skeleton lands.
- L13: Record validation reports under `android/docs/reports/`.

Do not mark Android lint/build/unit/assemble/connected-device/API 27/low-memory/
modern-device validation complete from this batch.
