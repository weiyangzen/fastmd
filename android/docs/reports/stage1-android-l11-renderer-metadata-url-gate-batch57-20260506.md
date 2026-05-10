# Stage 1 Android L11 Renderer Metadata URL Gate Batch 57 - 2026-05-06

## Scope

Android live lane bounded batch for the remaining conditional L11 renderer gates:

- Add local renderer packaging/offline tests if JS renderer assets are used.
- Add WebView request-blocking tests if local JS renderer surfaces are used.
- Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.

The current Android implementation remains native Kotlin/Jetpack Compose. No Android
`WebView`, `android.webkit`, React Native, Flutter, Cordova, remote WebView shell, or
vendored JS/CSS/font renderer asset tree is present. This batch hardens the future
local renderer asset contract without adding a web renderer.

## Changes

- `core/src/main/java/com/fastmd/mobile/core/render/RichRendererAssetPolicy.kt`
  - Hardened renderer asset metadata lock parsing.
  - Metadata fields for upstream name, upstream version, and license notes now fail
    closed when they contain control characters or URL markers such as remote HTTP(S),
    dangerous schemes, encoded scheme markers, or common CDN identifiers.
- `core/src/test/java/com/fastmd/mobile/core/render/RichRendererAssetPolicyTest.kt`
  - Added unit coverage for metadata lock rejection when metadata fields contain
    control/newline smuggling, direct remote URLs, percent-encoded remote URLs, or
    `javascript:` markers.
- `tools/audit_renderer_assets.sh`
  - Added the same metadata-field URL/control-marker rejection to the shell audit.
  - The scan is case-insensitive so encoded mixed-case markers like `https%3A` fail.
- `tools/test_renderer_asset_audit.sh`
  - Added synthetic fail-closed projects for direct and encoded URL markers in
    `renderer-assets.lock` metadata.

## Validation

| Command | Result | Notes |
| --- | --- | --- |
| `bash -n tools/audit_renderer_assets.sh && bash -n tools/test_renderer_asset_audit.sh && bash tools/audit_renderer_assets.sh && bash tools/test_renderer_asset_audit.sh && bash tools/audit_renderer_request_blocking.sh` | PASS | Native fallback has no vendored assets; synthetic app-local hashed JS/CSS/font assets pass; malformed/missing/stale/unlisted/misplaced assets fail; direct and encoded metadata URL markers fail; WebView/runtime markers fail; request-blocking audit confirms first-class request policy and no Android WebView implementation. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk ./gradlew projects --no-daemon` | PASS | Gradle project discovery succeeded for `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk ./gradlew :core:compileDebugUnitTestKotlin --no-daemon` | PASS | Core main/test Kotlin compilation was up to date after the prior compile; command completed successfully. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk ./gradlew :core:testDebugUnitTest --no-daemon` | BLOCKED | Main and test Kotlin compilation reached the unit test task after Kotlin daemon fallback, then runtime dependency resolution failed because `dl.google.com` timed out while downloading `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0`. |

## Supervisor Completion Candidates

- L11 `Add local renderer packaging/offline tests if JS renderer assets are used.`
  Evidence: `tools/test_renderer_asset_audit.sh` passes the native fallback case, a
  synthetic app-local JS/CSS/font renderer asset positive case with SHA-256 manifest
  and metadata lock, and fail-closed malformed/missing/stale/unlisted/misplaced asset
  cases.
- L11 `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
  Android evidence: no Android WebView surface exists; `tools/audit_renderer_request_blocking.sh`
  passes and requires `RichRendererRequestPolicy` plus unit-test coverage for bundled
  asset allowlisting, metadata lock blocking, remote/dangerous URL blocking,
  percent-encoded dangerous URLs, external navigation, and iframe blocking.
- L11 `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
  Evidence: `tools/test_renderer_asset_audit.sh` validates manifest/hash positive
  and negative cases, now including URL/control-marker smuggling through renderer
  metadata fields.

L12 `Run Android ./gradlew :core:testDebugUnitTest` should remain open until Maven
runtime dependencies can be resolved from Google Maven or are already cached.
