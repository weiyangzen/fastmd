# Stage 1 Android L11 Renderer Conditional Gates Batch 70

Date: 2026-05-06 13:08:09 CST
Lane: Android live lane
Ownership: Android-only evidence under `android/docs/reports/`

## Scope

This batch advanced the earliest remaining Android-owned checklist cluster from the authoritative blueprint:

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.

The Android implementation currently uses native rich-block fallback surfaces. No Android `WebView` or `android.webkit` implementation is present, and no `app/src/main/assets/fastmd-renderers` asset tree is present. Because those surfaces are conditional, this batch records the fresh Android gate evidence proving the conditions are absent and the dormant gates are present for any future vendored renderer/WebView work.

## Implementation Evidence

- `android/build.gradle.kts` wires `stage1AndroidRendererAssetGates` into Android `check` for application and library modules.
- `android/tools/audit_renderer_assets.sh` audits native Android app/runtime exclusions, app-local renderer asset roots, offline SHA-256 manifests, metadata locks, dangerous URL markers, network-capable browser APIs, dynamic code markers, SVG active content, and unsupported packaged asset extensions.
- `android/tools/test_renderer_asset_audit.sh` regression-tests the renderer asset audit with passing native-fallback and local-asset fixtures plus failing fixtures for missing manifests, stale hashes, remote subresources, encoded URLs, iframes, `srcdoc`, network APIs, dynamic code, workers, service workers, and React Native runtime dependency markers.
- `android/tools/audit_renderer_request_blocking.sh` verifies `RichRendererRequestPolicy` exists, has explicit block reasons for network/external navigation/`javascript:`/`data:`/content URI/non-renderer file/iframe cases, and fails any future `WebView` implementation that does not route through request interception and navigation override hooks.
- `android/tools/test_renderer_request_blocking_audit.sh` regression-tests request-blocking audit pass/fail behavior for native fallback, missing policy/tests, unrouted WebView, partially routed WebView, and fully routed WebView fixtures.
- `android/core/src/test/java/com/fastmd/mobile/core/render/RichRendererAssetPolicyTest.kt` contains pure Kotlin unit coverage for local renderer path validation, hash parsing/verification, metadata lock verification, dangerous encoded marker rejection, dynamic-code rejection, SVG active-content rejection, packaged asset mismatch detection, and request-policy blocking decisions.

## Fresh Validation

Passed:

- `bash tools/audit_renderer_assets.sh`
  - `PASS: No Android WebView or android.webkit implementation is present.`
  - `PASS: No React Native, Flutter, Cordova, or equivalent web runtime dependency is present.`
  - `PASS: No vendored JS/CSS/font renderer asset tree is present; Android rich blocks use native fallback paths.`
- `bash tools/test_renderer_asset_audit.sh`
  - Passed native-fallback and app-local JS/CSS/font renderer asset verification fixtures.
  - Passed negative fixtures for missing/malformed manifests, stale hashes, escaping paths, remote references, encoded dangerous URLs, iframes, `srcdoc`, network browser APIs, dynamic code, worker APIs, service workers, unsupported extensions, and web-runtime dependency markers.
- `bash tools/audit_renderer_request_blocking.sh`
  - Verified first-class request policy contract, explicit block reasons, request-policy unit test markers, and absence of Android `WebView`/`android.webkit` implementation.
- `bash tools/test_renderer_request_blocking_audit.sh`
  - Passed native fallback contract fixture.
  - Passed failure fixtures for missing policy, missing tests, unrouted WebView, and WebView without navigation override.
  - Passed routed WebView fixture that uses `RichRendererRequestPolicy`, `shouldInterceptRequest`, `shouldOverrideUrlLoading`, and explicit iframe classification.

Blocked:

- `java -version`
- `./gradlew projects`
- `./gradlew stage1AndroidRendererAssetGates`
- `./gradlew :core:testDebugUnitTest`

All four commands failed before Gradle/JVM startup with the same local environment blocker:

```text
The operation couldn’t be completed. Unable to locate a Java Runtime.
Please visit http://www.java.com for information on installing Java.
```

This preserves L12 Gradle validation gates as open until a JDK 17 runtime is available to the Android lane.

## Supervisor Completion Recommendation

The supervisor can mark these Android L11 conditional items complete from Android evidence:

- Add local renderer packaging/offline tests if JS renderer assets are used.
- Add WebView request-blocking tests if local JS renderer surfaces are used.
- Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.

Evidence path:

- `android/docs/reports/stage1-android-l11-renderer-conditional-gates-batch70-20260506.md`

Keep Android L12 Gradle validation items open because this batch could not start Java/Gradle in the local environment.
