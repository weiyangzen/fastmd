# Stage 1 Android L11 Renderer Metadata Escape Gate Batch 69

Timestamp: 2026-05-06 13:02:53 CST

## Scope

Android live lane bounded batch for the earliest still-open Android-owned L11 renderer
asset manifest/hash verification gate.

This batch hardens future vendored rich renderer metadata locks. Android currently has
no WebView renderer implementation and no vendored JS/CSS/font renderer asset tree; rich
Mermaid/math blocks remain native readable fallbacks. If a future isolated renderer is
vendored under `app/src/main/assets/fastmd-renderers/`, its `renderer-assets.lock`
metadata fields now reject hidden URL and dangerous-scheme markers after percent,
HTML-entity, and JavaScript-escape normalization.

## Android Files Changed

- `android/core/src/main/java/com/fastmd/mobile/core/render/RichRendererAssetPolicy.kt`
  - Extended renderer metadata field validation to scan normalized forms of upstream
    name, upstream version, and license notes.
  - Added rejection coverage for double-percent encoded, HTML numeric entity encoded,
    JavaScript unicode/hex escaped, and protocol-relative URL markers in metadata.
- `android/core/src/test/java/com/fastmd/mobile/core/render/RichRendererAssetPolicyTest.kt`
  - Added Kotlin contract assertions for metadata lock fields containing double-encoded
    URLs, HTML entity encoded URLs, JavaScript-escaped URLs, and protocol-relative CDN
    references.
- `android/tools/audit_renderer_assets.sh`
  - Added `validate_renderer_metadata_field` for source-level metadata lock audits.
  - Shell audit now rejects metadata URL markers in raw, HTML-entity encoded, and
    JavaScript-escaped forms, including double-percent escapes.
- `android/tools/test_renderer_asset_audit.sh`
  - Added synthetic-project regressions for double-encoded, HTML-entity encoded, and
    JavaScript-escaped renderer metadata URL markers.

## Validation

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
bash tools/test_renderer_asset_audit.sh
```

Result: PASS.

New regression cases passed:

- `renderer asset metadata lock double-encoded URL markers fail`
- `renderer asset metadata lock HTML entity URL markers fail`
- `renderer asset metadata lock JavaScript-escaped URL markers fail`

Command:

```bash
cd android
JAVA_HOME="/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home" ./gradlew projects --no-daemon
```

Result: PASS.

Evidence: Gradle discovered root project `fastmd-android` and modules `:app`, `:core`,
`:feature:library`, `:feature:reader`, and `:feature:settings`.

Command:

```bash
cd android
JAVA_HOME="/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home" ./gradlew :core:compileDebugUnitTestKotlin --offline --no-daemon
```

Result: PASS.

Evidence: Core main/test Kotlin compile tasks completed successfully from the local
cache.

Command:

```bash
cd android
JAVA_HOME="/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home" ./gradlew stage1AndroidRendererAssetGates --no-daemon
```

Result: PASS.

Evidence: Gradle aggregate renderer gates passed with 4 executed tasks:
`auditRendererAssets`, `auditRendererRequestBlocking`, `testRendererAssetAudit`, and
`testRendererRequestBlockingAudit`.

Command:

```bash
cd android
JAVA_HOME="/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home" ./gradlew :core:testDebugUnitTest --tests 'com.fastmd.mobile.core.render.RichRendererAssetPolicyTest' --no-daemon
```

Result: BLOCKED after Kotlin compilation.

Exact blocker:

```text
Execution failed for task ':core:testDebugUnitTest'.
> Could not resolve all files for configuration ':core:debugUnitTestRuntimeClasspath'.
   > Failed to transform collection-ktx-1.4.0.jar (androidx.collection:collection-ktx:1.4.0)
      > Could not GET 'https://dl.google.com/dl/android/maven2/androidx/collection/collection-ktx/1.4.0/collection-ktx-1.4.0.jar'.
         > Connect to dl.google.com:443 [dl.google.com/142.250.197.142, dl.google.com/2404:6800:4005:822:0:0:0:200e] failed: Connect timed out
   > Failed to transform concurrent-futures-1.1.0.jar (androidx.concurrent:concurrent-futures:1.1.0)
      > Could not GET 'https://dl.google.com/dl/android/maven2/androidx/concurrent/concurrent-futures/1.1.0/concurrent-futures-1.1.0.jar'.
         > Connect to dl.google.com:443 [dl.google.com/142.250.197.142, dl.google.com/2404:6800:4005:822:0:0:0:200e] failed: Connect timed out
```

The same run also hit the known local Kotlin daemon issue first:
`java.lang.IllegalArgumentException: 25.0.1`, then fell back to in-process compilation
and continued until the runtime dependency download timeout.

## Blueprint Checklist Evidence

Supervisor can use this report as Android evidence for:

- `L11 — Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
  - Evidence: Android Kotlin metadata lock contract tests and shell synthetic-project
    regressions now reject hidden URL markers in raw, percent-encoded,
    double-percent-encoded, HTML-entity-encoded, JavaScript-escaped, and
    protocol-relative forms.
  - Validation: `bash tools/test_renderer_asset_audit.sh`,
    `bash tools/audit_renderer_assets.sh`, `./gradlew stage1AndroidRendererAssetGates`,
    and `./gradlew :core:compileDebugUnitTestKotlin --offline` passed.

This also reinforces, but does not newly close, these already evidenced Android L11
conditional renderer gates:

- `L11 — Add local renderer packaging/offline tests if JS renderer assets are used.`
- `L11 — Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`

Keep broader L12 lint, build, assemble, full unit-test, instrumentation, API 27, and
device validation gates open. The targeted `:core:testDebugUnitTest` execution remains
blocked by `dl.google.com` dependency download timeouts in this environment.
