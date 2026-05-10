# Stage 1 Android L11 Renderer Offline Verifier Batch 59

Date: 2026-05-06 11:18:59 CST
Lane: FastMD Stage 1 Mobile Android live lane
Scope: Android-owned `android/**` only

## Batch Selection

Earliest open Android-owned cluster from `Docs/Stage1_Mobile_Blueprint.md`:

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.

The current Android implementation has no vendored JS/CSS/font renderer asset tree and no WebView implementation. This batch tightened the Kotlin package verifier so any future vendored `.js`, `.css`, `.html`, or `.htm` renderer asset package must remain offline and isolated in addition to proving hashes and metadata.

## Implementation Evidence

Changed Android files:

- `core/src/main/java/com/fastmd/mobile/core/render/RichRendererAssetPolicy.kt`
  - `LocalRendererAssetPackageVerifier.verifyOfflinePackage(...)` now verifies packaged renderer assets for offline isolation after SHA-256 manifest verification and metadata lock verification.
  - Scannable renderer assets reject network URL markers, dangerous URL schemes, CDN markers, iframe/srcdoc/form/meta refresh markers, external navigation APIs, and browser network APIs.
- `core/src/test/java/com/fastmd/mobile/core/render/RichRendererAssetPolicyTest.kt`
  - Added a package verifier regression covering remote URL and network API markers in otherwise correctly hashed vendored renderer assets.

## Validation Evidence

Environment discovery:

- Initial `./gradlew projects` without `JAVA_HOME` failed with: `Unable to locate a Java Runtime`.
- JDK 17 found at `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`.
- Android SDK found at `/Users/wangweiyang/Library/Android/sdk`.
- `local.properties` exists under `android/`.

Commands:

```bash
JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home \
ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk \
./gradlew projects
```

Result: PASS.

Evidence:

- Root project: `fastmd-android`.
- Modules listed: `:app`, `:core`, `:feature:library`, `:feature:reader`, `:feature:settings`.

```bash
bash tools/audit_renderer_assets.sh
```

Result: PASS.

Evidence:

- No Android `WebView` or `android.webkit` implementation is present.
- No React Native, Flutter, Cordova, or equivalent web runtime dependency is present.
- No vendored JS/CSS/font renderer asset tree is present; Android rich blocks use native fallback paths.

```bash
bash tools/test_renderer_asset_audit.sh
```

Result: PASS.

Evidence:

- Native fallback path passes without vendored renderer assets.
- App-local JS/CSS/font renderer fixture verifies with SHA-256 manifest.
- Negative fixtures fail for missing manifest, missing metadata lock, misplaced assets, non-main source-set assets, stale hash manifests, malformed manifests, metadata URL markers, remote subresources, content URI references, percent/double-encoded dangerous URLs, HTML entity-encoded dangerous URLs, iframe/srcdoc/form/meta-refresh surfaces, browser network APIs, worker APIs, WebView presence, and React Native dependency presence.

```bash
JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home \
ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk \
./gradlew stage1AndroidRendererAssetGates
```

Result: PASS.

Evidence:

- `:auditRendererAssets` passed.
- `:auditRendererRequestBlocking` passed.
- `:testRendererAssetAudit` passed.
- `:stage1AndroidRendererAssetGates` completed with `BUILD SUCCESSFUL in 47s`.

```bash
JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home \
ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk \
./gradlew :core:testDebugUnitTest
```

Result: BLOCKED after main and unit-test Kotlin compilation reached fallback execution.

Blocker:

- `:core:testDebugUnitTest` failed resolving `:core:debugUnitTestRuntimeClasspath`.
- Gradle timed out fetching AndroidX artifacts from `https://dl.google.com/dl/android/maven2/`, including:
  - `androidx.collection:collection-ktx:1.4.0`
  - `androidx.concurrent:concurrent-futures:1.1.0`

This keeps the broader L12 unit-test validation item open.

## Supervisor Checklist Candidates

The supervisor can consider the following Android portions complete based on implementation plus validation evidence in this report:

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
- L13 Android evidence item: Record validation reports under `android/docs/reports/`.

Do not mark Android L12 `:core:testDebugUnitTest` complete from this batch because Maven/Google artifact download timeout blocked the task.
