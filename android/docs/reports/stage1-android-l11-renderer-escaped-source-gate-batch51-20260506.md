# Stage 1 Android L11 Renderer Escaped Source Gate Batch 51

Date: 2026-05-06
Lane: Android live lane
Ownership: `android/**`

## Scope

This batch hardens the Android-local renderer asset gate for future vendored
JS/CSS/HTML renderer assets. The app still uses native fallback rich-block
rendering today; no Android `WebView`, `android.webkit`, React Native, Flutter,
Cordova, remote WebView shell, CDN renderer, or packaged JS/CSS/font renderer
asset tree was introduced.

## Implementation

- Updated `tools/audit_renderer_assets.sh`.
  - Added canonicalized scanning for JavaScript-style escaped text before
    applying the existing dangerous URL and network API policies.
  - Decodes `\uXXXX`, `\u{...}`, and `\xHH` forms into a temporary scan buffer.
  - Fails if the decoded asset text reveals remote subresources, external
    navigation markers, iframe markers, `javascript:`, `data:`, `blob:`,
    `filesystem:`, `file:`, `content:`, or network-capable browser APIs.
- Updated `tools/test_renderer_asset_audit.sh`.
  - Added regression fixtures for JavaScript unicode-escaped remote URLs.
  - Added regression fixtures for braced-unicode escaped `data:` URLs.
  - Added regression fixtures for hex-escaped `fetch(...)`.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `bash tools/audit_renderer_assets.sh` | PASS | No Android WebView/android.webkit implementation, no React Native/Flutter/Cordova/equivalent web runtime dependency, and no vendored JS/CSS/font renderer asset tree were found. |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Native fallback, local hashed assets, missing/misplaced/stale/malformed/unlisted assets, dangerous raw/encoded/entity references, the new JavaScript escaped URL/API fixtures, WebView markers, and React Native markers behaved as expected. |
| `JAVA_HOME='/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home' ANDROID_HOME='/Users/wangweiyang/Library/Android/sdk' ./gradlew projects --no-daemon` | PASS | Gradle listed root project `fastmd-android` with `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 14s`. |
| `JAVA_HOME='/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home' ANDROID_HOME='/Users/wangweiyang/Library/Android/sdk' ./gradlew stage1AndroidRendererAssetGates --no-daemon` | PASS | Ran `:auditRendererAssets`, `:testRendererAssetAudit`, and `:stage1AndroidRendererAssetGates`; `BUILD SUCCESSFUL in 44s`. |

## Checklist Evidence For Supervisor

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
  - Android evidence: `tools/test_renderer_asset_audit.sh` now includes escaped-source negative fixtures and passes both directly and through `stage1AndroidRendererAssetGates`.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
  - Android evidence: the same regression harness continues to verify SHA-256 manifests, metadata locks, stale hashes, unlisted packaged assets, malformed manifests, and invalid renderer asset paths; this batch adds escape-canonicalized source scanning before those assets can pass.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used, Android portion.
  - Android evidence: no Android WebView surface exists; the audit still fails if `WebView` or `android.webkit` appears in main Android code before a separate request-blocking gate exists.

## Notes

- This batch did not run `lint`, `build`, `assembleDebug`, `connectedDebugAndroidTest`, or device/API validation because it was intentionally scoped to the renderer asset gate. The minimum Gradle validation (`projects`) and the relevant Gradle aggregate gate both passed.
