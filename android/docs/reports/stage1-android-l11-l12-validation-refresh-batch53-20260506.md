# Stage 1 Android L11/L12 Validation Refresh Batch 53

Date: 2026-05-06
Lane: Android live lane
Scope: `android/**`

## Batch Selection

This batch advanced the earliest still-open Android-owned checklist cluster that can be
handled without touching iOS or the authoritative Docs checklist:

- L11 renderer packaging/offline tests if JS renderer assets are used.
- L11 WebView request-blocking tests if local JS renderer surfaces are used.
- L11 renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
- L12 Android Gradle validation retry for `projects`, `lint`, and `:core:testDebugUnitTest`.
- L12 Android source-level security, performance, and rich fixture render report capture.

The current Android implementation remains native Kotlin/Jetpack Compose. No Android
`WebView`, `android.webkit`, React Native, Flutter, Cordova, remote WebView shell, or
vendored JS/CSS/font renderer asset tree is present. Mermaid and math continue to use
native readable fallback cards.

## Environment

- Shell `java -version`: blocked because no Java runtime is on the default shell PATH.
- Android Studio bundled JBR exists at `/Applications/Android Studio.app/Contents/jbr/Contents/Home`.
- `android/local.properties` exists.
- Gradle wrapper exists at `android/gradlew` with distribution `gradle-9.3.0-bin.zip`.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED | Default shell reports: `Unable to locate a Java Runtime.` |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew projects --no-daemon` | PASS | Project graph evaluated successfully: root `fastmd-android` with `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 5s`. |
| `bash tools/audit_renderer_assets.sh && bash tools/test_renderer_asset_audit.sh && bash tools/audit_renderer_request_blocking.sh` | PASS | Confirmed native fallback with no vendored renderer asset tree; synthetic app-local JS/CSS/font assets pass only with SHA-256 manifest and metadata lock; missing/stale/misplaced/unlisted/malformed/escaping/remote/dangerous/WebView/web-runtime cases fail; request policy tests cover bundled-asset allowlisting, metadata lock blocking, remote/dangerous URL blocking, percent-encoded blocking, navigation blocking, and iframe blocking. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew stage1AndroidRendererAssetGates --no-daemon` | PASS | Gradle executed `auditRendererAssets`, `auditRendererRequestBlocking`, and `testRendererAssetAudit`; `BUILD SUCCESSFUL in 33s`. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew lint --no-daemon` | BLOCKED | Reached `:core:extractDebugAnnotations`, then failed resolving `com.android.tools.lint:lint-gradle:31.13.2` from Google Maven: `Connect to dl.google.com:443 ... timed out`; `BUILD FAILED in 3m 15s`. Kotlin daemon also reported `IllegalArgumentException: 25.0.1` and fell back to non-daemon compilation before the dependency-resolution failure. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew :core:testDebugUnitTest --no-daemon` | BLOCKED | Reached `:core:testDebugUnitTest`, then failed resolving uncached AndroidX runtime jars from Google Maven: `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0`; `Connect to dl.google.com:443 ... timed out`; `BUILD FAILED in 3m 12s`. Kotlin daemon again reported `IllegalArgumentException: 25.0.1` and fell back before the dependency-resolution failure. |
| `bash tools/audit_stage1_manifest.sh` | PASS | No permissions; no broad storage, notification, or default `INTERNET`; `allowBackup=false`; cleartext disabled; only document-entry `MainActivity` exported; no WebView implementation; release R8/resource shrinking/non-debuggable posture verified. |
| `bash tools/audit_performance_report.sh` | PASS | Captured Android performance profile limits for WatchCompact, LegacyEfficient, ModernStandard, and LargeScreen, plus local fixture size matrix; report audit completed. |
| `bash tools/audit_rich_fixture_render.sh` | PASS | Confirmed rich fixture coverage for headings, inline styles, links/autolinks/email, blockquotes, lists, task lists, tables, code fences, Mermaid/math fallback, images/media placeholders, footnotes, details/summary, generic HTML fallback, CJK/mixed-language content, escaped markers, native parser/render model block kinds, safe inline HTML mappings, Compose reader render paths, horizontal-scroll containment, remote-image privacy placeholder, and no web app runtime. |

## Checklist Evidence For Supervisor

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
  - Evidence: `tools/test_renderer_asset_audit.sh` passed directly and through Gradle `stage1AndroidRendererAssetGates`. It verifies native fallback when no assets are present and synthetic app-local JS/CSS/font assets only when packaged under `app/src/main/assets/fastmd-renderers` with SHA-256 manifest and metadata lock.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used, Android portion.
  - Evidence: no Android WebView surface exists; `tools/audit_renderer_request_blocking.sh` passed; `RichRendererRequestPolicyTest` coverage is enforced for bundled asset allowlisting, remote/dangerous request blocking, percent-encoded blocking, external navigation, and iframes.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
  - Evidence: `tools/test_renderer_asset_audit.sh` passed manifest/hash positive and negative cases, including missing, stale, misplaced, unlisted, malformed, escaping, metadata-inconsistent, and self-hashing manifests.
- L12: Run Android `./gradlew lint`.
  - Evidence: attempted with Android Studio JBR; remains open because Google Maven timed out resolving `com.android.tools.lint:lint-gradle:31.13.2`.
- L12: Run Android `./gradlew :core:testDebugUnitTest`.
  - Evidence: attempted with Android Studio JBR; remains open because Google Maven timed out resolving uncached AndroidX runtime jars.
- L12: Capture Android security audit report.
  - Evidence: `bash tools/audit_stage1_manifest.sh`, `bash tools/audit_renderer_assets.sh`, and `bash tools/audit_renderer_request_blocking.sh` passed in this batch.
- L12: Capture Android performance report.
  - Evidence: `bash tools/audit_performance_report.sh` passed in this batch.
- L12: Capture rich fixture render report, Android portion.
  - Evidence: `bash tools/audit_rich_fixture_render.sh` passed in this batch.

## Remaining Android Blockers

- The default shell still has no `java` runtime on PATH; Android validation currently requires explicit `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home'`.
- Android Studio's bundled JBR reports Java `25.0.1`, which triggers Kotlin daemon `IllegalArgumentException: 25.0.1`; Gradle falls back to non-daemon Kotlin compilation, but this is not a clean JDK 17 validation environment.
- Google Maven connectivity to `dl.google.com:443` remains unreliable and blocks `lint` and unit-test runtime dependency resolution for uncached artifacts.
