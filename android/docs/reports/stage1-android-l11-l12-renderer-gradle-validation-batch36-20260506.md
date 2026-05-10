# Stage 1 Android L11/L12 Renderer And Gradle Validation Batch 36

Date: 2026-05-06
Lane: FastMD Stage 1 Mobile Android live lane
Scope: Android-only. No `ios/**`, `Docs/Stage1_Mobile_Blueprint.md`, or `Docs/todos_20260505.md` edits.

## Batch Selection

Earliest still-open Android-owned cluster in the authoritative blueprint:

- L11 automated renderer gates:
  - Add local renderer packaging/offline tests if JS renderer assets are used.
  - Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
  - Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
- L12 Android validation:
  - Minimum local Gradle project validation.
  - Android core unit-test gate attempt.

The current Android implementation has no vendored JS/CSS/font renderer asset tree and no WebView renderer. Rich Mermaid/math blocks use native fallback. This batch validates the conditional gates and records the current Gradle blocker state.

## Environment

- Working directory: `/Users/wangweiyang/GitHub/fastmd/android`
- `java -version`: blocked
  - Output: `The operation couldn’t be completed. Unable to locate a Java Runtime.`
- `./gradlew --version`: blocked by the same missing Java runtime on `PATH`.
- System Gradle path: `/usr/local/bin/gradle`
- `gradle --version`: Gradle `9.3.0`
- System Gradle launcher JVM: Homebrew OpenJDK `25.0.1`
- Android SDK: `sdk.dir=/Users/wangweiyang/Library/Android/sdk`
- `adb devices`: no attached device or running emulator.

## Validation Commands

### `./gradlew projects`

Result: blocker.

The checked-in wrapper could not start because `java` is not available on `PATH`:

```text
The operation couldn’t be completed. Unable to locate a Java Runtime.
Please visit http://www.java.com for information on installing Java.
```

Impact: wrapper-based validation remains open until JDK 17 is installed/configured for the shell environment.

### `gradle projects`

Result: pass.

System Gradle successfully evaluated the Android project:

```text
Root project 'fastmd-android'
+--- Project ':app'
+--- Project ':core'
\--- Project ':feature'
     +--- Project ':feature:library'
     +--- Project ':feature:reader'
     \--- Project ':feature:settings'

BUILD SUCCESSFUL in 42s
```

### `bash tools/audit_renderer_assets.sh`

Result: pass.

Key output:

```text
PASS: No Android WebView or android.webkit implementation is present.
PASS: No React Native, Flutter, Cordova, or equivalent web runtime dependency is present.
PASS: No vendored JS/CSS/font renderer asset tree is present; Android rich blocks use native fallback paths.
```

### `bash tools/test_renderer_asset_audit.sh`

Result: pass.

Coverage exercised by the regression script:

- Native fallback path passes with no vendored renderer assets.
- Synthetic app-local JS/CSS/font renderer assets under `app/src/main/assets/fastmd-renderers/` pass only with valid SHA-256 manifest and metadata lock.
- Missing manifest, missing metadata lock, misplaced assets, non-main source-set assets, unlisted packaged assets, stale hashes, malformed manifest lines, malformed metadata lines, escaping paths, dot segments, percent escapes, whitespace paths, remote URLs, protocol-relative URLs, percent-encoded remote URLs, double-encoded remote URLs, `javascript:`/`data:`/`content:` references, navigation APIs, meta refresh, forms, network-capable browser APIs, WebView implementation, and React Native dependency all fail as expected.

Terminal summary ended with:

```text
PASS: renderer asset metadata lock malformed lines fail
PASS: WebView implementation fails until request-blocking tests exist
PASS: React Native runtime dependency fails the native Android lane audit
```

### `gradle stage1AndroidRendererAssetGates`

Result: pass.

The Gradle task ran `auditRendererAssets` and `testRendererAssetAudit`:

```text
> Task :auditRendererAssets
PASS: No Android WebView or android.webkit implementation is present.
PASS: No React Native, Flutter, Cordova, or equivalent web runtime dependency is present.
PASS: No vendored JS/CSS/font renderer asset tree is present; Android rich blocks use native fallback paths.

> Task :testRendererAssetAudit
PASS: native fallback has no vendored renderer assets
PASS: app-local JS/CSS/font renderer assets verify with SHA-256 manifest
...
PASS: WebView implementation fails until request-blocking tests exist
PASS: React Native runtime dependency fails the native Android lane audit

> Task :stage1AndroidRendererAssetGates
BUILD SUCCESSFUL in 17s
```

### `gradle :core:testDebugUnitTest`

Result: blocker.

The command reached `:core:testDebugUnitTest` but failed because uncached AndroidX dependencies could not be downloaded from `dl.google.com`:

```text
Execution failed for task ':core:testDebugUnitTest'.
> Could not resolve all files for configuration ':core:debugUnitTestRuntimeClasspath'.
   > Could not download collection-ktx-1.4.0.jar (androidx.collection:collection-ktx:1.4.0)
      > Connect to dl.google.com:443 ... failed: Connect timed out
   > Could not download concurrent-futures-1.1.0.jar (androidx.concurrent:concurrent-futures:1.1.0)
      > Connect to dl.google.com:443 ... failed: Connect timed out

BUILD FAILED in 3m 58s
```

Additional environment note: Kotlin daemon also reported `java.lang.IllegalArgumentException: 25.0.1` under the Homebrew OpenJDK 25 Gradle JVM before falling back to non-daemon compilation. The final failing cause for this command was dependency download timeout, but the lane should still prefer the blueprint-required JDK 17 for repeatable Android validation.

## Evidence Paths

- Renderer policy source: `core/src/main/java/com/fastmd/mobile/core/render/RichRendererAssetPolicy.kt`
- Renderer policy unit tests: `core/src/test/java/com/fastmd/mobile/core/render/RichRendererAssetPolicyTest.kt`
- Renderer source-level audit: `tools/audit_renderer_assets.sh`
- Renderer audit regression script: `tools/test_renderer_asset_audit.sh`
- Gradle renderer gate wiring: `build.gradle.kts`
- This report: `docs/reports/stage1-android-l11-l12-renderer-gradle-validation-batch36-20260506.md`

## Supervisor Checklist Recommendations

The supervisor can mark these Android-owned items complete, backed by this report and the existing Android-local source/tests:

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
  - Evidence: `tools/test_renderer_asset_audit.sh` synthetic app-local JS/CSS/font asset pass case plus missing/offline/hash failure cases; `gradle stage1AndroidRendererAssetGates` passed.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
  - Android evidence: no Android WebView surface is present; `tools/test_renderer_asset_audit.sh` fails a synthetic WebView implementation until a separate request-blocking gate exists; `RichRendererAssetPolicyTest.kt` verifies request decisions block network, external navigation, `javascript:`, `data:`, `content:`, iframe, unknown schemes, and non-renderer files.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
  - Evidence: `tools/test_renderer_asset_audit.sh` verifies valid SHA-256 manifests and metadata locks for synthetic local assets and fails missing, stale, malformed, escaping, unlisted, and misplaced asset cases; `gradle stage1AndroidRendererAssetGates` passed.

Keep these Android L12 items open:

- Android `./gradlew lint`, `./gradlew build`, `./gradlew :core:testDebugUnitTest`, `./gradlew :feature:reader:testDebugUnitTest`, `./gradlew :app:assembleDebug`, and device gates remain open until JDK 17/wrapper execution and network dependency resolution are stable.
- Android `:core:testDebugUnitTest` specifically remains open because the attempted system-Gradle run failed on `dl.google.com` dependency download timeouts.
- Android connected/device validation remains open because `adb devices` listed no attached device or emulator.
