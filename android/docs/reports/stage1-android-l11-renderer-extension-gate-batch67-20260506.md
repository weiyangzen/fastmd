# Stage 1 Android L11 Renderer Extension Gate Batch 67 - 2026-05-06

## Scope

This bounded Android live-lane batch hardened the Android-local rich renderer packaging,
offline, manifest/hash, and request-blocking gates. It only touched `android/**`.

The current Android implementation remains native Kotlin/Jetpack Compose. No Android
`WebView`, `android.webkit`, React Native, Flutter, Cordova, remote WebView shell, CDN
renderer, network permission, or vendored JS/CSS/font renderer asset tree is present.
Mermaid/math rich blocks still use native readable fallback surfaces.

## Implementation

- Tightened `RichRendererRequestPolicy` / local renderer package verification so future
  renderer packages can list only supported local renderer asset file types:
  `js`, `mjs`, `css`, `html`, `htm`, `woff`, `woff2`, `ttf`, `otf`, `svg`, `png`,
  `jpg`, `jpeg`, and `webp`.
- Added Kotlin unit-test contract coverage for unsupported manifest and metadata-lock
  entries such as `.json` and `.wasm`.
- Added Kotlin verifier coverage that rejects unsupported packaged asset types even when
  their SHA-256 hashes and metadata are otherwise internally consistent.
- Extended offline marker scanning to cover `.mjs` renderer module assets, not only
  `.js`, `.css`, and HTML files.
- Hardened `tools/audit_renderer_assets.sh` with the same supported-extension gate.
- Extended `tools/test_renderer_asset_audit.sh` with regression cases for unsupported
  manifest entries, unsupported unlisted packaged assets, and `.mjs` network API usage.

## Changed Files

- `android/core/src/main/java/com/fastmd/mobile/core/render/RichRendererAssetPolicy.kt`
- `android/core/src/test/java/com/fastmd/mobile/core/render/RichRendererAssetPolicyTest.kt`
- `android/tools/audit_renderer_assets.sh`
- `android/tools/test_renderer_asset_audit.sh`
- `android/docs/reports/stage1-android-l11-renderer-extension-gate-batch67-20260506.md`

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `bash tools/audit_renderer_assets.sh` | PASS | No Android WebView/android.webkit implementation, no web runtime dependency, and no vendored JS/CSS/font renderer asset tree are present. |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Existing renderer asset audit regressions passed, plus new unsupported extension and `.mjs` network API cases. |
| `bash tools/audit_renderer_request_blocking.sh` | PASS | Request policy contract and required unit-test markers are present; no WebView surface is present. |
| `bash tools/test_renderer_request_blocking_audit.sh` | PASS | Native fallback, missing contract, unrouted WebView, partially routed WebView, and fully routed WebView synthetic cases behaved as expected. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew projects --no-daemon` | PASS | Gradle discovered root project `fastmd-android` and modules `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `JAVA_HOME="/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home" ./gradlew stage1AndroidRendererAssetGates --no-daemon` | PASS | Gradle aggregate renderer asset/request-blocking gates passed with 4 executed tasks. |
| `JAVA_HOME="/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home" ./gradlew :core:compileDebugUnitTestKotlin --offline --no-daemon` | PASS | Core main and unit-test Kotlin compilation completed offline after Kotlin daemon fallback. The local Kotlin daemon still attempted to use an existing JDK `25.0.1` process first and logged the known `IllegalArgumentException: 25.0.1`, then Gradle fell back and finished successfully. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :core:testDebugUnitTest --no-daemon` | BLOCKED | Kotlin daemon first failed on JBR version parsing (`IllegalArgumentException: 25.0.1`) and fell back to in-process compilation. The task then failed before test execution because runtime dependencies could not be downloaded from `https://dl.google.com`: `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0` timed out. |

## Supervisor Checklist Candidates

The supervisor can use this report as Android evidence for these L11 checklist items:

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
  - Evidence: `tools/test_renderer_asset_audit.sh` covers native fallback, app-local
    JS/CSS/font packaging with SHA-256 manifest, unsupported renderer file extensions,
    `.mjs` offline scanning, missing/stale/malformed manifests, metadata locks, and
    remote/network/dynamic-code markers.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used, Android portion.
  - Evidence: `RichRendererRequestPolicy` remains fail-closed; request audit and
    regression tests passed; no Android WebView surface is currently present.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
  - Evidence: Kotlin verifier and shell audit tests validate SHA-256 manifests,
    metadata locks, stale hashes, unlisted assets, self-hashing manifests, unsupported
    asset extensions, and app-local asset root restrictions.

Keep broader L12 lint, build, assemble, unit-test execution, instrumentation, API 27, and
device validation gates open from this batch. The source-level renderer gates and core
Kotlin compilation pass, but `:core:testDebugUnitTest` execution is blocked by dependency
download timeouts from `dl.google.com`.
