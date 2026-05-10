# Stage 1 Android L11 Renderer Gate Hardening - 2026-05-05

## Scope

This bounded Android live-lane batch hardened the Android-owned L11 conditional
renderer asset gates without editing shared `Docs/**`, `ios/**`, or `.cron/**`
files.

The Android implementation remains native Kotlin and Jetpack Compose for ordinary
Markdown and rich fallback blocks. No Android `WebView`, `android.webkit`, React
Native, Flutter, Cordova, remote WebView shell, or vendored JS/CSS/font renderer
asset tree is present.

## Android Changes

- Hardened `android/tools/audit_renderer_assets.sh` so future vendored renderer
  assets fail if they contain generic protocol-relative remote URLs such as
  `//example.com/renderer.js`.
- Hardened `android/tools/audit_renderer_assets.sh` so future vendored renderer
  assets fail if they contain asset-side external navigation APIs such as
  `window.location`, `document.location`, `location.href`, `location.assign`,
  `location.replace`, or `window.open`.
- Extended `android/tools/test_renderer_asset_audit.sh` with regression cases for
  protocol-relative remote URLs and external navigation APIs.
- Added this Android-local evidence report.

## Validation Commands

All commands were run from `/Users/wangweiyang/GitHub/fastmd/android`.

| Command | Result | Evidence |
| --- | --- | --- |
| `bash tools/audit_renderer_assets.sh` | PASS | Confirmed no Android WebView/android.webkit implementation, no React Native/Flutter/Cordova runtime dependency, and no vendored JS/CSS/font renderer asset tree. |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Covered native fallback pass, app-local SHA-256 manifest pass, missing manifest failure, misplaced asset failure, remote subresource failure, protocol-relative remote URL failure, uppercase dangerous URL failure, external navigation API failure, stale SHA-256 manifest failure, unlisted packaged asset failure, escaping manifest path failure, and WebView-without-request-blocking-gate failure. |
| `bash tools/audit_stage1_manifest.sh` | PASS | Confirmed no permissions, no broad storage/notification/default `INTERNET`, `allowBackup=false`, cleartext disabled, only document-entry `MainActivity` exported, no WebView implementation, and release hardening posture. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew projects` | BLOCKED | The checked-in wrapper attempted to download `https://services.gradle.org/distributions/gradle-9.3.0-bin.zip` and failed with `java.net.UnknownHostException: services.gradle.org`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle projects` | PASS | System Gradle resolved root project `fastmd-android` with modules `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle stage1AndroidRendererAssetGates` | PASS | System Gradle ran `auditRendererAssets` and `testRendererAssetAudit`; both passed with the hardened cases. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle lint` | BLOCKED | Failed at `:core:checkDebugAarMetadata` because Gradle could not resolve Android/Kotlin dependencies from `https://dl.google.com/dl/android/maven2/`; DNS reported `dl.google.com` unavailable. |

## Supervisor Checklist Recommendation

The supervising session can use this report as Android evidence for the Android side
of these L11 items:

- Add local renderer packaging/offline tests if JS renderer assets are used.
- Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are
  used.
- Add renderer asset manifest/hash verification tests if JS/CSS/font assets are
  vendored.

These L11 items are conditional for Android in the current native-fallback
implementation. The hardened gate proves no local JS/CSS/font renderer assets or
WebView surface are present today, and it will fail future renderer asset additions
unless the assets are app-local, hashed, offline, free of remote subresources, free
of external navigation hooks, and accompanied by an explicit WebView
request-blocking gate if WebView code appears.

The supervising session can also use this report as evidence for:

- L13: Record validation reports under `android/docs/reports/`.

Keep Android L12 wrapper, lint, build, unit test, assemble, connected device, API 27,
low-memory/small-screen, modern-device, and compile-backed validation gates open
from this batch. The wrapper still cannot fetch Gradle from `services.gradle.org`,
and compile-backed Gradle tasks still cannot resolve dependencies from
`dl.google.com` in this environment.
