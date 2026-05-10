# Stage 1 Android L11 Renderer Request Extension Gate - 2026-05-06

## Batch Scope

- Worker lane: Android live lane.
- Ownership: `android/**` only.
- Blueprint cluster: L11 automated renderer gates, specifically Android local renderer/WebView request-blocking coverage.

## Implementation Evidence

- Hardened `RichRendererRequestPolicy` in `android/core/src/main/java/com/fastmd/mobile/core/render/RichRendererAssetPolicy.kt`.
- `file:///android_asset/fastmd-renderers/...` requests now require a recognized renderer asset extension instead of allowing every file under the renderer asset root.
- Allowed renderer asset extensions are limited to local renderer script/style/document/font/image types: `js`, `mjs`, `css`, `html`, `htm`, `woff`, `woff2`, `ttf`, `otf`, `svg`, `png`, `jpg`, `jpeg`, and `webp`.
- Added unit coverage in `android/core/src/test/java/com/fastmd/mobile/core/render/RichRendererAssetPolicyTest.kt` for:
  - Positive allowlisting of bundled `.mjs` renderer assets.
  - Blocking `config.json` under the renderer root as a non-renderer file.
  - Blocking extensionless renderer-root files.
  - Blocking hidden files.
  - Blocking trailing-dot file names.

## Validation

### Passed

- `bash tools/audit_renderer_request_blocking.sh`
  - Passed request policy contract checks.
  - Passed request-policy unit-test marker checks.
  - Confirmed no Android `WebView` / `android.webkit` implementation is present; rich Markdown currently uses native fallback surfaces.

- `bash tools/test_renderer_request_blocking_audit.sh`
  - Passed native fallback request policy gate.
  - Passed negative regression checks for missing policy and missing tests.
  - Passed negative regression checks for WebView renderer code without request interception or navigation override.
  - Passed positive regression check for WebView renderer code routed through `RichRendererRequestPolicy`.

- `bash tools/audit_renderer_assets.sh`
  - Passed no-WebView scan.
  - Passed native Android runtime exclusion scan.
  - Confirmed no vendored JS/CSS/font renderer asset tree is present; Android rich blocks use native fallback paths.

- `bash tools/test_renderer_asset_audit.sh`
  - Passed native fallback asset gate.
  - Passed local JS/CSS/font SHA-256 manifest regression checks.
  - Passed metadata lock regression checks.
  - Passed remote subresource, dangerous URL, browser API, iframe, `srcdoc`, and stale hash negative checks.
  - Passed WebView and React Native negative audit checks.

### Blocked

- `./gradlew projects`
  - Blocked before Gradle project evaluation.
  - Exact shell output: `The operation couldn’t be completed. Unable to locate a Java Runtime. Please visit http://www.java.com for information on installing Java.`

- `./gradlew :core:testDebugUnitTest --tests com.fastmd.mobile.core.render.RichRendererAssetPolicyTest`
  - Blocked by the same missing Java runtime before Gradle test execution.

## Checklist Evidence For Supervisor

- L11 `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
  - Android evidence: request policy is a first-class core contract, shell request-blocking audit gates pass, and no Android WebView implementation is currently present.
  - Evidence path: this report.

- L11 `Add local renderer packaging/offline tests if JS renderer assets are used.`
  - Android evidence: native fallback path has no vendored JS/CSS/font renderer asset tree; renderer asset audit and regression gates pass.
  - Evidence path: this report.

- L11 `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
  - Android evidence: SHA-256 manifest and metadata lock regression gates pass in `tools/test_renderer_asset_audit.sh`; no current vendored asset tree is present.
  - Evidence path: this report.

## Remaining Blockers

- Platform Gradle validation remains open until a Java runtime/JDK 17 is available in the Android worker shell.
