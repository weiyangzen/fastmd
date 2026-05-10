# Stage 1 Android L11 Renderer Request Blocking Batch 52

Date: 2026-05-06
Scope: Android-only live lane batch.
Ownership: `android/**`.

## Blueprint Items Advanced

- L11: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
- L13: Record validation reports under `android/docs/reports/`.

## Implementation Evidence

- Added `tools/audit_renderer_request_blocking.sh`.
- Wired `auditRendererRequestBlocking` into `stage1AndroidRendererAssetGates` in `build.gradle.kts`.
- Wired `audit_renderer_request_blocking.sh` into `stage1AndroidSecurityAuditReport` through the existing `auditSecurityReport` task.
- Updated `README.md` so the Android-local audit list includes the request-blocking gate.

The new audit verifies the Android renderer request policy and its unit-test coverage for:

- bundled `file:///android_asset/fastmd-renderers/` allowlisting,
- remote `http://`, `https://`, and protocol-relative request blocking,
- external navigation blocking,
- `javascript:`, `data:`, `blob:`, `filesystem:`, and `content:` denial,
- percent-encoded dangerous URL denial,
- iframe denial.

If future Android main code adds `WebView` or `android.webkit`, the audit requires:

- routing requests through `RichRendererRequestPolicy.decide`,
- `shouldInterceptRequest` handling,
- `shouldOverrideUrlLoading` handling,
- explicit iframe request classification.

Current Stage 1 Android main code contains no `WebView` or `android.webkit`, so Mermaid/math rich blocks remain native fallback surfaces and no JS/CSS/font renderer assets are packaged.

## Validation Commands

Run from `android/`.

```bash
bash tools/audit_renderer_request_blocking.sh
```

Result: pass.

Key output:

```text
PASS: Renderer request policy is a first-class Android core contract.
PASS: Renderer request policy has an explicit iframe request class.
PASS: Renderer request policy has an explicit network-request block reason.
PASS: Renderer request policy has an explicit external-navigation block reason.
PASS: Renderer request policy has an explicit javascript: URL block reason.
PASS: Renderer request policy has an explicit data: URL block reason.
PASS: Renderer request policy has an explicit content URI block reason.
PASS: Renderer request policy has an explicit non-renderer-file block reason.
PASS: Unit tests cover allowlisting of bundled Android renderer assets.
PASS: Unit tests cover remote and dangerous renderer request blocking.
PASS: Unit tests cover percent-encoded dangerous renderer requests.
PASS: Unit tests cover external navigation and iframe blocking.
PASS: No Android WebView or android.webkit implementation is present; rich Markdown uses native fallback surfaces.
```

```bash
bash tools/audit_renderer_assets.sh
```

Result: pass.

Key output:

```text
PASS: No Android WebView or android.webkit implementation is present.
PASS: No React Native, Flutter, Cordova, or equivalent web runtime dependency is present.
PASS: No vendored JS/CSS/font renderer asset tree is present; Android rich blocks use native fallback paths.
```

```bash
bash tools/test_renderer_asset_audit.sh
```

Result: pass.

Key output:

```text
PASS: native fallback has no vendored renderer assets
PASS: app-local JS/CSS/font renderer assets verify with SHA-256 manifest
PASS: renderer assets require hash manifest
PASS: renderer assets require platform-local metadata lock
PASS: renderer asset metadata lock must be included in hash manifest
PASS: renderer assets outside app-local asset root fail
PASS: renderer assets outside app main source set fail
PASS: renderer assets with remote subresources fail
PASS: renderer assets with network-capable browser APIs fail
PASS: renderer assets with dynamic import APIs fail
PASS: renderer assets with worker APIs fail
PASS: WebView implementation fails until request-blocking tests exist
PASS: React Native runtime dependency fails the native Android lane audit
```

```bash
JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew stage1AndroidRendererAssetGates
```

Result: pass.

Key output:

```text
> Task :auditRendererAssets
> Task :auditRendererRequestBlocking
> Task :testRendererAssetAudit
> Task :stage1AndroidRendererAssetGates
BUILD SUCCESSFUL in 49s
3 actionable tasks: 3 executed
```

```bash
JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew projects
```

Result: pass.

Key output:

```text
Root project 'fastmd-android'
+--- Project ':app'
+--- Project ':core'
\--- Project ':feature'
     +--- Project ':feature:library'
     +--- Project ':feature:reader'
     \--- Project ':feature:settings'
BUILD SUCCESSFUL in 2s
```

```bash
JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew stage1AndroidSecurityAuditReport
```

Result: pass.

Key output:

```text
> Task :auditSecurityReport
PASS: No uses-permission declarations are present.
PASS: No broad storage, notification, or default INTERNET permission is present.
PASS: Only the document-entry MainActivity is exported.
PASS: No Android WebView implementation is present in Stage 1 main code.
PASS: No Android WebView or android.webkit implementation is present.
PASS: No vendored JS/CSS/font renderer asset tree is present; Android rich blocks use native fallback paths.
PASS: Renderer request policy is a first-class Android core contract.
PASS: Unit tests cover remote and dangerous renderer request blocking.
PASS: Unit tests cover external navigation and iframe blocking.
> Task :stage1AndroidSecurityAuditReport
BUILD SUCCESSFUL in 5s
```

```bash
JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew :core:testDebugUnitTest
```

Result: blocked by external dependency download timeout before tests executed.

Blocker output:

```text
Execution failed for task ':core:testDebugUnitTest'.
Could not download collection-ktx-1.4.0.jar (androidx.collection:collection-ktx:1.4.0)
Could not GET 'https://dl.google.com/dl/android/maven2/androidx/collection/collection-ktx/1.4.0/collection-ktx-1.4.0.jar'.
Connect to dl.google.com:443 failed: Connect timed out
Could not download concurrent-futures-1.1.0.jar (androidx.concurrent:concurrent-futures:1.1.0)
Could not GET 'https://dl.google.com/dl/android/maven2/androidx/concurrent/concurrent-futures/1.1.0/concurrent-futures-1.1.0.jar'.
Connect to dl.google.com:443 failed: Connect timed out
BUILD FAILED in 3m 7s
```

Note: a default `./gradlew stage1AndroidRendererAssetGates` attempt without `JAVA_HOME` failed before Gradle launched with `Unable to locate a Java Runtime`; rerunning with the documented JDK 17 path passed.
