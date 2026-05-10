# Stage 1 Android L11 Renderer Request Policy Batch - 2026-05-06

## Scope

Android live lane bounded batch for the earliest open Android-owned L11 renderer gate cluster:

- Add local renderer packaging/offline tests if JS renderer assets are used.
- Add WebView request-blocking tests if local JS renderer surfaces are used.
- Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.

The current Android implementation remains native Kotlin/Jetpack Compose. No Android WebView,
`android.webkit`, React Native, Flutter, Cordova, remote WebView shell, or vendored JS/CSS/font
renderer asset tree is present. Mermaid and math remain native readable source-card fallback paths.

This batch adds a reusable Android core request policy for any future isolated rich-renderer surface
without introducing a renderer surface or vendored assets.

## Changed Android Files

- `android/core/src/main/java/com/fastmd/mobile/core/render/RichRendererAssetPolicy.kt`
- `android/core/src/test/java/com/fastmd/mobile/core/render/RichRendererAssetPolicyTest.kt`
- `android/docs/reports/stage1-android-l11-renderer-request-policy-20260506.md`

## Implementation Evidence

`RichRendererAssetPolicy.kt` now defines:

- `RichRendererRequestKind` for initial document, renderer asset, subresource, navigation, and iframe requests.
- `RichRendererRequestBlockReason` for blank URLs, network requests, external navigation,
  `javascript:`, `data:`, iframes, `content:`, non-renderer `file:`, and unknown schemes.
- `RichRendererRequestDecision` as an allow/block result with an explicit block reason.
- `RichRendererRequestPolicy.decide(...)`, which only allows local Android asset URLs under
  `file:///android_asset/fastmd-renderers/` for non-navigation renderer loads.

The policy blocks:

- `http://`, `https://`, and protocol-relative remote URLs.
- external navigation, including navigation to otherwise local renderer assets.
- `javascript:` and mixed-case `JAVASCRIPT:` URLs.
- `data:` URLs.
- iframe requests.
- `content:` URIs.
- non-renderer `file:` URLs.
- blank URLs and unknown schemes.
- path traversal attempts such as `../` and `%2e%2e`.
- direct loading of the renderer hash manifest as a runtime asset.

`RichRendererAssetPolicyTest.kt` now covers:

- allowed bundled renderer asset paths under `file:///android_asset/fastmd-renderers/`.
- rejection of renderer-root directory loads, traversal, manifest loads, and non-renderer app assets.
- rejection of remote subresources, CDN-style schemes, dangerous script/data/content URLs, external
  navigation, iframes, blank URLs, and unknown schemes.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `bash tools/audit_renderer_assets.sh` | PASS | No Android WebView/android.webkit implementation, no React Native/Flutter/Cordova runtime, and no vendored JS/CSS/font renderer asset tree are present. |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Existing regression gate still passes for native fallback, app-local hashed assets, missing/stale manifests, misplaced assets, remote/dangerous asset references, WebView marker failure, and web-runtime dependency failure. |
| `bash tools/audit_rich_fixture_render.sh` | PASS | Rich fixture coverage remains native Kotlin/Compose; Mermaid/math render as safe readable source cards; no web app runtime is present. |
| `bash tools/audit_stage1_manifest.sh` | PASS | No broad storage/media/notification/default `INTERNET` permission; `allowBackup=false`; cleartext disabled; only `MainActivity` exported; no WebView implementation. |
| `bash tools/audit_performance_report.sh` | PASS | Android performance profiles and fixture matrix report emitted; source-level performance posture remains intact. |
| `java -version` | BLOCKED | The shell default Java runtime is unavailable: `Unable to locate a Java Runtime.` |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17 ./gradlew projects --no-daemon` | BLOCKED | Gradle wrapper attempted `https://services.gradle.org/distributions/gradle-9.3.0-bin.zip` and failed before project evaluation with `java.net.UnknownHostException: services.gradle.org`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17 gradle projects --no-daemon` | PASS | Installed Gradle evaluated the Android project successfully and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17 ./gradlew :core:testDebugUnitTest --no-daemon` | BLOCKED | Wrapper distribution download failed with `java.net.UnknownHostException: services.gradle.org`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17 gradle :core:testDebugUnitTest --no-daemon` | BLOCKED | Project evaluation started, then `:core:compileDebugKotlin` failed resolving Maven artifacts. Maven Central returned HTTP 403 for `kotlinx-coroutines-android-1.8.1.jar`, `okio-jvm-3.4.0.jar`, `kotlin-stdlib-jdk8-1.8.0.jar`, and `kotlin-stdlib-jdk7-1.8.0.jar`. |

## Supervisor Checklist Candidates

The supervisor can consider the following Android-owned checklist items complete or not-applicable
for the current native-fallback implementation, with this report as evidence:

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
  - Evidence: `bash tools/test_renderer_asset_audit.sh` passed and confirms current native fallback plus future app-local offline asset/hash requirements.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
  - Android evidence: no Android WebView surface is present; `RichRendererRequestPolicy` and tests define fail-closed request decisions for any future local renderer surface.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
  - Evidence: `bash tools/test_renderer_asset_audit.sh` passed manifest/hash positive and negative cases; current tree has no vendored renderer assets.

Keep Android Gradle compile/unit-test validation items open until wrapper distribution and Maven
artifact resolution are available in the local environment.
