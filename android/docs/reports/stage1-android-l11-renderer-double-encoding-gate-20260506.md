# Stage 1 Android L11 Renderer Double-Encoding Gate

Date: 2026-05-06 06:35 CST

## Scope

Android-owned L11 renderer safety gate hardening.

This batch keeps ordinary Markdown rendering native Kotlin / Jetpack Compose. It
does not add Android `WebView`, `android.webkit`, React Native, Flutter,
Cordova, CDN renderer assets, remote renderer loading, network permissions, or a
vendored JS/CSS/font renderer asset tree.

## Implementation Evidence

- Hardened `core/src/main/java/com/fastmd/mobile/core/render/RichRendererAssetPolicy.kt`.
  - Renderer request policy now recursively decodes percent escapes up to a
    bounded limit before classifying dangerous schemes.
  - Double-encoded `http(s)`, `javascript:`, `data:`, `content:`, and
    encoded `file:` payloads continue to fail closed.
- Extended `core/src/test/java/com/fastmd/mobile/core/render/RichRendererAssetPolicyTest.kt`.
  - Added double percent-encoded remote, JavaScript, data, and content URI
    request-policy coverage.
- Hardened `tools/audit_renderer_assets.sh`.
  - Renderer asset scans now reject percent-encoded percent markers (`%25`) so
    future vendored assets cannot hide dangerous remote or script schemes behind
    double encoding.
- Extended `tools/test_renderer_asset_audit.sh`.
  - Added negative cases for double percent-encoded remote URLs.
  - Added negative cases for double percent-encoded `javascript:` URLs.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew projects --no-daemon` | PASS | Gradle discovered root project `fastmd-android` and modules `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 4s`. |
| `bash tools/audit_renderer_assets.sh` | PASS | No Android `WebView` / `android.webkit`, no React Native / Flutter / Cordova or equivalent web runtime dependency, and no vendored JS/CSS/font renderer asset tree were found. |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Regression harness passed native fallback, app-local SHA-256 manifest success, missing/misplaced/stale/unlisted/malformed assets, dangerous remote/content/protocol-relative/encoded/uppercase references, new double-encoded remote and `javascript:` references, network-capable APIs, WebView markers, and React Native dependency markers. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew stage1AndroidRendererAssetGates --no-daemon` | PASS | Ran `:auditRendererAssets`, `:testRendererAssetAudit`, and `:stage1AndroidRendererAssetGates`; `BUILD SUCCESSFUL in 11s`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :core:testDebugUnitTest --no-daemon` | BLOCKED | Changed Kotlin sources and tests compiled, then `:core:testDebugUnitTest` failed resolving uncached Google Maven artifacts `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0`; both downloads timed out connecting to `dl.google.com:443`. |

## Checklist Evidence For Supervisor

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
  - Android evidence: `tools/test_renderer_asset_audit.sh` covers native fallback,
    app-local JS/CSS/font renderer asset packaging, SHA-256 manifest verification,
    misplaced assets, missing manifests, and offline-only subresource posture.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used, Android portion.
  - Android evidence: no Android WebView surface is present; the gate fails if a
    WebView marker appears before request-blocking coverage exists. Kotlin
    request-policy tests cover local asset allowlisting and blocked network,
    external navigation, `javascript:`, `data:`, `content:`, iframe, and
    double-encoded dangerous requests.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
  - Android evidence: `tools/test_renderer_asset_audit.sh` verifies valid
    SHA-256 manifests and fails missing, stale, unlisted, escaping, self-hashing,
    and malformed manifests.

## Remaining Blockers

- Full Android JVM test execution remains blocked by uncached dependency
  downloads timing out from Google Maven. The Gradle task compiled the changed
  Kotlin sources and test sources before dependency resolution failed for the
  runtime classpath.
