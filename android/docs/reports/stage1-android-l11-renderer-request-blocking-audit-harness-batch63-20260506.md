# Stage 1 Android L11 Renderer Request Blocking Audit Harness Batch 63 - 2026-05-06

## Scope

Android-owned L11 conditional renderer gate hardening:

- Add WebView request-blocking regression coverage for Android local rich-renderer surfaces.
- Keep ordinary Android Markdown rendering native Kotlin/Compose; no WebView, JS renderer asset tree, network permission, or web runtime was introduced.
- Record validation evidence under `android/docs/reports/` only.

## Implementation

- Added `tools/test_renderer_request_blocking_audit.sh`.
  - Builds synthetic Android source trees in a temporary directory.
  - Verifies native fallback request-policy coverage passes.
  - Verifies missing request-policy contracts fail.
  - Verifies missing request-policy unit-test markers fail.
  - Verifies a WebView marker without request interception fails.
  - Verifies a WebView marker with request interception but no navigation override fails.
  - Verifies a WebView marker with `RichRendererRequestPolicy.decide`, `shouldInterceptRequest`, `shouldOverrideUrlLoading`, and iframe classification passes.
- Added Gradle task `testRendererRequestBlockingAudit`.
- Wired `testRendererRequestBlockingAudit` into `stage1AndroidRendererAssetGates`.
- Updated `android/README.md` with the direct shell command and regression scope.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `bash -n tools/test_renderer_request_blocking_audit.sh` | PASS | Shell syntax validation completed with no output. |
| `bash tools/test_renderer_request_blocking_audit.sh` | PASS | Passed native fallback, missing policy, missing tests, unrouted WebView, intercept-only WebView, and fully routed WebView synthetic cases. |
| `bash tools/audit_renderer_request_blocking.sh` | PASS | Confirmed Android request policy, request-policy unit-test markers, blocked remote/dangerous requests, percent-encoded dangerous requests, external navigation, iframe denial, and absence of WebView/android.webkit in current main code. |
| `bash tools/audit_renderer_assets.sh` | PASS | Confirmed no Android WebView/android.webkit implementation, no React Native/Flutter/Cordova-equivalent runtime, and no vendored JS/CSS/font renderer asset tree. |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Existing renderer asset regression harness still passes, including native fallback, app-local SHA-256-manifested assets, missing/misplaced/non-main assets, remote/content/protocol-relative/encoded/double-encoded dangerous references, iframe/srcdoc/navigation/network API blockers, stale/unlisted/malformed manifests, WebView marker failure, and React Native dependency failure. |
| `./gradlew projects --no-daemon` | BLOCKED | Local machine has no Java runtime: `The operation couldn't be completed. Unable to locate a Java Runtime. Please visit http://www.java.com for information on installing Java.` |

## Checklist Evidence

Supervisor can use this Android-local evidence for the Android portion of:

- L11: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
  - Evidence: `tools/test_renderer_request_blocking_audit.sh` and this report.
- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
  - Evidence refreshed: `bash tools/test_renderer_asset_audit.sh` passed in this batch.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
  - Evidence refreshed: `bash tools/test_renderer_asset_audit.sh` passed in this batch.

Do not close Android Gradle-backed L12 validation gates from this batch. Gradle remains blocked locally until a Java 17-compatible runtime is installed and visible to `./gradlew`.
