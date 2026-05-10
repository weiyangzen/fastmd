# Stage 1 Android L11 Renderer Dynamic Code Gate Batch 64 - 2026-05-06

## Scope

Android-owned L11 renderer asset gate hardening. This batch keeps FastMD Android native Kotlin/Compose and does not add a WebView or vendored JS/CSS/font renderer assets.

## Implementation

- Hardened `LocalRendererAssetPackageVerifier` so future vendored renderer assets are rejected when scannable JS/CSS/HTML contains dynamic code execution markers:
  - `eval(...)`
  - `Function(...)`
  - `new Function(...)`
  - string-based `setTimeout(...)`
  - string-based `setInterval(...)`
- Applied the same dynamic-code marker check to `tools/audit_renderer_assets.sh`, including JavaScript escape decoding before scanning.
- Added Kotlin verifier regression coverage for eval, Function constructor, new Function constructor, string timer, and JavaScript-escaped eval payloads.
- Added synthetic shell-audit fixtures proving the Android renderer asset audit fails those payloads before any future renderer asset package can pass.

## Validation

Run from `android/`.

| Command | Result | Notes |
| --- | --- | --- |
| `bash tools/audit_renderer_assets.sh` | PASS | Current Android tree has no WebView, no web-runtime dependency, and no vendored renderer asset tree; native fallback path remains locked down. |
| `bash tools/audit_renderer_request_blocking.sh` | PASS | Request policy contract and unit-test markers remain present; no Android WebView implementation is present. |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Synthetic fixtures now include dynamic import, eval, Function constructor, string timer, and JavaScript-escaped eval rejection cases. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew projects` | PASS | Gradle wrapper resolved the Android project hierarchy. Default shell `java` is still unavailable without explicit `JAVA_HOME`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew stage1AndroidRendererAssetGates` | PASS | Ran `auditRendererAssets`, `auditRendererRequestBlocking`, `testRendererAssetAudit`, and `testRendererRequestBlockingAudit`; build successful. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew :core:testDebugUnitTest stage1AndroidRendererAssetGates` | BLOCKED | Renderer gate portion completed, but `:core:testDebugUnitTest` failed resolving AndroidX jars from `dl.google.com`: `collection-ktx-1.4.0.jar` and `concurrent-futures-1.1.0.jar` timed out. Kotlin also reported an existing daemon on Java `25.0.1` and fell back to non-daemon compilation before the dependency-resolution failure. |

## Environment Notes

- `java -version` with the default shell path failed: `Unable to locate a Java Runtime`.
- JDK 17 exists at `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home` and was used explicitly for Gradle validation.
- Network access to `https://dl.google.com/dl/android/maven2/` timed out during `:core:testDebugUnitTest`, so platform validation items that require uncached AndroidX artifacts should remain open until dependency resolution succeeds.

## Checklist Evidence For Supervisor

- L11 `Add local renderer packaging/offline tests if JS renderer assets are used`: can be marked complete for Android evidence. The Android native fallback path passes with no vendored assets, and future vendored renderer asset trees must pass hash/metadata/offline/dynamic-code gates.
- L11 `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used`: Android side can be marked complete as conditional evidence. No Android WebView exists; if one is added, the request-blocking audit requires policy routing, request interception, navigation interception, and iframe classification.
- L11 `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored`: can be marked complete for Android evidence. The Android audit and Gradle aggregate require `renderer-assets.sha256`, `renderer-assets.lock`, exact SHA-256 matches, app-main asset location, metadata coverage, and offline scan compliance.
- L12 `Run Android ./gradlew :core:testDebugUnitTest`: keep open. Current blocker is dependency download timeout from `dl.google.com`, not a source-level renderer gate failure.
