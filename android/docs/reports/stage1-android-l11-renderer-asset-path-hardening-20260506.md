# Stage 1 Android L11 Renderer Asset Path Hardening - 2026-05-06

## Batch Scope

Android-owned bounded batch for the L11 conditional renderer gates:

- Add local renderer packaging/offline tests if JS renderer assets are used.
- Add WebView request-blocking tests if local JS renderer surfaces are used.
- Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.

The current Android implementation remains native Kotlin/Jetpack Compose. No Android WebView,
`android.webkit`, React Native, Flutter, Cordova, remote WebView shell, or vendored
JS/CSS/font renderer asset tree is present in the app. Mermaid/math rich blocks remain on
native fallback surfaces.

## Implementation

Changed Android files:

- `core/src/main/java/com/fastmd/mobile/core/render/RichRendererAssetPolicy.kt`
- `core/src/test/java/com/fastmd/mobile/core/render/RichRendererAssetPolicyTest.kt`
- `tools/test_renderer_asset_audit.sh`

Implementation details:

- Hardened `LocalRendererAssetPath` so any future vendored renderer asset path must:
  - stay under `fastmd-renderers/`;
  - include a concrete file below that root;
  - avoid blank path segments, `.` segments, and `..` traversal;
  - avoid whitespace/control characters;
  - avoid backslashes, percent-encoded markers, query strings, and fragments;
  - avoid URI schemes.
- Expanded JVM contract coverage for invalid renderer asset paths that previously relied
  only on the request policy/audit layer.
- Expanded shell audit regression coverage so the packaging/offline gate proves:
  - app-local JS, CSS, and font files pass only with a valid SHA-256 manifest;
  - malformed manifest lines fail;
  - manifests cannot hash themselves.

## Validation

Commands run from `android/` on 2026-05-06:

| Command | Result | Evidence |
| --- | --- | --- |
| `bash tools/audit_renderer_assets.sh` | PASS | No Android WebView/android.webkit implementation, no web runtime dependency, and no vendored JS/CSS/font renderer asset tree are present. |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Native fallback, app-local JS/CSS/font SHA-256 manifest success, missing/stale/malformed/self-hashing manifests, misplaced/unlisted assets, remote/dangerous references, WebView marker, and React Native dependency cases behaved as expected. |
| `bash tools/audit_stage1_manifest.sh` | PASS | No permissions, no broad storage/media/notification/default `INTERNET`, `allowBackup=false`, cleartext disabled, only `MainActivity` exported, no WebView implementation, and release hardening enabled. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew projects --no-daemon` | PASS | Gradle evaluated the root project and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew stage1AndroidRendererAssetGates --no-daemon` | PASS | Gradle executed `auditRendererAssets`, `testRendererAssetAudit`, and `stage1AndroidRendererAssetGates`; build successful. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew :core:testDebugUnitTest --tests 'com.fastmd.mobile.core.render.RichRendererAssetPolicyTest' --no-daemon` | BLOCKED | Kotlin compilation completed, but `:core:testDebugUnitTest` failed resolving runtime dependencies from Google Maven. Downloads for `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0` timed out connecting to `dl.google.com:443`. |

Local Java note:

- Plain `java -version` is blocked because no Java runtime is on PATH.
- Explicit JDK 17 path works: `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`.

## Supervisor Checklist Evidence

The supervisor can consider these Android L11 items complete for the Android lane based on
the implementation and validation above:

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
  - Evidence: `tools/test_renderer_asset_audit.sh` now covers app-local JS/CSS/font assets with a valid SHA-256 manifest and native fallback with no assets.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
  - Android evidence: no Android WebView surface is present; `RichRendererRequestPolicy` remains fail-closed for future renderer requests, and the renderer audit fails if WebView implementation markers appear before request-blocking coverage is in place.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
  - Evidence: `tools/test_renderer_asset_audit.sh` passes positive JS/CSS/font manifest coverage and negative cases for missing, stale, malformed, self-hashing, escaping, and incomplete manifests.

Do not mark broader L12 compile/test/lint/device validation complete from this batch. The
targeted Gradle unit-test execution remains blocked by Google Maven dependency download
timeouts, although `./gradlew projects` and script-backed Gradle renderer gates passed with
the explicit JDK 17 path.
