# Stage 1 Android L11 Gradle Renderer Gates - 2026-05-05

## Scope

This bounded Android live-lane batch advanced the earliest still-open Android-owned
L11 renderer gate cluster without touching shared `Docs/**` checklists or any iOS
files.

The three conditional L11 items are:

- Add local renderer packaging/offline tests if JS renderer assets are used.
- Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
- Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.

Android currently uses native fallback render surfaces for Mermaid/math and has no
vendored JS/CSS/font renderer asset tree. The gate therefore remains conditional at
runtime, but this batch made the Android enforcement path first-class in Gradle.

## Implementation Evidence

- Added root Gradle task `auditRendererAssets`.
- Added root Gradle task `testRendererAssetAudit`.
- Added aggregate root Gradle task `stage1AndroidRendererAssetGates`.
- Wired `stage1AndroidRendererAssetGates` into Android module `check` tasks for
  modules that apply `com.android.application` or `com.android.library`.
- Updated `android/README.md` so the renderer asset gates are listed both as direct
  shell audits and as the Gradle task `gradle stage1AndroidRendererAssetGates`.

The existing script-backed regression coverage verifies:

- Native fallback passes when no vendored renderer assets are present.
- App-local renderer assets under `app/src/main/assets/fastmd-renderers/` pass only
  with a valid SHA-256 manifest.
- Missing manifests fail.
- Renderer assets outside the app-local asset root fail.
- Remote subresources, CDN-style references, iframes, `javascript:` URLs, and
  `data:` URLs fail.
- Stale hashes fail.
- Packaged assets missing from the manifest fail.
- Manifest paths escaping the asset root fail.
- WebView implementation markers fail until a separate request-blocking gate exists.

## Validation

| Command | Result | Notes |
| --- | --- | --- |
| `bash tools/test_renderer_asset_audit.sh` | PASS | All positive and negative renderer asset audit regression cases behaved as expected. |
| `bash tools/audit_renderer_assets.sh` | PASS | Current Android tree has no WebView/android.webkit implementation, no React Native/Flutter/Cordova runtime dependency, and no vendored JS/CSS/font renderer asset tree. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle projects` | PASS | System Gradle resolved root project `fastmd-android` and modules `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle stage1AndroidRendererAssetGates --dry-run` | PASS | Gradle task graph includes `:auditRendererAssets`, `:testRendererAssetAudit`, and `:stage1AndroidRendererAssetGates`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle stage1AndroidRendererAssetGates` | PASS | Gradle executed `:auditRendererAssets` and `:testRendererAssetAudit`; all current-tree and regression renderer asset checks passed. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle :core:check --dry-run` | PASS | Module `check` graph includes `:stage1AndroidRendererAssetGates` through the root Gradle wiring. |

## Supervisor Checklist Recommendation

The supervising session can treat these Android L11 conditional renderer checklist
items as complete/not-applicable for the current native fallback implementation, with
ongoing regression coverage:

- Add local renderer packaging/offline tests if JS renderer assets are used.
- Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
- Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.

Evidence paths:

- `android/build.gradle.kts`
- `android/tools/audit_renderer_assets.sh`
- `android/tools/test_renderer_asset_audit.sh`
- `android/docs/reports/stage1-android-l11-gradle-renderer-gates-20260505.md`

Do not mark SDK/dependency-backed Android L12 build, lint, assemble, unit-test, or
device validation gates complete from this batch. This batch only validates the
Android-owned L11 renderer asset gate path.
