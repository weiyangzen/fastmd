# Stage 1 Android L11/L12 Validation Refresh Batch 66 - 2026-05-06

Android-owned bounded batch for the live lane.

## Scope

- Re-validate the Android conditional renderer packaging/offline gates.
- Re-validate the Android WebView/request-blocking gate posture.
- Attempt the earliest open Android L12 Gradle gate: `./gradlew lint`.
- Keep checklist reconciliation out of `Docs/**`; this file is the Android-local evidence handoff.

## Source Posture

- Android implementation remains native Kotlin and Jetpack Compose.
- No Android `WebView` / `android.webkit` renderer surface is present.
- No React Native, Flutter, Cordova, remote WebView shell, or web app runtime dependency is present.
- No vendored JS/CSS/font renderer asset tree is present; Mermaid/math remain native readable fallback surfaces.
- `local.properties` exists and points at `/Users/wangweiyang/Library/Android/sdk`.
- Default shell `java` is not available, so Gradle validation used explicit JDK 17:
  `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew projects --no-daemon` | PASS | Gradle loaded root project `fastmd-android` and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. Build successful in 13s. |
| `bash tools/audit_renderer_assets.sh && bash tools/audit_renderer_request_blocking.sh && bash tools/test_renderer_asset_audit.sh && bash tools/test_renderer_request_blocking_audit.sh` | PASS | Script-backed renderer gates passed native fallback, no web runtime, no WebView surface, no vendored renderer asset tree, request-policy contract checks, synthetic app-local JS/CSS/font hash-manifest success, and negative cases for remote/dangerous subresources, iframe/srcdoc, dynamic code, network APIs, stale/malformed manifests, and unrouted WebView markers. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew stage1AndroidRendererAssetGates --no-daemon` | PASS | Gradle task executed `auditRendererAssets`, `auditRendererRequestBlocking`, `testRendererAssetAudit`, and `testRendererRequestBlockingAudit`; build successful in 1m 17s. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew lint --no-daemon` | BLOCKED | Gradle reached `:core:extractDebugAnnotations`, then failed resolving `com.android.tools.lint:lint-gradle:31.13.2` from `https://dl.google.com/dl/android/maven2/...` because the connection to `dl.google.com:443` timed out. This is a dependency download blocker; lint did not complete and the L12 lint item must remain open. |

## Supervisor Completion Candidates

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
  - Android evidence: `tools/test_renderer_asset_audit.sh`, Gradle `stage1AndroidRendererAssetGates`, and this report.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
  - Android evidence: no Android WebView surface is present; `RichRendererRequestPolicy` and `tools/test_renderer_request_blocking_audit.sh` verify the fail-closed request-blocking contract for any future WebView-capable renderer.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
  - Android evidence: `tools/test_renderer_asset_audit.sh` and Gradle `stage1AndroidRendererAssetGates` verify valid app-local JS/CSS/font assets only with SHA-256 manifest and metadata lock, and fail stale, missing, malformed, escaping, unlisted, and self-hashing manifests.
- L13: Record validation reports under `android/docs/reports/`.
  - Evidence: this Android-local report.

## Items Kept Open

- L12: Run Android `./gradlew lint`.
  - Blocker: dependency download timeout for `com.android.tools.lint:lint-gradle:31.13.2` from `dl.google.com`.
- Remaining L12 compile/test/assemble/device validation gates were not attempted in this bounded batch.
