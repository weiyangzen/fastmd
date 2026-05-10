# Stage 1 Android L11 Renderer Metadata Request Lock Batch 53

Date: 2026-05-06 09:59 CST

## Scope

Android-only bounded batch for the L11 conditional renderer asset and request-blocking gates.

This batch keeps the current Stage 1 Android renderer posture native-first:

- No Android `WebView` or `android.webkit` implementation is present.
- No vendored JS/CSS/font renderer asset tree is present.
- Mermaid and math rich blocks continue to use native readable fallback surfaces.
- Future isolated renderer assets remain guarded by source-level and Gradle-wired packaging/offline/request-blocking gates.

## Implementation

Changed files:

- `android/core/src/main/java/com/fastmd/mobile/core/render/RichRendererAssetPolicy.kt`
- `android/core/src/test/java/com/fastmd/mobile/core/render/RichRendererAssetPolicyTest.kt`
- `android/tools/audit_renderer_request_blocking.sh`
- `android/docs/reports/stage1-android-l11-renderer-metadata-request-lock-batch53-20260506.md`

Behavior added:

- `RichRendererRequestPolicy` now blocks direct loads of both renderer metadata files:
  - `file:///android_asset/fastmd-renderers/renderer-assets.sha256`
  - `file:///android_asset/fastmd-renderers/renderer-assets.lock`
- The existing allowed surface remains limited to actual files under
  `file:///android_asset/fastmd-renderers/` with clean path segments.
- The request-blocking audit now requires a regression assertion for
  `renderer-assets.lock`, so future WebView-capable renderer work cannot
  accidentally expose local asset metadata as loadable renderer content.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `bash tools/audit_renderer_request_blocking.sh` | PASS | Confirmed request policy contract, bundled asset allowlist tests, metadata lock request blocking test, remote/dangerous request tests, percent-encoded dangerous request tests, external navigation/iframe tests, and no Android WebView implementation. |
| `bash tools/audit_renderer_assets.sh` | PASS | Confirmed no Android WebView/android.webkit implementation, no React Native/Flutter/Cordova runtime dependency, and no vendored JS/CSS/font renderer asset tree. |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Confirmed native fallback passes; app-local JS/CSS/font assets require valid SHA-256 manifest and metadata lock; negative cases fail for misplaced assets, missing metadata, remote/content/protocol-relative/encoded URLs, dangerous APIs, stale hashes, escaping paths, malformed manifests, WebView markers, and React Native runtime markers. |
| `./gradlew projects --no-daemon` | BLOCKED | With no `JAVA_HOME` in this shell, wrapper failed before Gradle startup: `Unable to locate a Java Runtime`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew projects --no-daemon` | PASS | Project hierarchy resolved: root `fastmd-android`, `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew :core:testDebugUnitTest --tests 'com.fastmd.mobile.core.render.RichRendererAssetPolicyTest' --no-daemon` | BLOCKED | Gradle reached `:core:testDebugUnitTest`, but runtime classpath resolution timed out downloading `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0` from `https://dl.google.com/dl/android/maven2/...`. Kotlin daemon also emitted an environment warning because an existing daemon saw Java `25.0.1`; fallback compilation continued before the Google Maven timeout blocked test execution. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew stage1AndroidRendererAssetGates --no-daemon` | PASS | Gradle executed `auditRendererAssets`, `auditRendererRequestBlocking`, and `testRendererAssetAudit`; build successful in 44s. |

## Blueprint Items For Supervisor Review

The supervisor can use this report as Android evidence for these conditional L11 items:

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
  - Evidence: `stage1AndroidRendererAssetGates` passed and `test_renderer_asset_audit.sh`
    covers native fallback, valid app-local asset packaging, metadata lock, SHA-256
    manifest verification, stale hashes, unlisted assets, misplaced source sets, and
    offline-only asset restrictions.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
  - Evidence: Android has no current WebView surface; `audit_renderer_request_blocking.sh`
    requires request policy tests and fails if WebView markers appear without routing
    through the blocking contract. The policy blocks network requests, external
    navigation, `javascript:`, `data:`, `blob:`, `filesystem:`, `content:`, iframes,
    non-renderer files, percent-encoded dangerous URLs, and renderer metadata files.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
  - Evidence: `RichRendererAssetPolicyTest` and `test_renderer_asset_audit.sh`
    both cover SHA-256 manifest parsing/verification and negative cases for missing,
    malformed, stale, unlisted, escaping, self-hashing, and metadata-lock omissions.

## Open Validation

The Android platform validation checklist remains open for full `lint`, `build`,
module unit tests, `assembleDebug`, connected tests, API 27, device profile, and
real-device validation gates. This batch only completed the Gradle project smoke
test and source-level renderer gate because deeper unit execution was blocked by
Google Maven dependency download timeouts.
