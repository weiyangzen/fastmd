# Stage 1 Android L11/L12 Renderer Network API Batch 54

Date: 2026-05-06
Lane: Android live lane
Scope: `android/**`

## Batch Selection

This bounded batch advanced the earliest still-open Android-owned cluster that could
be handled without touching iOS or the authoritative Docs checklist:

- L11 conditional local renderer packaging/offline tests if JS renderer assets are used.
- L11 conditional WebView request-blocking tests if local JS renderer surfaces are used.
- L11 conditional renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
- L12 minimum Android Gradle validation through `./gradlew projects`.
- L12 bounded retry of Android `./gradlew lint`.

The current Android renderer path remains native Kotlin/Compose fallback for Mermaid
and math. No Android `WebView`, `android.webkit`, React Native, Flutter, Cordova,
Capacitor, remote WebView shell, or vendored JS/CSS/font renderer asset tree is
present.

## Implementation

Updated `android/tools/test_renderer_asset_audit.sh` to add explicit fail-closed
regression cases for additional network-capable browser APIs inside synthetic
vendored renderer assets:

- `XMLHttpRequest`
- `WebSocket`
- `EventSource`
- `navigator.sendBeacon`
- `SharedWorker`
- `importScripts`
- `navigator.serviceWorker`

These cases complement the existing checks for `fetch`, dynamic `import`, `Worker`,
remote subresources, dangerous URL schemes, iframe/srcdoc surfaces, navigation APIs,
manifest/hash tampering, metadata lock drift, misplaced assets, and web-runtime
dependencies.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED | Default shell Java is unavailable: macOS reported `Unable to locate a Java Runtime.` |
| `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported OpenJDK `17.0.17`. |
| `/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/java -version` | PASS but not Stage 1 JDK | Reported OpenJDK `21.0.6`; not used for the Gradle gates in this batch. |
| `adb devices` | PASS with device blocker | Command ran, but no attached device or running emulator was listed. |
| `bash -n tools/test_renderer_asset_audit.sh && bash tools/test_renderer_asset_audit.sh` | PASS | New and existing renderer audit regression cases passed, including the added `XMLHttpRequest`, `WebSocket`, `EventSource`, `sendBeacon`, `SharedWorker`, `importScripts`, and `serviceWorker` fail-closed cases. |
| `bash tools/audit_renderer_assets.sh && bash tools/audit_renderer_request_blocking.sh` | PASS | Confirmed no Android WebView/android.webkit implementation, no web app runtime dependency, no vendored JS/CSS/font renderer asset tree, and enforced request-policy test coverage for bundled assets, metadata lock blocking, remote/dangerous URL blocking, percent-encoded URL blocking, external navigation, and iframe blocking. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew projects --no-daemon` | PASS | `BUILD SUCCESSFUL in 14s`. Project graph: root `fastmd-android`, `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew stage1AndroidRendererAssetGates --no-daemon` | PASS | `BUILD SUCCESSFUL in 55s`. Ran `auditRendererAssets`, `auditRendererRequestBlocking`, `testRendererAssetAudit`, and `stage1AndroidRendererAssetGates`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew lint --no-daemon` | BLOCKED | Reached `:core:extractDebugAnnotations`, then failed resolving `com.android.tools.lint:lint-gradle:31.13.2` from Google Maven because `https://dl.google.com/.../lint-gradle-31.13.2.pom` timed out. Build failed in `3m 47s`. Kotlin daemon also logged `IllegalArgumentException: 25.0.1` and fell back to non-daemon compilation before the dependency-resolution blocker. |

## Checklist Evidence For Supervisor

The supervisor can mark these Android L11 items complete based on this report plus
the source files named below:

- L11 `Add local renderer packaging/offline tests if JS renderer assets are used.`
  Evidence: `android/tools/test_renderer_asset_audit.sh` passes native fallback with
  no vendored assets and a synthetic app-local JS/CSS/font asset fixture under
  `app/src/main/assets/fastmd-renderers/` with SHA-256 manifest and metadata lock.
- L11 `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
  Android evidence: no WebView surface exists; `android/tools/audit_renderer_request_blocking.sh`
  passes; `android/tools/test_renderer_asset_audit.sh` fails closed if a WebView marker
  appears before request-blocking coverage exists; `android/core/src/test/java/com/fastmd/mobile/core/render/RichRendererAssetPolicyTest.kt`
  covers renderer request allow/block decisions.
- L11 `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
  Evidence: `android/tools/test_renderer_asset_audit.sh` passes manifest/hash positive
  and negative cases, including missing, stale, misplaced, unlisted, malformed,
  escaping, metadata-inconsistent, and self-hashing manifests.

The supervisor can mark this Android L12 item complete:

- L12 `Run Android ./gradlew projects.`
  Evidence: the JDK 17 wrapper command above passed and printed the expected module graph.

The supervisor should keep this Android L12 item open:

- L12 `Run Android ./gradlew lint.`
  Blocker: Google Maven timed out resolving `com.android.tools.lint:lint-gradle:31.13.2`
  from `dl.google.com:443`.

Device-backed L12 validations remain open:

- `:app:connectedDebugAndroidTest`, API 27 validation, low-memory/small-screen validation,
  and modern device validation remain blocked because `adb devices` lists no attached
  device or running emulator in this environment.

## Files Touched

- `android/tools/test_renderer_asset_audit.sh`
- `android/docs/reports/stage1-android-l11-l12-renderer-network-api-batch54-20260506.md`
