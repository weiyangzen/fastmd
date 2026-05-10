# Stage 1 Android L11 Renderer Manifest Hardening - 2026-05-05

## Scope

This bounded Android batch hardened the earliest still-open Android-owned L11 renderer validation gates:

- Add local renderer packaging/offline tests if JS renderer assets are used.
- Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
- Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.

The current Android implementation remains native Kotlin/Jetpack Compose and does not use `WebView`, `android.webkit`, React Native, Flutter, Cordova, CDN renderer assets, or vendored JS/CSS/font renderer assets. Mermaid and math remain native readable fallback surfaces.

## Implementation Evidence

- Hardened `tools/audit_renderer_assets.sh`.
  - Validates every `renderer-assets.sha256` line has a lowercase SHA-256 hash and a local relative asset path.
  - Rejects manifest paths that are absolute, URI-like, contain a colon, or escape the renderer asset root.
  - Rejects manifests that hash themselves.
  - Rejects manifests that reference missing files.
  - Requires every packaged renderer asset file to be listed in `renderer-assets.sha256`.
  - Scans JS/CSS/HTML renderer assets case-insensitively for remote URLs, CDN references, iframes, `srcdoc`, `javascript:` URLs, and `data:` URLs.
- Expanded `tools/test_renderer_asset_audit.sh`.
  - Keeps the existing native-fallback, app-local asset, missing-manifest, misplaced-asset, remote-reference, and WebView-marker checks.
  - Adds negative coverage for uppercase dangerous URL schemes.
  - Adds negative coverage for stale/tampered SHA-256 manifests.
  - Adds negative coverage for packaged renderer files omitted from the manifest.
  - Adds negative coverage for manifest paths that escape the renderer asset root.

## Validation

All commands were run from `/Users/wangweiyang/GitHub/fastmd/android` unless noted.

| Command | Result | Notes |
| --- | --- | --- |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Covered native fallback, valid app-local hashed assets, missing manifest failure, misplaced asset failure, remote subresource failure, uppercase dangerous URL failure, stale hash failure, unlisted packaged asset failure, escaping manifest path failure, and WebView marker failure. |
| `bash tools/audit_renderer_assets.sh` | PASS | Current Android tree has no `WebView`/`android.webkit` implementation, no React Native/Flutter/Cordova runtime dependency, and no vendored JS/CSS/font renderer asset tree. |
| `bash -n tools/audit_renderer_assets.sh && bash -n tools/test_renderer_asset_audit.sh` | PASS | Shell syntax checks passed. |
| `bash tools/audit_stage1_manifest.sh` | PASS | No permissions; no broad storage, notification, or default `INTERNET`; `allowBackup=false`; cleartext disabled; only document-entry `MainActivity` exported; no WebView implementation; release hardening remains enabled. |
| `./gradlew projects` | BLOCKED | The checked-in wrapper failed before project evaluation: `Unable to locate a Java Runtime.` |
| `gradle projects` | PASS | System Gradle resolved root project `fastmd-android` with `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `gradle :core:testDebugUnitTest` | BLOCKED | Gradle reached `:core:compileDebugKotlin` but dependency resolution failed because `dl.google.com` could not be reached for AndroidX artifacts. |
| `git diff --check -- android/tools/audit_renderer_assets.sh android/tools/test_renderer_asset_audit.sh` | PASS | No whitespace errors in this batch's script edits. |

## Supervisor Checklist Recommendation

The supervising session can use this report plus the hardened audit harness as Android-lane evidence for completing the three conditional L11 renderer checklist items:

- Add local renderer packaging/offline tests if JS renderer assets are used.
- Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
- Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.

Do not mark SDK/dependency/device-dependent Android validation gates complete from this batch. `lint`, `build`, `:core:testDebugUnitTest`, `:feature:reader:testDebugUnitTest`, `:app:assembleDebug`, connected tests, API 27 validation, low-memory/small-screen validation, and modern-device validation remain open until the Java/wrapper and dependency-resolution environment is healthy.
