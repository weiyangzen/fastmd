# Stage 1 Android L12 Live Validation Batch 9 - 2026-05-06

## Scope

This Android-owned batch advanced L12 platform validation evidence without editing
the shared blueprint or todo snapshot. The batch focused on the earliest remaining
Android validation surfaces that can be evaluated locally:

- Android Gradle entrypoint and system Gradle fallback preflight.
- Android performance report capture.
- Android security audit report capture.
- Rich fixture render report capture.
- Device/API 27 availability preflight.

## Environment

- Working directory: `android/`
- Gradle entrypoint attempted: `./gradlew`
- System Gradle fallback attempted: `gradle`
- Android SDK location from `local.properties`: `/Users/wangweiyang/Library/Android/sdk`
- Installed SDK platforms visible locally: `android-31`, `android-32`, `android-33`, `android-34`, `android-35`, `android-36`
- API 27 system image directory check: `/Users/wangweiyang/Library/Android/sdk/system-images/android-27` is missing
- `adb` path: `/usr/local/bin/adb`
- Attached devices from `adb devices`: none

## Command Results

| Command | Result | Evidence |
| --- | --- | --- |
| `./gradlew projects` | BLOCKED | macOS Java launcher returned: `Unable to locate a Java Runtime.` Gradle did not start. |
| `gradle projects` | PASS | System Gradle resolved root project `fastmd-android` and modules `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; build successful in 11s. |
| `gradle lint` | BLOCKED | Project evaluation and early Android tasks ran, then `:core:compileDebugKotlin` could not resolve `org.jetbrains.kotlin:kotlin-script-runtime:1.9.24` from Maven Central because the server returned HTTP 403 Forbidden. |
| `java -version` | BLOCKED | macOS Java launcher returned: `Unable to locate a Java Runtime.` |
| `/usr/libexec/java_home -V` | BLOCKED | macOS Java launcher returned: `Unable to locate a Java Runtime.` |
| `adb devices` | BLOCKED for device validation | Command ran, but listed no attached device or emulator. |
| `ls /Users/wangweiyang/Library/Android/sdk/system-images/android-27` | BLOCKED for API 27 validation | Directory is missing. |
| `bash tools/audit_performance_report.sh` | PASS | Printed profile limits and fixture matrix, ending with `PASS: Android performance report audit completed.` |
| `bash tools/audit_stage1_manifest.sh` | PASS | Manifest audit passed permission, backup, cleartext, exported component, WebView absence, and release hardening checks. |
| `bash tools/audit_renderer_assets.sh` | PASS | No Android WebView/android.webkit implementation, no web runtime dependency, and no vendored JS/CSS/font renderer asset tree were found. |
| `bash tools/audit_rich_fixture_render.sh` | PASS | Rich fixture, parser, render model, Compose reader, native fallback, and no-web-runtime checks passed. |

## Passed Audit Detail

### Performance Report

`bash tools/audit_performance_report.sh` captured the Android source-level
performance posture. It verified the expected runtime profile limits and fixture
matrix, then completed successfully:

- `WatchCompact softLimitBytes=262144`
- `LegacyEfficient softLimitBytes=1048576`
- `ModernStandard softLimitBytes=5242880`
- `LargeScreen softLimitBytes=5242880`
- `PASS: Android performance report audit completed.`

### Security Audit

The Android security audit was captured with both manifest and renderer-asset
checks:

- `bash tools/audit_stage1_manifest.sh`
- `bash tools/audit_renderer_assets.sh`

The combined evidence covers permission exclusions, backup posture,
cleartext-network posture, exported component scope, WebView absence,
web-runtime exclusions, and local renderer asset/hash/offline requirements.

### Rich Fixture Render Report

`bash tools/audit_rich_fixture_render.sh` verified the Stage 1 rich Markdown
fixture surface against Android-native parser and Compose renderer paths. The
audit passed coverage for headings, inline emphasis/code/mark/sub/sup, links,
blockquote, lists, task lists, tables, code fences, Mermaid/math native fallback,
images, video placeholder, footnotes, details, generic HTML fallback, CJK mixed
content, wide-surface containment, remote-image placeholder posture, and absence
of a web app runtime.

## Blockers Preserved

The following L12 Android gates must remain open:

- `./gradlew lint`
- `./gradlew build`
- `./gradlew :core:testDebugUnitTest`
- `./gradlew :feature:reader:testDebugUnitTest`
- `./gradlew :app:assembleDebug`
- `./gradlew :app:connectedDebugAndroidTest`
- Android API 27 validation
- Android low-memory/small-screen profile validation
- Android modern device validation

Primary blockers:

- No Java runtime/JDK 17 is discoverable by `java`, `/usr/libexec/java_home`, or
  `./gradlew`.
- System `gradle` can evaluate the project graph, but Kotlin dependency resolution
  for compile-backed gates is blocked by Maven Central HTTP 403 for
  `org.jetbrains.kotlin:kotlin-script-runtime:1.9.24`.
- No Android device or emulator is attached.
- No API 27 system image directory exists under the configured Android SDK.

## Supervisor Checklist Recommendation

The supervising session can mark these Android-owned L12 checklist items complete
using this report as evidence:

- Capture Android performance report.
- Capture Android security audit report.
- Capture rich fixture render report.

Do not mark Gradle build/test/lint/assemble, connected-device, API 27,
low-memory/small-screen, or modern-device validation complete from this batch.
