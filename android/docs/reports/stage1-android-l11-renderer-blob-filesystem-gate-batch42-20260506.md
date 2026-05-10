# Stage 1 Android L11 Renderer Blob/Filesystem Request Gate Batch 42

Date: 2026-05-06
Worker: Android live lane
Scope: Android only

## Batch Summary

This batch tightened the Android conditional rich renderer request-blocking gate.
The current Stage 1 renderer remains native Compose fallback with no WebView and
no vendored JS/CSS/font asset tree, but any future isolated local renderer surface
now has explicit policy and regression coverage for two browser-only URL families
that must not be accepted by a Markdown renderer:

- `blob:` renderer requests.
- `filesystem:` renderer requests.
- Percent-encoded and double-percent-encoded forms of those request schemes in
  Kotlin request policy tests.
- Script-level synthetic asset fixtures that fail when packaged renderer assets
  contain `blob:` or `filesystem:` references.

## Android Files Changed

- `core/src/main/java/com/fastmd/mobile/core/render/RichRendererAssetPolicy.kt`
- `core/src/test/java/com/fastmd/mobile/core/render/RichRendererAssetPolicyTest.kt`
- `tools/audit_renderer_assets.sh`
- `tools/test_renderer_asset_audit.sh`

## Validation

Commands were run from `android/`.

| Command | Result | Evidence |
| --- | --- | --- |
| `bash -n tools/audit_renderer_assets.sh && bash -n tools/test_renderer_asset_audit.sh` | PASS | Shell syntax validation completed with no output. |
| `bash tools/audit_renderer_assets.sh` | PASS | Confirmed no Android WebView or `android.webkit` implementation, no React Native/Flutter/Cordova/equivalent runtime dependency, and no vendored JS/CSS/font renderer asset tree. |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Existing renderer audit fixtures passed, plus new `renderer assets with blob URLs fail` and `renderer assets with filesystem URLs fail` negative fixtures. |
| `./gradlew projects` | BLOCKED | The command exited before Gradle project evaluation: `Unable to locate a Java Runtime.` `JAVA_HOME` is empty, so JDK 17 is not available on PATH. |

## Checklist Evidence For Supervisor

- L11 `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
  - Android evidence: `RichRendererRequestPolicy` now explicitly blocks direct,
    percent-encoded, and double-percent-encoded `blob:` and `filesystem:` renderer
    requests.
  - Android evidence: `tools/test_renderer_asset_audit.sh` now fails synthetic
    app-local renderer assets containing `blob:` and `filesystem:` references.
  - Android evidence: `bash tools/test_renderer_asset_audit.sh` passed.

- L11 `Add local renderer packaging/offline tests if JS renderer assets are used.`
  - Refreshed Android evidence: `bash tools/test_renderer_asset_audit.sh` still
    passes the native fallback case and the synthetic app-local JS/CSS/font package
    case with SHA-256 manifest and metadata lock.

- L11 `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
  - Refreshed Android evidence: `bash tools/test_renderer_asset_audit.sh` still
    passes the positive manifest case and fails stale hash, missing manifest,
    malformed manifest, missing metadata lock, stale metadata hash, unlisted asset,
    escaping path, dot segment, percent escape, whitespace path, and self-hash cases.

## Blockers Kept Open

- Android Gradle validation remains blocked until JDK 17 is installed or exposed
  through `JAVA_HOME`/`PATH`.
- Because Gradle cannot start, `:core:testDebugUnitTest`, `lint`, `build`,
  `:feature:reader:testDebugUnitTest`, `:app:assembleDebug`, and connected device
  validation remain open.
