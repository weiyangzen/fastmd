# Stage 1 Android L12 Report Capture Batch 31 - 2026-05-06

## Scope

This bounded Android live-lane batch advanced the next Android-owned open L12 validation surface without editing shared `Docs/**`, `ios/**`, or `.cron/**`.

The batch focused on source-level Android report capture gates that do not require a device or downloading additional AndroidX artifacts:

- Android performance report capture.
- Android security audit report capture.
- Rich fixture render report capture.

Compile-backed Gradle gates were attempted only far enough to identify the current environment blocker.

## Android Changes

- Added this Android-local validation report under `android/docs/reports/`.

No Android app source code changed in this batch.

## Validation Commands

All commands were run from `/Users/wangweiyang/GitHub/fastmd/android`.

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew projects` | PASS | Wrapper-backed Gradle evaluated root project `fastmd-android` and listed modules `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :core:testDebugUnitTest :feature:reader:testDebugUnitTest` | BLOCKED | `:core:testDebugUnitTest` failed before test execution while resolving `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0` from `https://dl.google.com/dl/android/maven2/`; both downloads timed out connecting to `dl.google.com:443`. `:feature:reader:testDebugUnitTest` was not reached after the `:core` resolution failure. |
| `bash tools/audit_performance_report.sh` | PASS | Printed Android performance profile limits for Watch Compact, Legacy Efficient, Modern Standard, and Large Screen; printed fixture size matrix; completed with `PASS: Android performance report audit completed.` |
| `bash tools/audit_stage1_manifest.sh && bash tools/audit_renderer_assets.sh` | PASS | Confirmed no permissions, no broad storage/notification/default `INTERNET`, `allowBackup=false`, cleartext disabled, only `MainActivity` exported, release minify/shrink/non-debuggable posture, no WebView/android.webkit implementation, no web runtime dependency, and no vendored JS/CSS/font renderer asset tree. |
| `bash tools/audit_rich_fixture_render.sh` | PASS | Confirmed fixture coverage for headings, inline styles, links, quotes, lists, task lists, tables, code fences, Mermaid/math fallback, images, video HTML placeholder, footnotes, details/summary, generic HTML fallback, mixed CJK text, escaped markers, native parser/render block kinds, Compose renderer paths, local horizontal scrolling for wide surfaces, remote-image placeholders, and no web runtime rendering. |
| `adb devices` | BLOCKED | `adb` ran successfully but listed no attached Android device or running emulator after `List of devices attached`. Connected/device validation remains open. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew stage1AndroidPerformanceReport stage1AndroidSecurityAuditReport stage1AndroidRichFixtureRenderReport` | PASS | Gradle executed `:auditPerformanceReport`, `:auditSecurityReport`, and `:auditRichFixtureRenderReport`; all report tasks completed and the build ended with `BUILD SUCCESSFUL`. |

## Blockers Preserved

- `./gradlew :core:testDebugUnitTest` is blocked by Maven artifact download timeouts from `dl.google.com`, not by a failing unit test assertion.
- `./gradlew :feature:reader:testDebugUnitTest` should remain open because the combined unit-test command stopped at the `:core` dependency resolution failure before reaching the reader test task.
- `./gradlew lint`, `./gradlew build`, and `./gradlew :app:assembleDebug` should remain open until AndroidX dependency resolution from `dl.google.com` is available or the missing artifacts are cached locally.
- `./gradlew :app:connectedDebugAndroidTest`, Android API 27 validation, low-memory/small-screen validation, and modern-device validation should remain open because no device or emulator was attached.

## Supervisor Checklist Recommendation

The supervising session can use this report as Android-lane evidence for:

- L12: Capture Android performance report.
- L12: Capture Android security audit report.
- L12: Capture rich fixture render report.
- L13: Record validation reports under `android/docs/reports/`.

Keep these Android L12 gates open from this batch:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.
