# Stage 1 Android L11 Renderer Percent-Encoding Request Policy Batch

Date: 2026-05-06

## Scope

This Android-only batch hardened the local rich-renderer request policy used by
conditional Mermaid/math renderer surfaces. The current Stage 1 Android
implementation still uses native Kotlin/Compose fallback rendering and does not
package a WebView renderer or vendored JS/CSS/font renderer assets.

## Implementation

- Updated `core/src/main/java/com/fastmd/mobile/core/render/RichRendererAssetPolicy.kt`
  to classify one level of percent-encoded dangerous renderer URLs before
  request allow/block decisions.
- Kept local renderer asset allowlisting strict: encoded `file:` renderer asset
  URLs and encoded path traversal remain blocked instead of being decoded into
  an allowed asset path.
- Preserved explicit dangerous-scheme classification before the generic
  external-navigation block so encoded `javascript:` navigation is still
  reported as `JavascriptUrl`.
- Added focused coverage in
  `core/src/test/java/com/fastmd/mobile/core/render/RichRendererAssetPolicyTest.kt`
  for percent-encoded `https:`, `javascript:`, `data:`, `content:`, `file:`,
  and encoded traversal forms.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED | Default shell has no Java runtime: `Unable to locate a Java Runtime.` |
| `./gradlew projects --no-daemon` | BLOCKED | Default shell has no Java runtime: `Unable to locate a Java Runtime.` |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew projects --no-daemon` | PASS | Gradle listed `:app`, `:core`, `:feature:reader`, `:feature:library`, and `:feature:settings`; `BUILD SUCCESSFUL in 12s`. |
| `bash tools/audit_renderer_assets.sh` | PASS | No Android `WebView`/`android.webkit`, no React Native/Flutter/Cordova-equivalent runtime, and no vendored JS/CSS/font renderer asset tree. |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Regression audit covered native fallback, app-local SHA-256-manifested assets, missing/stale/malformed manifests, misplaced assets, remote subresources, percent-encoded remote URLs, dangerous URLs, external navigation APIs, WebView marker failure, and React Native dependency failure. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew stage1AndroidRendererAssetGates --no-daemon` | PASS | `:auditRendererAssets`, `:testRendererAssetAudit`, and `:stage1AndroidRendererAssetGates` passed; final rerun `BUILD SUCCESSFUL in 23s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew :core:compileDebugUnitTestKotlin --no-daemon` | PASS | Kotlin main and unit-test sources compiled after the request-policy change; `BUILD SUCCESSFUL in 30s`. |
| `bash tools/audit_stage1_manifest.sh` | PASS | No permissions, no broad storage/media/notification/default `INTERNET`, `allowBackup=false`, cleartext disabled, only `MainActivity` exported, no WebView implementation, and release hardening present. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew :core:testDebugUnitTest stage1AndroidRendererAssetGates --no-daemon` | BLOCKED | Kotlin compilation reached `:core:compileDebugUnitTestKotlin` and the renderer gates passed, but `:core:testDebugUnitTest` failed before tests ran because Gradle could not download `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0` from `https://dl.google.com/dl/android/maven2/...`; both GET requests timed out. |

## Checklist Evidence

The supervisor can use this report as Android evidence for the conditional L11
renderer request-blocking/local asset gate posture:

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
- L13: Record validation reports under `android/docs/reports/`.

The three L11 renderer items remain conditional for Android because no Android
WebView renderer or vendored JS/CSS/font renderer asset tree is present in this
Stage 1 implementation. The Android gates now also classify percent-encoded
dangerous renderer requests before any future renderer surface can accidentally
treat them as ordinary unknown URLs.

## Open Validation

Do not mark `:core:testDebugUnitTest` complete from this batch. The task was
blocked by dependency downloads from `dl.google.com`, not by a test assertion.
