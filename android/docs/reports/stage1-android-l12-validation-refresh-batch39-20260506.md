# Stage 1 Android L12 Validation Refresh Batch 39

Date: 2026-05-06
Lane: FastMD Stage 1 Mobile Android live lane
Scope: Android-owned validation evidence only. No `ios/**`, shared `Docs/**`, or `.cron/**` edits.

## Batch Selection

The earliest still-open Android-owned cluster in the authoritative blueprint is L11/L12 validation. Earlier Android implementation clusters already have Android-local source and report evidence, so this batch refreshed the small validation slice that can run locally:

- Renderer asset packaging/offline/hash/request-blocking gate evidence.
- Android project graph validation through both system Gradle and the checked-in wrapper with an explicit local JBR.
- Source-level Android performance, manifest/security, and rich fixture render reports.
- Exact blocker for default wrapper execution from the current shell.

## Environment

- Repository: `/Users/wangweiyang/GitHub/fastmd`
- Android project: `/Users/wangweiyang/GitHub/fastmd/android`
- Timestamp: `20260506-081345 CST`
- Default shell `java -version`: blocked.
- Default wrapper `./gradlew projects`: blocked by missing Java runtime from the default shell.
- System Gradle path: `/usr/local/bin/gradle`
- Wrapper fallback used for one real wrapper validation: `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"`

Default shell Java blocker:

```text
The operation couldn’t be completed. Unable to locate a Java Runtime.
Please visit http://www.java.com for information on installing Java.
```

## Commands And Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version && ./gradlew --version` | BLOCKED | The default shell cannot locate a Java Runtime, so wrapper-based Gradle commands fail unless `JAVA_HOME` is provided. |
| `./gradlew projects` | BLOCKED | Same missing Java Runtime blocker from the default shell. |
| `./gradlew lint` | BLOCKED | Same missing Java Runtime blocker from the default shell before Gradle configuration. |
| `gradle projects` | PASS | System Gradle evaluated root project `fastmd-android` and discovered `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 2s`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew projects --no-daemon` | PASS | Checked-in wrapper evaluated the same Android project graph; `BUILD SUCCESSFUL in 3s`. |
| `bash tools/audit_renderer_assets.sh` | PASS | Confirmed no Android `WebView` or `android.webkit` implementation, no React Native/Flutter/Cordova/equivalent web runtime dependency, and no vendored JS/CSS/font renderer asset tree. Android rich blocks use native fallback paths. |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Confirmed native fallback passes with no renderer assets; synthetic app-local JS/CSS/font assets pass only with valid SHA-256 manifest and metadata lock; missing/misplaced/non-main/stale/unlisted/malformed/escaping asset cases fail; remote/content/protocol-relative/encoded/double-encoded/dangerous references fail; external navigation, meta refresh, forms, network-capable browser APIs, WebView markers, and React Native markers fail. |
| `gradle stage1AndroidRendererAssetGates` | PASS | Ran `:auditRendererAssets`, `:testRendererAssetAudit`, and `:stage1AndroidRendererAssetGates`; `BUILD SUCCESSFUL in 15s`. |
| `bash tools/audit_stage1_manifest.sh` | PASS | Confirmed no permissions; no broad storage, notification, or default `INTERNET`; `allowBackup=false`; cleartext disabled; only document-entry `MainActivity` exported; no WebView implementation; release build type uses R8/resource shrinking/non-debuggable output and app ProGuard rules. |
| `bash tools/audit_performance_report.sh` | PASS | Printed Android performance profile limits and fixture size matrix; completed with `PASS: Android performance report audit completed.` |
| `bash tools/audit_rich_fixture_render.sh` | PASS | Confirmed rich fixture coverage, parser/render model block kinds, inline style coverage, native reader paths, local horizontal scroll constraints, remote image privacy placeholder, Mermaid/math native source-card fallback, and no web app runtime. |

## Source-Level Audit Highlights

Renderer asset gate output:

```text
PASS: No Android WebView or android.webkit implementation is present.
PASS: No React Native, Flutter, Cordova, or equivalent web runtime dependency is present.
PASS: No vendored JS/CSS/font renderer asset tree is present; Android rich blocks use native fallback paths.
PASS: app-local JS/CSS/font renderer assets verify with SHA-256 manifest
PASS: WebView implementation fails until request-blocking tests exist
PASS: React Native runtime dependency fails the native Android lane audit
```

Manifest/security audit output:

```text
PASS: No uses-permission declarations are present.
PASS: No broad storage, notification, or default INTERNET permission is present.
PASS: App manifest documents Stage 1 backup posture with allowBackup=false.
PASS: App manifest disables cleartext network traffic.
PASS: Only the document-entry MainActivity is exported.
PASS: No Android WebView implementation is present in Stage 1 main code.
PASS: Release build type enables R8 minify, resource shrinking, non-debuggable output, and app ProGuard rules.
```

Rich fixture render audit completed with native coverage for:

- H1-H6, paragraphs, emphasis, strikethrough, inline code, mark, subscript, superscript, links, autolinks, email autolinks.
- Blockquote, unordered/ordered/task lists, tables, fenced code, Mermaid fallback, inline/block math fallback, images, safe video HTML placeholder, footnotes, details/summary, generic HTML fallback, mixed CJK/English/Japanese/Korean, and escaped markers.
- Native Compose reader paths including `MarkdownBlockPreview`, `BlockquoteBlock`, `ListBlock`, `TableBlock`, `CodeLikeBlock`, `ImageBlock`, `MediaPlaceholderBlock`, `FootnoteBlock`, `DetailsBlock`, `SafeFallbackBlock`, and `toAnnotatedString`.

## L12 Status From This Batch

- Android `./gradlew lint`: keep open. Attempted from the default shell and blocked by missing Java Runtime before configuration.
- Android `./gradlew build`: keep open. Not run after `./gradlew lint` showed the default wrapper Java blocker.
- Android `./gradlew :core:testDebugUnitTest`: keep open. Not run in this batch because the default wrapper Java blocker still prevents deeper wrapper gates.
- Android `./gradlew :feature:reader:testDebugUnitTest`: keep open. Not run for the same wrapper blocker.
- Android `./gradlew :app:assembleDebug`: keep open. Not run for the same wrapper blocker.
- Android `./gradlew :app:connectedDebugAndroidTest`: keep open. No device validation was attempted in this batch.
- Android API 27 validation: keep open. No API 27 device/emulator validation was performed in this batch.
- Android low-memory/small-screen profile validation: keep open. Source-level performance profile audit passed, but no target device/emulator validation was performed.
- Android modern device validation: keep open. No target device/emulator validation was performed.
- Capture Android performance report: supervisor can count this batch as refreshed Android-local source-level evidence via `bash tools/audit_performance_report.sh`.
- Capture Android security audit report: supervisor can count this batch as refreshed Android-local source-level evidence via `bash tools/audit_stage1_manifest.sh` and `bash tools/audit_renderer_assets.sh`.
- Capture rich fixture render report: supervisor can count this batch as refreshed Android-local source-level evidence via `bash tools/audit_rich_fixture_render.sh`.

## Supervisor Checklist Recommendations

The supervising session can use this report as Android-lane evidence for:

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
  - Evidence: `android/tools/test_renderer_asset_audit.sh` and Gradle task `stage1AndroidRendererAssetGates` passed. Synthetic app-local JS/CSS/font assets pass only with valid local packaging, SHA-256 manifest, and metadata lock.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
  - Android evidence: no Android WebView surface exists; the renderer audit fails a synthetic WebView implementation until request-blocking coverage exists; `android/core/src/test/java/com/fastmd/mobile/core/render/RichRendererAssetPolicyTest.kt` covers blocked network, navigation, `javascript:`, `data:`, `content:`, iframe, unknown-scheme, percent-encoded, and non-renderer-file decisions.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
  - Evidence: `android/tools/test_renderer_asset_audit.sh` verifies valid synthetic renderer manifests and fails missing, stale, malformed, escaping, unlisted, misplaced, and non-main-source-set asset cases; Gradle task `stage1AndroidRendererAssetGates` passed.
- L12: Capture Android performance report.
  - Evidence: `bash tools/audit_performance_report.sh` passed in this batch.
- L12: Capture Android security audit report.
  - Evidence: `bash tools/audit_stage1_manifest.sh` and `bash tools/audit_renderer_assets.sh` passed in this batch.
- L12: Capture rich fixture render report.
  - Evidence: `bash tools/audit_rich_fixture_render.sh` passed in this batch.
- L13: Record validation reports under `android/docs/reports/`.
  - Evidence: this report.

Do not mark Android L12 lint/build/unit/assemble/connected-device/API 27/low-memory/modern-device validation complete from this batch.
