# Stage 1 Android L11 Renderer Entity-Encoding Gate Batch 46

Date: 2026-05-06

## Scope

- Android-owned implementation only.
- Blueprint area: L11 automated test gates for optional local JS/CSS/font rich renderer assets and WebView request-blocking posture.
- No iOS files, shared Docs checklists, or `.cron` files were edited.

## Implementation

- Hardened `tools/audit_renderer_assets.sh` so future vendored rich renderer `.js`, `.css`, and `.html` assets fail the audit when dangerous URL schemes, remote subresource markers, or navigation APIs are hidden behind decimal or hexadecimal HTML entity encodings.
- Added regression fixtures to `tools/test_renderer_asset_audit.sh` for:
  - `javascript&#x3a;...` and `https&#58;//...` inside a local renderer HTML asset.
  - `window&#46;location` navigation marker inside a local renderer HTML asset.

The current Android app still contains no WebView or vendored JS/CSS/font renderer asset tree. Mermaid/math rich blocks remain on native fallback paths.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `bash tools/audit_renderer_assets.sh` | PASS | No Android `WebView`/`android.webkit`, no React Native/Flutter/Cordova/equivalent web runtime dependency, and no vendored JS/CSS/font renderer asset tree were found. |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Existing renderer asset audit self-tests passed, plus new cases for HTML entity-encoded dangerous URLs and navigation markers. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew projects --no-daemon` | PASS | Gradle resolved the Android project hierarchy: `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 3s`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew stage1AndroidRendererAssetGates --no-daemon` | PASS | Ran `:auditRendererAssets`, `:testRendererAssetAudit`, and `:stage1AndroidRendererAssetGates`; `BUILD SUCCESSFUL in 26s`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :core:testDebugUnitTest --tests 'com.fastmd.mobile.core.render.RichRendererAssetPolicyTest' --no-daemon` | BLOCKED | Kotlin daemon first reported `IllegalArgumentException: 25.0.1` and fell back to non-daemon compilation. The task then failed resolving runtime dependencies from Google Maven: `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0` downloads from `https://dl.google.com/dl/android/maven2/...` timed out connecting to `dl.google.com:443`. |

## Checklist Evidence For Supervisor

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
  - Evidence: `tools/test_renderer_asset_audit.sh` continues to pass native fallback, app-local JS/CSS/font asset packaging, manifest, metadata lock, stale hash, unlisted asset, and misplaced asset cases.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used, Android portion.
  - Evidence: `tools/audit_renderer_assets.sh` fails closed when Android `WebView`/`android.webkit` implementation markers are present before request-blocking coverage exists; current app has no WebView surface.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
  - Evidence: `tools/test_renderer_asset_audit.sh` covers SHA-256 manifest success and negative cases for missing, stale, malformed, self-hashing, escaping, incomplete, and metadata-inconsistent manifests.
- Additional Android L11 hardening evidence from this batch:
  - Future vendored renderer assets now fail the audit when dangerous schemes, remote subresources, or navigation APIs are HTML entity-encoded.

## Remaining Open Validation

- Android `:core:testDebugUnitTest` remains blocked by local network dependency resolution to Google Maven, not by this batch's source changes.
- Full Android L12 gates such as `lint`, `build`, `assembleDebug`, device/API 27 validation, connected tests, and device performance validation remain open until the environment can complete dependency resolution and device execution.
