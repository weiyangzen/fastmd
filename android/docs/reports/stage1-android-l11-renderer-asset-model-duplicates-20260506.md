# Stage 1 Android L11 Renderer Asset Model Duplicate Gate - 2026-05-06

## Scope

This bounded Android batch hardens the remaining conditional L11 renderer asset
gate surface. Android Stage 1 still uses native Compose fallback for Mermaid and
math rich blocks; no Android WebView implementation and no vendored
JS/CSS/font renderer asset tree are present in the current app.

## Implementation

- Updated `core/src/main/java/com/fastmd/mobile/core/render/RichRendererAssetPolicy.kt`.
  - `RichRendererAssetPolicy` now rejects duplicate vendored renderer asset
    paths.
  - This keeps future `renderer-assets.sha256` / metadata lock declarations
    one-to-one with packaged asset paths and prevents ambiguous duplicate
    declarations with different kind or hash values.
- Updated `core/src/test/java/com/fastmd/mobile/core/render/RichRendererAssetPolicyTest.kt`.
  - Added `rendererSurfaceRejectsDuplicateVendoredAssetPaths`.
  - The test accepts distinct script/CSS assets and rejects duplicate exact,
    duplicate hash, and duplicate kind variants for the same asset path.

## Validation

| Command | Result | Notes |
| --- | --- | --- |
| `bash -n tools/audit_renderer_assets.sh && bash -n tools/test_renderer_asset_audit.sh` | PASS | Shell syntax validation completed with no output. |
| `bash tools/audit_renderer_assets.sh` | PASS | Confirmed no Android WebView or `android.webkit` implementation, no React Native/Flutter/Cordova/equivalent web runtime dependency, and no vendored JS/CSS/font renderer asset tree. |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Regression harness passed native fallback, app-local JS/CSS/font assets with SHA-256 manifest, missing manifest, missing metadata lock, metadata lock included in manifest, misplaced/non-main assets, dangerous/remote references, navigation APIs, iframe/srcdoc, network APIs, stale hashes, malformed manifests, WebView marker failure, and React Native dependency failure. |
| `./gradlew projects --no-daemon` | BLOCKED | Default macOS `/usr/bin/java` stub reported `Unable to locate a Java Runtime`; no default Java runtime is configured. |
| `JAVA_HOME='/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home' ./gradlew projects --no-daemon` | PASS | Root project `fastmd-android`; modules `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings` were discovered. |
| `JAVA_HOME='/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home' ./gradlew :core:testDebugUnitTest --tests 'com.fastmd.mobile.core.render.RichRendererAssetPolicyTest' --no-daemon` | BLOCKED | Edited main and test Kotlin classes compiled after Kotlin daemon fallback, but `:core:testDebugUnitTest` failed resolving runtime dependencies from Google Maven: `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0` timed out connecting to `dl.google.com:443`. |

## Blueprint Evidence

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
  - Android evidence: current implementation uses native fallback and packages
    no renderer asset tree; `tools/audit_renderer_assets.sh` and
    `tools/test_renderer_asset_audit.sh` passed.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer
  surfaces are used.
  - Android evidence: no Android WebView surface is present; the audit harness
    fails any Android WebView marker until request-blocking coverage exists.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font
  assets are vendored.
  - Android evidence: `RichRendererAssetPolicy` now rejects duplicate asset
    path declarations in the Kotlin model, while the shell audit harness
    verifies future app-local renderer assets require SHA-256 manifests,
    metadata lock entries, clean paths, and offline-only content.

## Remaining Validation Limits

- L12 Android compile/test/lint/build gates remain open where they require
  network dependency resolution from Google Maven or device/emulator access.
- Default Java discovery remains blocked until the local shell config exports a
  real JDK, even though an explicit OpenJDK 17 `JAVA_HOME` can run Gradle
  project discovery.
