# Stage 1 Android L11 Renderer Encoded Offline Gate Batch 62

Date: 2026-05-06 11:41 CST
Lane: FastMD Stage 1 Mobile Android live lane
Scope: Android-owned `android/**` only

## Batch Selection

Earliest open Android-owned checklist cluster from the Stage 1 snapshot:

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.

Current Android posture remains native-first:

- No vendored JS/CSS/font renderer asset tree exists under `app/src/main/assets/fastmd-renderers/`.
- No Android `WebView` or `android.webkit` implementation exists in main source.
- Mermaid/math rich Markdown blocks use native readable fallback surfaces.

This batch tightened the Kotlin package verifier for any future vendored renderer package. It now scans normalized asset text variants, so dangerous URL/navigation/network markers hidden behind common encodings are rejected before a local renderer package can be accepted.

## Implementation Evidence

Changed Android files:

- `core/src/main/java/com/fastmd/mobile/core/render/RichRendererAssetPolicy.kt`
  - `LocalRendererAssetPackageVerifier.verifyOfflinePackage(...)` now scans raw lowercased renderer asset text plus normalized variants.
  - Added repeated percent-decoding for packaged `.js`, `.css`, `.html`, and `.htm` renderer assets.
  - Added JavaScript escape decoding for `\xNN`, `\uNNNN`, and `\u{N...}` sequences.
  - Added HTML numeric entity decoding for decimal and hexadecimal entities.
  - Offline isolation checks now reject dangerous markers found after those normalizations.
- `core/src/test/java/com/fastmd/mobile/core/render/RichRendererAssetPolicyTest.kt`
  - Added `localRendererPackageVerifierRejectsEncodedDangerousMarkers`.
  - The regression covers JavaScript unicode-escaped remote URLs, braced unicode escapes, hex-escaped network APIs, HTML entity-encoded `javascript:` URLs, and double-percent-encoded remote URLs.

## Validation Evidence

Environment:

- JDK 17 used for Gradle commands: `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`
- Android SDK used for Gradle commands: `/Users/wangweiyang/Library/Android/sdk`

Commands:

```bash
bash tools/audit_renderer_assets.sh
```

Result: PASS.

Evidence:

- No Android `WebView` or `android.webkit` implementation is present.
- No React Native, Flutter, Cordova, or equivalent web runtime dependency is present.
- No vendored JS/CSS/font renderer asset tree is present; Android rich blocks use native fallback paths.

```bash
bash tools/audit_renderer_request_blocking.sh
```

Result: PASS.

Evidence:

- Renderer request policy is a first-class Android core contract.
- Unit tests cover bundled renderer asset allowlisting, metadata file request blocking, remote/dangerous request blocking, percent-encoded dangerous requests, external navigation, and iframe blocking.
- No Android `WebView` or `android.webkit` implementation is present.

```bash
bash tools/test_renderer_asset_audit.sh
```

Result: PASS.

Evidence:

- Native fallback passes without vendored renderer assets.
- Valid app-local JS/CSS/font renderer fixture verifies with SHA-256 manifest.
- Negative fixtures fail for missing manifests, missing metadata, misplaced assets, non-main source-set assets, stale hashes, malformed manifests, metadata URL markers, remote/content/protocol-relative/encoded URLs, HTML entity encodings, JavaScript escape encodings, iframe/srcdoc/form/meta-refresh surfaces, browser network APIs, worker APIs, WebView markers, and React Native dependency markers.

```bash
JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home \
ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk \
./gradlew projects --no-daemon
```

Result: PASS.

Evidence:

- Root project: `fastmd-android`.
- Modules listed: `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`.

```bash
JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home \
ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk \
./gradlew :core:compileDebugKotlin :core:compileDebugUnitTestKotlin --no-daemon
```

Result: PASS.

Evidence:

- `:core:compileDebugKotlin` completed.
- `:core:compileDebugUnitTestKotlin` completed.
- An existing Kotlin daemon still reported Java `25.0.1`, but Gradle fell back to non-daemon compilation under the requested JDK 17 and the build completed successfully.

```bash
JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home \
ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk \
./gradlew :core:testDebugUnitTest --tests 'com.fastmd.mobile.core.render.RichRendererAssetPolicyTest' --no-daemon
```

Result: BLOCKED.

Evidence:

- The changed main and test Kotlin sources reached fallback compilation after an existing Kotlin daemon reported Java `25.0.1`.
- The task then failed resolving `:core:debugUnitTestRuntimeClasspath`.

Blocker:

- Gradle timed out downloading AndroidX artifacts from Google Maven:
  - `https://dl.google.com/dl/android/maven2/androidx/collection/collection-ktx/1.4.0/collection-ktx-1.4.0.jar`
  - `https://dl.google.com/dl/android/maven2/androidx/concurrent/concurrent-futures/1.1.0/concurrent-futures-1.1.0.jar`

This keeps the broader L12 `:core:testDebugUnitTest` validation item open.

```bash
JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home \
ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk \
./gradlew stage1AndroidRendererAssetGates --no-daemon
```

Result: PASS.

Evidence:

- `:auditRendererAssets` passed.
- `:auditRendererRequestBlocking` passed.
- `:testRendererAssetAudit` passed.
- Final rerun after the robustness adjustment completed with `BUILD SUCCESSFUL in 1m 8s`.

## Supervisor Checklist Candidates

The supervisor can use this Android-local implementation and validation evidence for:

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
  - Evidence: Kotlin package verifier now rejects raw, percent-encoded, JavaScript-escaped, and HTML entity-encoded dangerous markers; `stage1AndroidRendererAssetGates` passed.
- L11 Android portion: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
  - Evidence: Android has no current WebView surface; `audit_renderer_request_blocking.sh` passed and fails future WebView-capable code unless it routes requests and navigations through the blocking contract.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
  - Evidence: `test_renderer_asset_audit.sh` and `RichRendererAssetPolicyTest` cover manifest/hash verification, metadata lock verification, stale hashes, unlisted packaged assets, malformed manifests, and encoded offline-bypass regressions.
- L13 Android evidence item: Record validation reports under `android/docs/reports/`.
  - Evidence: this report.

Do not mark L12 `:core:testDebugUnitTest` complete from this batch because Google Maven dependency download timeouts blocked unit-test runtime classpath resolution.
