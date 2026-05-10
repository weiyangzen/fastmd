# Stage 1 Android L11 Renderer Audit Tests - 2026-05-05

## Scope

This bounded Android batch advanced the earliest still-open Android-owned L11 renderer validation items:

- Add local renderer packaging/offline tests if JS renderer assets are used.
- Add WebView request-blocking tests if local JS renderer surfaces are used.
- Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.

The current Android implementation still does not use Android `WebView`, `android.webkit`, vendored JS/CSS/font renderer assets, React Native, Flutter, Cordova, CDN assets, or remote renderer subresources. Mermaid and math stay on native fallback render surfaces.

## Implementation Evidence

- Added JVM contract coverage in `core/src/test/java/com/fastmd/mobile/core/render/RichRendererAssetPolicyTest.kt`.
  - Native fallback renderer policies use no vendored assets and keep network/navigation blockers enabled.
  - Vendored renderer paths must be local relative paths under `fastmd-renderers/`.
  - Optional asset hashes must be 64 lowercase SHA-256 hex characters.
  - Rich renderer surfaces cannot opt out of blocking network requests, external navigation, `javascript:` URLs, `data:` URLs, iframes, or remote subresources.
- Added `tools/test_renderer_asset_audit.sh`.
  - Creates isolated temporary Android project trees.
  - Verifies the audit passes when no renderer asset tree exists.
  - Verifies app-local renderer assets pass only with a valid `renderer-assets.sha256` manifest.
  - Verifies missing manifests, misplaced renderer assets, remote subresource references, and WebView implementation markers fail closed.
- Updated `tools/audit_renderer_assets.sh` to support `FASTMD_ANDROID_AUDIT_ROOT` so the audit can be tested against isolated temporary roots while preserving the default current-repo behavior.

## Validation

All commands were run from `/Users/wangweiyang/GitHub/fastmd/android` unless noted.

| Command | Result | Notes |
| --- | --- | --- |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Covered native fallback, app-local SHA manifest success, missing manifest failure, misplaced asset failure, remote subresource failure, and WebView marker failure. |
| `bash tools/audit_renderer_assets.sh` | PASS | Current Android tree has no WebView/android.webkit implementation, no React Native/Flutter/Cordova runtime dependency, and no vendored JS/CSS/font renderer asset tree. |
| `bash -n tools/audit_renderer_assets.sh && bash -n tools/test_renderer_asset_audit.sh` | PASS | Shell syntax check passed. |
| `bash tools/audit_stage1_manifest.sh` | PASS | No `uses-permission`; no broad storage, notification, or default `INTERNET`; `allowBackup=false`; cleartext disabled; only document-entry `MainActivity` exported; no WebView implementation; release hardening remains enabled. |
| `gradle projects` | PASS | Resolved root project `fastmd-android` with `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `gradle :core:testDebugUnitTest` | BLOCKED | Android SDK location is missing. Gradle requested `ANDROID_HOME` or `sdk.dir` in `/Users/wangweiyang/GitHub/fastmd/android/local.properties`. |
| `git diff --check -- android` | PASS | No whitespace errors in Android changes. |

## Supervisor Checklist Recommendation

The supervising session can use this report plus the implementation files above as Android-lane evidence for completing the three conditional L11 renderer checklist items:

- Add local renderer packaging/offline tests if JS renderer assets are used.
- Add WebView request-blocking tests if local JS renderer surfaces are used.
- Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.

Do not mark SDK-dependent Android Gradle or device validation gates complete from this batch. `:core:testDebugUnitTest`, lint, build, assemble, connected tests, API 27 validation, low-memory/small-screen validation, and modern-device validation remain blocked until Android SDK/wrapper/device setup is available.
