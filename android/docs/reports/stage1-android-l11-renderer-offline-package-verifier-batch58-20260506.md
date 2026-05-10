# Stage 1 Android L11 Renderer Offline Package Verifier Batch 58

Date: 2026-05-06
Lane: FastMD Stage 1 Mobile Android live lane
Ownership: `android/**` only

## Scope

Advanced the earliest still-open Android-owned conditional L11 renderer gates:

- Add local renderer packaging/offline tests if JS renderer assets are used.
- Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
- Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.

Current Android implementation still has no `WebView`/`android.webkit` main-code renderer and no vendored
`fastmd-renderers` asset tree. This batch therefore strengthens the native core contract that future optional
local renderer assets must satisfy before they can be used.

## Implementation Evidence

- `core/src/main/java/com/fastmd/mobile/core/render/RichRendererAssetPolicy.kt`
  - Added `LocalRendererAssetPackageVerifier.verifyOfflinePackage(...)`.
  - Added `LocalRendererAssetManifest.verifyPackagedAssetBytes(...)`.
  - Added platform-local SHA-256 computation with `MessageDigest`, so tests and future packaging checks can verify
    bundled bytes directly instead of trusting caller-supplied hashes.
- `core/src/test/java/com/fastmd/mobile/core/render/RichRendererAssetPolicyTest.kt`
  - Added `localRendererPackageVerifierComputesPackagedHashesAndLocksMetadataOffline`.
  - Added `localRendererPackageVerifierRejectsMissingMismatchedAndUnlistedPackagedAssets`.
  - Coverage verifies manifest parsing, metadata lock matching, actual packaged-byte hash computation, and rejection
    of missing, tampered, or unlisted renderer assets.

## Validation

### Passed

Command:

```bash
bash tools/audit_renderer_assets.sh
```

Result: PASS

Key output:

```text
PASS: No Android WebView or android.webkit implementation is present.
PASS: No React Native, Flutter, Cordova, or equivalent web runtime dependency is present.
PASS: No vendored JS/CSS/font renderer asset tree is present; Android rich blocks use native fallback paths.
```

Command:

```bash
bash tools/audit_renderer_request_blocking.sh
```

Result: PASS

Key output:

```text
PASS: Renderer request policy is a first-class Android core contract.
PASS: Renderer request policy has an explicit iframe request class.
PASS: Renderer request policy has an explicit network-request block reason.
PASS: Renderer request policy has an explicit external-navigation block reason.
PASS: Renderer request policy has an explicit javascript: URL block reason.
PASS: Renderer request policy has an explicit data: URL block reason.
PASS: Renderer request policy has an explicit content URI block reason.
PASS: Renderer request policy has an explicit non-renderer-file block reason.
PASS: Unit tests cover allowlisting of bundled Android renderer assets.
PASS: Unit tests cover blocking renderer metadata lock file requests.
PASS: Unit tests cover remote and dangerous renderer request blocking.
PASS: Unit tests cover percent-encoded dangerous renderer requests.
PASS: Unit tests cover external navigation and iframe blocking.
PASS: No Android WebView or android.webkit implementation is present; rich Markdown uses native fallback surfaces.
```

Command:

```bash
bash tools/test_renderer_asset_audit.sh
```

Result: PASS

Key output:

```text
PASS: native fallback has no vendored renderer assets
PASS: app-local JS/CSS/font renderer assets verify with SHA-256 manifest
PASS: renderer assets require hash manifest
PASS: renderer assets require platform-local metadata lock
PASS: renderer asset metadata lock must be included in hash manifest
PASS: renderer assets outside app-local asset root fail
PASS: renderer assets outside app main source set fail
PASS: renderer assets with remote subresources fail
PASS: renderer assets with content URI subresources fail
PASS: renderer assets with protocol-relative remote URLs fail
PASS: renderer assets with percent-encoded remote URLs fail
PASS: renderer assets with double percent-encoded remote URLs fail
PASS: renderer assets with uppercase dangerous URLs fail
PASS: renderer assets with double percent-encoded javascript URLs fail
PASS: renderer assets with HTML entity-encoded dangerous URLs fail
PASS: renderer assets with HTML entity-encoded navigation markers fail
PASS: renderer assets with JavaScript unicode-escaped remote URLs fail
PASS: renderer assets with JavaScript braced unicode-escaped data URLs fail
PASS: renderer assets with JavaScript hex-escaped network APIs fail
PASS: renderer assets with blob URLs fail
PASS: renderer assets with filesystem URLs fail
PASS: renderer assets with external navigation APIs fail
PASS: renderer assets with HTML meta refresh navigation fail
PASS: renderer assets with HTML form navigation fail
PASS: renderer assets with iframe surfaces fail
PASS: renderer assets with srcdoc surfaces fail
PASS: renderer assets with network-capable browser APIs fail
PASS: renderer assets with XMLHttpRequest APIs fail
PASS: renderer assets with WebSocket APIs fail
PASS: renderer assets with EventSource APIs fail
PASS: renderer assets with sendBeacon APIs fail
PASS: renderer assets with dynamic import APIs fail
PASS: renderer assets with worker APIs fail
PASS: renderer assets with shared worker APIs fail
PASS: renderer assets with importScripts APIs fail
PASS: renderer assets with service worker APIs fail
PASS: renderer assets with stale SHA-256 manifest fail
PASS: renderer metadata lock with stale asset hash fails
PASS: packaged renderer assets missing from manifest fail
PASS: renderer asset manifest paths cannot escape asset root
PASS: renderer asset manifest paths cannot contain dot segments
PASS: renderer asset manifest paths cannot contain percent escapes
PASS: renderer asset manifest paths cannot contain whitespace
PASS: packaged renderer asset paths cannot contain whitespace even when unlisted
PASS: renderer asset manifest cannot hash itself
PASS: renderer asset manifest malformed lines fail
PASS: renderer asset metadata lock malformed lines fail
PASS: renderer asset metadata lock URL markers fail
PASS: renderer asset metadata lock encoded URL markers fail
PASS: WebView implementation fails until request-blocking tests exist
PASS: React Native runtime dependency fails the native Android lane audit
```

### Blocked

Command:

```bash
./gradlew projects
```

Result: BLOCKED

Exact blocker:

```text
The operation couldn’t be completed. Unable to locate a Java Runtime.
Please visit http://www.java.com for information on installing Java.
```

Command:

```bash
./gradlew :core:testDebugUnitTest
```

Result: BLOCKED

Exact blocker:

```text
The operation couldn’t be completed. Unable to locate a Java Runtime.
Please visit http://www.java.com for information on installing Java.
```

## Supervisor Checklist Candidates

The supervisor can use this report as Android evidence for the conditional L11 renderer gate cluster, subject to
its reconciliation policy:

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.

Evidence path:

- `android/docs/reports/stage1-android-l11-renderer-offline-package-verifier-batch58-20260506.md`

Platform Gradle validation remains open because this machine has no Java runtime available during this batch.
