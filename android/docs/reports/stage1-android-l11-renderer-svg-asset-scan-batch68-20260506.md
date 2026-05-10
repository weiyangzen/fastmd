# Stage 1 Android L11 Renderer SVG Asset Scan Batch 68

Timestamp: 2026-05-06 12:48:02 CST

## Scope

Android live lane bounded batch for the earliest still-open Android-owned L11 renderer asset gates.

This batch hardens the conditional local renderer packaging/offline/hash path for SVG renderer assets. SVG was already an allowed vendored renderer asset extension, but the offline text scan only covered JS, MJS, CSS, HTML, and HTM. If a future isolated Mermaid/math renderer vendors SVG assets under `app/src/main/assets/fastmd-renderers/`, those SVG assets now receive the same offline isolation scan for active script content, event handlers, external navigation, and remote subresource markers.

## Android Files Changed

- `android/core/src/main/java/com/fastmd/mobile/core/render/RichRendererAssetPolicy.kt`
  - Added `.svg` to `LocalRendererAssetPackageVerifier` scannable renderer asset extensions.
  - Added active SVG/HTML markers and event-handler pattern coverage to the offline forbidden scan: `<script`, `onload=`, `onclick=`, and `onerror=`.
- `android/core/src/test/java/com/fastmd/mobile/core/render/RichRendererAssetPolicyTest.kt`
  - Added `localRendererPackageVerifierRejectsSvgActiveContentAndRemoteReferences`.
  - Covers SVG `<script>`, remote image references, and SVG event-handler navigation.
- `android/tools/audit_renderer_assets.sh`
  - Added `<script` and event-handler markers to the source-level renderer asset audit.
  - Added `*.svg` files to the renderer asset text scan.
- `android/tools/test_renderer_asset_audit.sh`
  - Added synthetic project regressions for SVG script content, SVG remote references, and SVG event handlers.

## Validation

Command:

```bash
cd android
bash tools/test_renderer_asset_audit.sh
```

Result: PASS.

Evidence:

- Native fallback with no vendored renderer assets passed.
- App-local JS/CSS/font renderer asset manifest path passed.
- Existing negative cases for missing manifests, metadata locks, remote URLs, encoded URLs, dangerous schemes, iframe/srcdoc, browser network APIs, dynamic code execution, stale hashes, malformed manifests, and invalid metadata all passed.
- New SVG cases passed:
  - `renderer SVG assets with active script content fail`
  - `renderer SVG assets with remote references fail`
  - `renderer SVG assets with event handlers fail`

Command:

```bash
cd android
bash tools/audit_renderer_assets.sh
```

Result: PASS.

Observed output:

```text
PASS: No Android WebView or android.webkit implementation is present.
PASS: No React Native, Flutter, Cordova, or equivalent web runtime dependency is present.
PASS: No vendored JS/CSS/font renderer asset tree is present; Android rich blocks use native fallback paths.
```

Command:

```bash
cd android
./gradlew projects
```

Result: BLOCKED.

Exact blocker:

```text
The operation couldn’t be completed. Unable to locate a Java Runtime.
Please visit http://www.java.com for information on installing Java.
```

Command:

```bash
cd android
./gradlew :core:testDebugUnitTest --tests 'com.fastmd.mobile.core.render.RichRendererAssetPolicyTest'
```

Result: BLOCKED.

Exact blocker:

```text
The operation couldn’t be completed. Unable to locate a Java Runtime.
Please visit http://www.java.com for information on installing Java.
```

Command:

```bash
cd android
java -version
```

Result: BLOCKED with the same missing Java Runtime message.

Command:

```bash
cd android
/usr/libexec/java_home -V
```

Result: BLOCKED with the same missing Java Runtime message.

## Blueprint Checklist Evidence

Supervisor can consider the Android side of these L11 checklist items advanced by this report and the changed Android files:

- `L11 — Add local renderer packaging/offline tests if JS renderer assets are used.`
  - Evidence: `android/tools/test_renderer_asset_audit.sh` now regression-tests SVG active content, SVG remote references, and SVG event handlers in synthetic vendored renderer asset trees.
  - Validation: `bash tools/test_renderer_asset_audit.sh` passed.
- `L11 — Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
  - Evidence: existing manifest/hash regression audit remains passing after SVG scan hardening, including stale hash and missing metadata cases.
  - Validation: `bash tools/test_renderer_asset_audit.sh` passed.

Keep L12 Gradle validation items open until a JDK 17 runtime is available to the Android lane.
