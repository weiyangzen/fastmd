# Stage 1 Android L12 Validation Refresh Batch 30 - 2026-05-06

## Scope

Android-only validation evidence for the earliest still-open Android-owned Stage 1
items in L12. No shared `Docs/**`, `ios/**`, or `.cron/**` files were edited.

This batch did not introduce implementation code. It refreshed Android-local
validation evidence after the wrapper and Android SDK were available locally.

## Environment

- Repository: `/Users/wangweiyang/GitHub/fastmd`
- Android root: `/Users/wangweiyang/GitHub/fastmd/android`
- Default shell Java: blocked, macOS reported no Java runtime for `java -version`
- Android Studio bundled JBR:
  - Path: `/Applications/Android Studio.app/Contents/jbr/Contents/Home`
  - Version: OpenJDK `21.0.6` build `21.0.6+-13391695-b895.109`
- Android SDK path from `local.properties`:
  - `sdk.dir=/Users/wangweiyang/Library/Android/sdk`
- Installed SDK platforms observed locally:
  - `android-31`, `android-32`, `android-33`, `android-34`, `android-35`, `android-36`

## Validation Commands

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED | macOS reported: `Unable to locate a Java Runtime.` |
| `./gradlew projects --no-daemon` | BLOCKED | With no `JAVA_HOME`, Gradle failed immediately because the shell Java runtime was unavailable. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew projects --no-daemon` | PASS | Gradle listed root project `fastmd-android` with `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; build successful in 4s. |
| `bash tools/audit_renderer_assets.sh` | PASS | No Android `WebView` or `android.webkit` implementation, no React Native/Flutter/Cordova web runtime dependency, and no vendored JS/CSS/font renderer asset tree. |
| `bash tools/audit_stage1_manifest.sh` | PASS | No `uses-permission`; no broad storage, notification, or default `INTERNET`; `allowBackup=false`; cleartext disabled; only document-entry `MainActivity` exported; no WebView implementation; release hardening posture enabled. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew :core:testDebugUnitTest --no-daemon --max-workers=1 -Dkotlin.compiler.execution.strategy=in-process` | BLOCKED | Reached `> Task :core:testDebugUnitTest`, then produced no further output or test result XML for about one minute; process was stopped to avoid leaving a dangling validation session. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew :core:testDebugUnitTest --tests 'com.fastmd.mobile.core.document.MarkdownDocumentTest' --no-daemon --max-workers=1 -Dkotlin.compiler.execution.strategy=in-process` | BLOCKED | A single filtered JUnit test also reached `> Task :core:testDebugUnitTest`, then produced no further output or result XML for about one minute; process was stopped. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew :feature:reader:testDebugUnitTest --no-daemon` | BLOCKED | Initial parallel run collided with the simultaneous `:core:testDebugUnitTest` run in shared Kotlin incremental build state (`NoSuchFileException`/`FileNotFoundException` under `core/build/...`), then stopped producing useful output; process was stopped and not counted as valid test evidence. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew :app:assembleDebug --no-daemon --max-workers=1 -Dkotlin.compiler.execution.strategy=in-process` | BLOCKED | Reached `> Task :feature:library:compileDebugKotlin`, then produced no further output for about 90 seconds; process was stopped to keep the batch bounded. |
| `bash tools/audit_performance_report.sh` | PASS | Source-level Android performance profile audit passed for Watch Compact, Legacy Efficient, Modern Standard, Large Screen limits and fixture matrix. |
| `bash tools/audit_rich_fixture_render.sh` | PASS | Rich fixture source audit passed for heading, inline, list, table, code, Mermaid/math native fallback, image/media placeholders, footnotes, details, HTML fallback, CJK/English coverage, and native Compose renderer paths. |

## Notes On Interrupted Runs

The first `:core:testDebugUnitTest` and `:feature:reader:testDebugUnitTest` attempt
was started in parallel. That was not valid evidence because both invocations touched
shared Kotlin incremental outputs under `core/build/**` at the same time. The later
serial `:core:testDebugUnitTest` and filtered single-test rerun avoided that
parallelism but still hung at the Gradle `testDebugUnitTest` task without generating
test result XML.

No Gradle wrapper, Gradle daemon, or Kotlin daemon process remained after the stopped
runs.

## Checklist Evidence For Supervisor

The following Android-owned blueprint items have fresh Android-local evidence:

- L12 `Run Android ./gradlew :app:assembleDebug`: still open; blocked by local Gradle/Kotlin task hang at `:feature:library:compileDebugKotlin`.
- L12 `Run Android ./gradlew :core:testDebugUnitTest`: still open; blocked by local Gradle JUnit task hang at `:core:testDebugUnitTest`.
- L12 `Run Android ./gradlew :feature:reader:testDebugUnitTest`: still open; first attempt invalid due parallel Gradle contention; should be rerun serially in a clean environment.
- L12 `Capture Android performance report`: supervisor can mark Android evidence complete if source-level audit evidence is acceptable; `bash tools/audit_performance_report.sh` passed in this report.
- L12 `Capture Android security audit report`: supervisor can mark Android evidence complete if source-level audit evidence is acceptable; `bash tools/audit_stage1_manifest.sh` and `bash tools/audit_renderer_assets.sh` passed in this report.
- L12 `Capture rich fixture render report`: supervisor can mark Android evidence complete if source-level audit evidence is acceptable; `bash tools/audit_rich_fixture_render.sh` passed in this report.
- L13 `Record validation reports under android/docs/reports/`: this report records the current Android validation evidence.

## Files Changed

- `android/docs/reports/stage1-android-l12-validation-refresh-batch30-20260506.md`
