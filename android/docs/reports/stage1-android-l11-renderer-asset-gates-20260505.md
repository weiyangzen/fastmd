# Stage 1 Android L11 Renderer Asset Gates - 2026-05-05

## Scope

This batch addressed the Android-owned conditional L11 renderer gates:

- Add local renderer packaging/offline tests if JS renderer assets are used.
- Add WebView request-blocking tests if local JS renderer surfaces are used.
- Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.

The current Android implementation does not use Android `WebView`, `android.webkit`, vendored JS/CSS/font renderer assets, React Native, Flutter, Cordova, CDN assets, or remote renderer subresources. Mermaid and math remain native fallback render surfaces.

## Implementation Evidence

- Added `android/tools/audit_renderer_assets.sh`.
- The audit fails closed if `WebView` or `android.webkit` appears in Android main code without a separate renderer request-blocking gate.
- The audit fails if React Native, Flutter, Cordova, or equivalent web-runtime dependencies appear in Android code or Gradle configuration.
- The audit detects `src/main/assets/fastmd-renderers` trees. If assets are introduced, it requires them to be app-local under `app/src/main/assets/fastmd-renderers`, requires `renderer-assets.sha256`, verifies SHA-256 hashes with `shasum -a 256 -c`, and scans JS/CSS/HTML renderer assets for remote URLs, CDN references, iframes, `javascript:` URLs, and `data:` URLs.
- With no renderer asset tree present, the audit records the conditional renderer gates as not applicable for the current native-fallback implementation.

## Validation

| Command | Result | Notes |
| --- | --- | --- |
| `bash tools/audit_renderer_assets.sh` | PASS | No Android WebView/android.webkit implementation, no React Native/Flutter/Cordova runtime dependency, and no vendored JS/CSS/font renderer asset tree were found. |
| `bash tools/audit_stage1_manifest.sh` | PASS | No `uses-permission`, broad storage, notification, default `INTERNET`, backup-enabled posture, unexpected exported component, or WebView implementation was found; release hardening posture remains present. |
| `gradle projects` | PASS | System Gradle resolved the Android project graph for `:app`, `:core`, `:feature:reader`, `:feature:library`, and `:feature:settings`. |
| `gradle :core:testDebugUnitTest` | BLOCKED | Android SDK location is missing: Gradle requested `ANDROID_HOME` or `sdk.dir` in `/Users/wangweiyang/GitHub/fastmd/android/local.properties`. |

## Supervisor Checklist Recommendation

The supervising session can treat the three Android L11 renderer conditional checklist items as complete/not-applicable for the current Android implementation, using this report plus `android/tools/audit_renderer_assets.sh` as evidence:

- Add local renderer packaging/offline tests if JS renderer assets are used.
- Add WebView request-blocking tests if local JS renderer surfaces are used.
- Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.

Do not mark SDK-dependent Android validation gates complete from this batch. `:core:testDebugUnitTest`, lint, build, assemble, connected tests, API 27, low-memory/small-screen, and modern-device validation remain open until the Android SDK location is configured and device/emulator validation is available.
