# Stage 1 Android L11 Conditional Renderer Gates Batch 71

Date: 2026-05-06
Lane: Android live lane
Scope: L11 conditional renderer gates for local JS/CSS/font assets and WebView request blocking

## Batch Decision

The earliest still-open Android-owned checklist items are the conditional L11 renderer gates:

- Add local renderer packaging/offline tests if JS renderer assets are used.
- Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
- Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.

Android currently uses native fallback surfaces for Mermaid/math and does not package a vendored renderer asset tree. No Android WebView or `android.webkit` implementation is present. This batch therefore validates the conditional gates through the existing Android renderer policy contracts and audit harnesses instead of adding a JS renderer surface.

## Implementation Evidence

- `core/src/main/java/com/fastmd/mobile/core/render/RichRendererAssetPolicy.kt`
  - Defines `RichRendererAssetPolicy.nativeFallback(...)` with vendored assets disabled and all request/navigation/script/data/iframe/subresource blocking flags required.
  - Defines `RichRendererRequestPolicy` with explicit block reasons for network requests, external navigation, `javascript:`, `data:`, `blob:`, `filesystem:`, `content:`, non-renderer files, unknown schemes, and iframes.
  - Defines local renderer manifest, metadata lock, path validation, SHA-256 validation, and offline package verification contracts for any future vendored assets.
- `core/src/test/java/com/fastmd/mobile/core/render/RichRendererAssetPolicyTest.kt`
  - Covers native fallback no-asset posture.
  - Covers bundled renderer asset allowlisting.
  - Covers remote/dangerous request blocking, percent-encoded dangerous URL classification, external navigation blocking, and iframe blocking.
  - Covers manifest/hash verification, metadata lock verification, missing/unlisted/mismatched assets, unsupported extensions, dynamic code markers, remote references, and active SVG content.
- `tools/audit_renderer_assets.sh`
  - Production audit for absent/present renderer assets, WebView/runtime scan, app-local asset root, SHA-256 manifest, metadata lock, offline markers, network APIs, dynamic code, iframe/srcdoc/form/meta refresh, SVG active content, and dangerous URL encodings.
- `tools/audit_renderer_request_blocking.sh`
  - Production audit for request policy contracts and WebView interception requirements if Android WebView renderer code is introduced.
- `tools/test_renderer_asset_audit.sh`
  - Local shell harness proving the asset audit passes native fallback and valid app-local JS/CSS/font assets, and fails unsafe or incomplete renderer packages.
- `tools/test_renderer_request_blocking_audit.sh`
  - Local shell harness proving request-blocking audit fails missing policy/tests and unrouted WebView implementations, and passes only when request interception and navigation override policy routing are present.

## Validation Commands

Run from `android/`.

| Command | Result | Evidence |
| --- | --- | --- |
| `bash tools/audit_renderer_assets.sh` | PASS | Reported no Android WebView/`android.webkit`, no React Native/Flutter/Cordova runtime, and no vendored JS/CSS/font renderer asset tree. |
| `bash tools/audit_renderer_request_blocking.sh` | PASS | Confirmed first-class renderer request policy, explicit iframe/network/navigation/URL/file block reasons, required unit-test markers, and no Android WebView implementation. |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Confirmed native fallback pass, valid local JS/CSS/font package pass, and expected failures for missing manifests/metadata, misplaced assets, remote references, dangerous schemes, encoded URLs, network APIs, dynamic code, iframe/srcdoc/form/meta refresh, active SVG content, stale hashes, escaping paths, unsupported file types, malformed metadata, WebView without request-blocking tests, and web runtime dependencies. |
| `bash tools/test_renderer_request_blocking_audit.sh` | PASS | Confirmed request policy/test contract pass, missing policy/test failures, WebView without interception/navigation override failures, and routed WebView pass. |
| `./gradlew projects` | BLOCKED | Local shell cannot locate a Java Runtime: `The operation couldn't be completed. Unable to locate a Java Runtime.` |
| `./gradlew :core:testDebugUnitTest --tests 'com.fastmd.mobile.core.render.RichRendererAssetPolicyTest'` | BLOCKED | Same missing Java Runtime blocker as `./gradlew projects`. |

## Supervisor Checklist Recommendation

The supervisor can mark the following Android L11 checklist items complete as conditional Android gates, with this report plus the policy/test/tool files above as evidence:

- Add local renderer packaging/offline tests if JS renderer assets are used.
- Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
- Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.

Rationale: Android does not currently use JS/CSS/font renderer assets or WebView renderer surfaces. The implementation keeps Mermaid/math on native fallback paths and includes enforced audits/tests that pass the current native fallback posture while failing unsafe future renderer asset or WebView introductions.

## Remaining Blockers

- JVM-backed Gradle validation remains open until a Java Runtime/JDK 17 is available in this shell.
- This batch does not claim Android `lint`, `build`, `assembleDebug`, unit-test, connected device, API 27, low-memory, or modern-device L12 gates.
