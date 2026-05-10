# Stage 1 Android L11 Renderer Network API Gate - 2026-05-06

## Scope

Android live lane bounded batch for the earliest open Android-owned L11 conditional
renderer gate cluster:

- Add local renderer packaging/offline tests if JS renderer assets are used.
- Add WebView request-blocking tests if local JS renderer surfaces are used.
- Add renderer asset manifest/hash verification tests if JS/CSS/font assets are
  vendored.

The current Android implementation remains native Kotlin with Jetpack Compose.
There is no Android `WebView`, `android.webkit`, React Native, Flutter, Cordova,
remote WebView shell, or vendored JS/CSS/font renderer asset tree in this batch.
Mermaid and math continue to render through native readable fallback cards.

This batch hardens the Android-local renderer asset audit so any future vendored
JS/CSS/HTML renderer asset fails closed if it uses browser APIs that can initiate
network requests even without a hardcoded remote URL literal.

## Changed Android Files

- `android/tools/audit_renderer_assets.sh`
- `android/tools/test_renderer_asset_audit.sh`
- `android/docs/reports/stage1-android-l11-renderer-network-api-gate-20260506.md`

## Implementation Evidence

`android/tools/audit_renderer_assets.sh` now rejects local renderer assets that
reference network-capable browser APIs:

- `fetch(...)`
- `XMLHttpRequest`
- `WebSocket(...)`
- `EventSource(...)`
- `sendBeacon(...)`
- `importScripts(...)`

This complements the existing audit checks that already reject:

- remote URL forms, including `http://`, `https://`, protocol-relative URLs, and
  percent-encoded remote schemes.
- `javascript:`, `data:`, `file:`, and `content:` references.
- CDN indicators such as `cdnjs`, `unpkg`, and `jsdelivr`.
- iframe/srcdoc usage.
- external navigation APIs such as `window.location`, `document.location`,
  `location.href`, `location.assign`, `location.replace`, and `window.open`.
- missing, stale, malformed, escaping, self-hashing, or incomplete
  `renderer-assets.sha256` manifests.
- renderer assets outside `app/src/main/assets/fastmd-renderers/`.
- Android WebView markers before a request-blocking implementation gate exists.
- React Native, Flutter, Cordova, Capacitor, or equivalent web runtime markers.

`android/tools/test_renderer_asset_audit.sh` now includes a synthetic failing
project with a vendored renderer asset containing `fetch(path)`. The regression
label is:

```text
renderer assets with network-capable browser APIs fail
```

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `bash tools/audit_renderer_assets.sh` | PASS | Confirmed no Android WebView/android.webkit implementation, no React Native/Flutter/Cordova runtime, and no vendored JS/CSS/font renderer asset tree are present. |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Covered native fallback, app-local hashed assets, missing manifests, misplaced assets, remote/content/protocol-relative/percent-encoded/uppercase dangerous references, external navigation APIs, the new network-capable browser API failure, stale hashes, unlisted packaged assets, escaping manifest paths, self-hashing manifests, malformed manifests, WebView marker failure, and React Native runtime failure. |
| `bash tools/audit_stage1_manifest.sh` | PASS | Confirmed no permissions, no broad storage/media/notification/default `INTERNET`, `allowBackup=false`, cleartext disabled, only `MainActivity` exported, no WebView implementation, and release hardening posture. |
| `bash tools/audit_rich_fixture_render.sh` | PASS | Confirmed rich fixture coverage remains native Kotlin/Compose; Mermaid and block math render as native readable source cards; remote images stay placeholders; no web app runtime is present. |
| `java -version` | BLOCKED with default shell Java | `/usr/bin/java` reports `Unable to locate a Java Runtime.` |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home java -version` | PASS | OpenJDK `17.0.17` from Homebrew is available when `JAVA_HOME` is set explicitly. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew projects --no-daemon` | PASS | Gradle evaluated root project `fastmd-android` and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew stage1AndroidRendererAssetGates --no-daemon` | PASS | Ran `:auditRendererAssets` and `:testRendererAssetAudit`; the new network-capable browser API regression case passed as an expected failure in the synthetic unsafe renderer project. |

## Supervisor Checklist Candidates

The supervisor can consider the following Android-owned checklist items complete
or not-applicable for the current native-fallback Android implementation, using
this report plus the updated audit scripts as evidence:

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
  Evidence: `bash tools/test_renderer_asset_audit.sh` and
  `./gradlew stage1AndroidRendererAssetGates --no-daemon` pass, including
  app-local asset placement, offline remote-reference rejection, and manifest
  integrity cases.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces
  are used.
  Android evidence: no Android WebView surface exists; the renderer audit fails if
  a WebView marker appears before a separate request-blocking gate exists, and the
  existing `RichRendererRequestPolicy` core tests define fail-closed request
  decisions for any future local rich renderer surface.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets
  are vendored.
  Evidence: the renderer audit self-test passes positive SHA-256 manifest
  verification and negative missing/stale/unlisted/escaping/self-hashing/malformed
  manifest cases; the current tree has no vendored renderer assets.

Keep full Android compile, lint, assemble, device, API 27, low-memory, and modern
device validation items open until those specific gates are run and reconciled by
the supervising session.
