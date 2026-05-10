# Stage 1 Android L12 Capture Validation Batch 26 - 2026-05-06

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned
validation cluster in `Docs/Stage1_Mobile_Blueprint.md`.

This batch focused on L12 platform validation evidence that can be advanced
without touching iOS or shared Docs:

- Retry Android Gradle project/lint/unit-test validation with the current local
  environment.
- Capture Android performance report evidence.
- Capture Android security audit report evidence.
- Capture rich fixture render report evidence.

No `ios/**`, shared `Docs/**`, or `.cron/**` files were edited.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
`2026-05-06 05:53:17 CST`.

Gradle commands used:

```text
JAVA_HOME=/Applications/Android Studio.app/Contents/jbr/Contents/Home
```

Environment observations:

- Default `java -version`: blocked with `Unable to locate a Java Runtime`.
- Android Studio bundled JBR: `openjdk version "21.0.6" 2025-01-21`.
- Android Gradle wrapper: present at `android/gradlew`, Gradle distribution
  `gradle-9.3.0-bin.zip`.
- Android SDK path: `sdk.dir=/Users/wangweiyang/Library/Android/sdk`.
- `adb devices`: `adb` is present at `/usr/local/bin/adb`, but no attached
  devices or running emulators were listed.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME=... ./gradlew projects --no-daemon` | PASS | Root project `fastmd-android` evaluated and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `JAVA_HOME=... ./gradlew lint --no-daemon` | BLOCKED | Gradle reached `:core:extractDebugAnnotations`, then failed resolving `com.android.tools.lint:lint-gradle:31.13.2` from `https://dl.google.com/dl/android/maven2/...` with `Connect timed out`. |
| `JAVA_HOME=... ./gradlew :core:testDebugUnitTest --no-daemon` | BLOCKED | Gradle reached `:core:testDebugUnitTest`, then failed resolving AndroidX runtime jars `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0` from Google Maven with `Connect timed out`. |
| `bash tools/audit_performance_report.sh` | PASS | Printed all Android performance profile soft limits and fixture size matrix, then `PASS: Android performance report audit completed.` |
| `bash tools/audit_stage1_manifest.sh` | PASS | Confirmed no broad storage, notification, default `INTERNET`, WebView implementation, or unexpected exported component; confirmed backup, cleartext, and release hardening posture. |
| `bash tools/audit_rich_fixture_render.sh` | PASS | Confirmed rich fixture coverage, render model block kinds, parser emissions, inline styles, native Compose reader paths, wide-surface containment, remote-image placeholder posture, and no web runtime. |
| `bash tools/audit_renderer_assets.sh` | PASS | Confirmed no Android WebView/android.webkit implementation, no React Native/Flutter/Cordova runtime, and no vendored JS/CSS/font asset tree because Android rich blocks use native fallback paths. |
| `JAVA_HOME=... ./gradlew stage1AndroidPerformanceReport stage1AndroidSecurityAuditReport stage1AndroidRichFixtureRenderReport --no-daemon` | PASS | Ran `:auditPerformanceReport`, `:auditSecurityReport`, and `:auditRichFixtureRenderReport`; build successful in 6s with 3 executed tasks. |

## Captured Report Evidence

`stage1AndroidPerformanceReport` confirmed:

- Runtime profiles expose bounded soft file-size limits:
  `WatchCompact=262144`, `LegacyEfficient=1048576`,
  `ModernStandard=5242880`, `LargeScreen=5242880`.
- The Android fixture matrix includes required basic, rich, long, large,
  huge-table, huge-code-block, remote-image, and local-image fixtures.
- The source audit passed the Android performance report gate.

`stage1AndroidSecurityAuditReport` confirmed:

- No `uses-permission` declarations are present.
- No broad storage, notification, or default `INTERNET` permission is present.
- `allowBackup=false` is documented in the app manifest.
- Cleartext traffic is disabled.
- Only the document-entry `MainActivity` is exported.
- No Android WebView implementation is present.
- Release build type enables R8 minify, resource shrinking, non-debuggable
  output, and app ProGuard rules.
- Renderer asset audit also confirms no web runtime dependency and no vendored
  JS/CSS/font renderer asset tree.

`stage1AndroidRichFixtureRenderReport` confirmed:

- The rich fixture covers headings, inline styles, links/autolinks/email,
  blockquotes, lists, task lists, tables, code fences, Mermaid fallback, inline
  and block math, images, safe video HTML, footnotes, details/summary, generic
  HTML fallback, mixed CJK/English/Japanese/Korean content, and escaped markers.
- The render model and parser expose the required native block kinds and inline
  styles.
- The Compose reader uses native renderer paths for ordinary Markdown blocks.
- Code/table/media surfaces are locally horizontally scrollable and do not force
  whole-page horizontal overflow.
- Remote images remain placeholders and Mermaid/math render as native readable
  source cards.
- Android rich rendering remains native Kotlin/Compose without WebView or a web
  app runtime.

## Blockers Preserved

- L12 `./gradlew lint` remains open because Google Maven timed out resolving
  `com.android.tools.lint:lint-gradle:31.13.2`.
- L12 `./gradlew :core:testDebugUnitTest` remains open because Google Maven
  timed out resolving AndroidX runtime jars.
- L12 `./gradlew build`, `./gradlew :feature:reader:testDebugUnitTest`,
  `./gradlew :app:assembleDebug`, and `./gradlew :app:connectedDebugAndroidTest`
  were not advanced in this batch. They remain behind the same Google Maven
  dependency-resolution risk, and connected tests also need an attached device
  or running emulator.
- Android API 27, low-memory/small-screen, and modern-device validation remain
  open because `adb devices` listed no attached target.
- The available Android Studio JBR is Java 21, not the requested JDK 17; Gradle
  did run with it for the captured gates, but final release validation should
  still use a JDK 17 runtime as documented.

## Supervisor Checklist Recommendation

The supervising session can use this report as Android-lane evidence to mark:

- L12: Capture Android performance report.
- L12: Capture Android security audit report.
- L12: Capture rich fixture render report.
- L13: Record validation reports under `android/docs/reports/`.

Do not mark Android lint, build, unit-test, assemble, connected-device, API 27,
low-memory/small-screen, or modern-device validation complete from this batch.
