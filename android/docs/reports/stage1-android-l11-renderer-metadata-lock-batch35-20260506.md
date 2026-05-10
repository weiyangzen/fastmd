# Stage 1 Android L11 Renderer Metadata Lock Batch 35 - 2026-05-06

## Scope

This batch advanced the earliest still-open Android-owned L11 renderer gate without touching iOS or authoritative `Docs/` checklist files.

The current Android implementation remains native Kotlin/Jetpack Compose. No Android `WebView`, `android.webkit`, React Native, Flutter, Cordova, remote WebView shell, or vendored JS/CSS/font renderer asset tree is present. Mermaid and math continue to use native readable fallback cards.

## Implementation

- Hardened `android/tools/audit_renderer_assets.sh` so future vendored renderer assets under `app/src/main/assets/fastmd-renderers/` must include:
  - `renderer-assets.sha256` with every packaged renderer asset and the metadata lock.
  - `renderer-assets.lock` with one line per renderer asset.
  - Asset path, upstream name, upstream version, license notes, and SHA-256 hash in each metadata-lock line.
  - Matching hash evidence between the metadata lock, SHA-256 manifest, and packaged asset bytes.
- Kept the native-fallback path passing when no vendored JS/CSS/font renderer asset tree is present.
- Extended `android/tools/test_renderer_asset_audit.sh` with regression coverage for:
  - passing app-local JS/CSS/font renderer assets with SHA-256 manifest and metadata lock;
  - missing metadata lock;
  - stale metadata-lock asset hash;
  - malformed metadata-lock lines;
  - existing remote URL, encoded URL, dangerous scheme, navigation API, network-capable API, misplaced asset, stale manifest, path traversal, malformed manifest, WebView marker, and React Native dependency cases.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `bash -n tools/audit_renderer_assets.sh tools/test_renderer_asset_audit.sh` | PASS | Shell syntax check completed with exit code 0. |
| `bash tools/audit_renderer_assets.sh` | PASS | Reported no Android WebView/android.webkit implementation, no React Native/Flutter/Cordova/equivalent web runtime dependency, and no vendored JS/CSS/font renderer asset tree; native fallback remains valid. |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Positive and negative regression matrix passed, including the new platform-local metadata lock, stale metadata hash, and malformed metadata lock cases. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew projects --no-daemon` | PASS | Gradle wrapper discovered `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 4s`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew stage1AndroidRendererAssetGates --no-daemon` | PASS | Ran `auditRendererAssets` and `testRendererAssetAudit`; `BUILD SUCCESSFUL in 18s`. |

## Checklist Evidence

The supervising session can use this report as Android evidence for these L11 checklist items:

- `Add local renderer packaging/offline tests if JS renderer assets are used.`
  - Evidence: `tools/test_renderer_asset_audit.sh` verifies native fallback when no assets are present and verifies app-local offline JS/CSS/font renderer assets when future assets are present.
- `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
  - Evidence: `tools/audit_renderer_assets.sh` and `tools/test_renderer_asset_audit.sh` now require both `renderer-assets.sha256` and `renderer-assets.lock`, validate clean app-local paths, require upstream/version/license metadata, and compare SHA-256 values against packaged bytes.

The Android portion of the WebView request-blocking condition remains guarded by existing fail-closed audit behavior: a future Android `WebView` or `android.webkit` implementation still fails `stage1AndroidRendererAssetGates` until request-blocking implementation and tests exist.

## Remaining Validation Notes

This batch did not run full Android `lint`, `build`, module unit-test, `assembleDebug`, connected device, API 27 emulator, low-memory/small-screen, or modern-device validation gates. Those L12 platform validation items should remain open unless covered by separate reports.
