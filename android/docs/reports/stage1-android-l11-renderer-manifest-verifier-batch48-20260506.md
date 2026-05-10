# Stage 1 Android L11 Renderer Manifest Verifier Batch 48

Date: 2026-05-06

## Scope

- Android-owned files only.
- Blueprint area: L11 conditional renderer asset packaging/offline, request-blocking, and manifest/hash verification gates.
- No iOS files, shared `Docs/**` checklist files, or `.cron/**` files were edited.
- The current Android implementation still has no vendored JS/CSS/font renderer asset tree and no Android `WebView`/`android.webkit` surface. Mermaid and math remain native readable fallback cards.

## Implementation Evidence

- `core/src/main/java/com/fastmd/mobile/core/render/RichRendererAssetPolicy.kt`
  - Added `LocalRendererAssetManifestEntry` and `LocalRendererAssetManifest`.
  - Parses `renderer-assets.sha256`-style manifest lines for future app-local renderer assets.
  - Requires lowercase SHA-256 hashes, clean paths relative to `fastmd-renderers/`, no path traversal, no percent-escaped paths, no duplicate paths, no self-hashing of `renderer-assets.sha256`, and mandatory inclusion of `renderer-assets.lock`.
  - Verifies packaged asset hash maps so missing, unlisted, or mismatched packaged renderer assets fail closed.
- `core/src/test/java/com/fastmd/mobile/core/render/RichRendererAssetPolicyTest.kt`
  - Added Kotlin unit coverage for valid JS/CSS/font/lock manifest verification.
  - Added negative cases for missing metadata lock, self-hashing manifests, malformed SHA lines, duplicate paths, escaping paths, percent-escaped paths, root-prefixed manifest paths, missing packaged assets, unlisted packaged assets, mismatched hashes, and accidental inclusion of `renderer-assets.sha256`.
  - Added strict rejection of leading/trailing whitespace in manifest paths.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `bash tools/audit_renderer_assets.sh` | PASS | Confirmed no Android `WebView` or `android.webkit` implementation, no React Native/Flutter/Cordova/equivalent web runtime dependency, and no vendored JS/CSS/font renderer asset tree. |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Confirmed native fallback passes; app-local JS/CSS/font renderer assets pass only with SHA-256 manifest and metadata lock; missing/misplaced/non-main/stale/unlisted/malformed/escaping assets fail; remote/content/protocol-relative/encoded/double-encoded/uppercase dangerous references fail; external navigation, meta refresh, forms, iframe/srcdoc, network-capable APIs, WebView markers, and React Native markers fail. |
| `JAVA_HOME="/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home" ANDROID_HOME="/Users/wangweiyang/Library/Android/sdk" ./gradlew projects --no-daemon` | PASS | Resolved root project `fastmd-android` and modules `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 16s`. |
| `JAVA_HOME="/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home" ANDROID_HOME="/Users/wangweiyang/Library/Android/sdk" ./gradlew :core:testDebugUnitTest --no-daemon` | BLOCKED | Kotlin first hit the existing stale daemon issue parsing Java `25.0.1`, then fell back to non-daemon compilation and reached `:core:testDebugUnitTest`. Runtime classpath resolution then failed downloading `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0` from `https://dl.google.com/dl/android/maven2/...` due connection timeouts. This is a dependency download blocker, not a Kotlin source assertion failure. |
| `JAVA_HOME="/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home" ANDROID_HOME="/Users/wangweiyang/Library/Android/sdk" ./gradlew :core:compileDebugUnitTestKotlin --no-daemon` | PASS | Main and test Kotlin sources compiled after the stale Java `25.0.1` Kotlin daemon failure fell back to non-daemon compilation; `BUILD SUCCESSFUL in 1m 3s`. |
| `JAVA_HOME="/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home" ANDROID_HOME="/Users/wangweiyang/Library/Android/sdk" ./gradlew stage1AndroidRendererAssetGates --no-daemon` | PASS | Gradle executed `:auditRendererAssets`, `:testRendererAssetAudit`, and `:stage1AndroidRendererAssetGates`; latest rerun after the final whitespace-path hardening patch ended `BUILD SUCCESSFUL in 38s`. |

## Supervisor Checklist Candidates

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
  - Android evidence: `tools/audit_renderer_assets.sh`, `tools/test_renderer_asset_audit.sh`, Gradle task `stage1AndroidRendererAssetGates`, and this report.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
  - Android evidence: no Android WebView surface is present; `RichRendererRequestPolicy` remains fail-closed for future renderer requests; the renderer audit fails if a WebView marker appears before a request-blocking gate exists.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
  - Android evidence: `LocalRendererAssetManifest`, new Kotlin unit coverage in `RichRendererAssetPolicyTest`, `tools/test_renderer_asset_audit.sh`, and Gradle `stage1AndroidRendererAssetGates`.
- L13: Record validation reports under `android/docs/reports/`.
  - Evidence: this report.

## Remaining Open Validation

- L12 Android `:core:testDebugUnitTest` remains open until Google Maven dependency resolution succeeds.
- Device-backed Android validation remains open; this batch did not run `:app:connectedDebugAndroidTest`, API 27 validation, low-memory/small-screen validation, or modern-device validation.
