# Stage 1 Android L11 Renderer URL Hardening - 2026-05-06

## Scope

Bounded Android-owned batch for the earliest still-open Android checklist cluster:

- L11 local renderer packaging/offline tests if JS renderer assets are used.
- L11 WebView request-blocking tests if local JS renderer surfaces are used.
- L11 renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.

No `ios/**`, shared `Docs/**`, or `.cron/**` files were edited.

The current Android implementation remains native Kotlin with Jetpack Compose. No Android `WebView`, `android.webkit`, React Native, Flutter, Cordova, remote WebView shell, or vendored JS/CSS/font renderer asset tree is present.

## Android Changes

- `core/src/main/java/com/fastmd/mobile/core/render/RichRendererAssetPolicy.kt`
  - Hardened `RichRendererRequestPolicy` for future local rich-renderer surfaces.
  - Local Android asset requests under `file:///android_asset/fastmd-renderers/` now fail closed when the renderer path contains control whitespace, backslashes, query strings, fragments, percent-encoded bytes, or URI-scheme separators.
  - This keeps bundled renderer loads narrow and avoids accepting encoded traversal, encoded remote URLs, or query/fragment smuggling as local asset paths.
- `core/src/test/java/com/fastmd/mobile/core/render/RichRendererAssetPolicyTest.kt`
  - Added regression coverage for percent-encoded separators, encoded path traversal forms, backslashes, query strings, fragments, newline smuggling, and nested `https://` strings inside local asset URLs.
- `tools/audit_renderer_assets.sh`
  - Extended vendored renderer source scanning to reject common percent-encoded remote/scheme forms such as `https%3a`, `javascript%3a`, `data%3a`, `file%3a`, `content%3a`, `%2f`, and `%5c`.
- `tools/test_renderer_asset_audit.sh`
  - Added a synthetic regression project proving percent-encoded remote renderer references fail the asset audit.

## Validation

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` unless noted.

| Command | Result | Notes |
| --- | --- | --- |
| `java -version` | BLOCKED | Default shell Java runtime is unavailable: `Unable to locate a Java Runtime.` |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew projects --no-daemon` | PASS | Wrapper-backed Gradle evaluated root project `fastmd-android` and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 3s`. |
| `bash tools/audit_renderer_assets.sh` | PASS | No Android WebView/android.webkit implementation, no React Native/Flutter/Cordova runtime dependency, and no vendored JS/CSS/font renderer asset tree were found. |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Regression audit passed native fallback, app-local hashed renderer assets, missing/stale/incomplete/escaping manifests, misplaced assets, remote/protocol-relative/content URI references, percent-encoded remote references, uppercase dangerous URLs, external navigation APIs, WebView marker failure, and React Native dependency failure. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew stage1AndroidRendererAssetGates --no-daemon` | PASS | Gradle ran `:auditRendererAssets` and `:testRendererAssetAudit`; `BUILD SUCCESSFUL in 11s`. |
| `git diff --check -- android` from repo root | PASS | No whitespace errors were reported. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :core:testDebugUnitTest --no-daemon` | BLOCKED | Kotlin compilation completed and `:core:testDebugUnitTest` started, then Gradle failed resolving runtime jars from Google Maven: `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0` timed out from `https://dl.google.com/dl/android/maven2/...`. |

## Blockers Preserved

- Default shell `java` remains unavailable; Android validation requires the Android Studio bundled JBR through `JAVA_HOME`.
- Compile-backed Android unit-test validation remains open because Google Maven timed out resolving AndroidX runtime jars from `dl.google.com`.
- L12 `./gradlew lint`, `./gradlew build`, `./gradlew :feature:reader:testDebugUnitTest`, `./gradlew :app:assembleDebug`, `./gradlew :app:connectedDebugAndroidTest`, API 27 validation, low-memory/small-screen validation, and modern-device validation should remain open until dependency resolution and device or emulator targets are available.

## Supervisor Checklist Recommendation

The supervising session can use this Android-local report as additional evidence for:

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
- L13: Record validation reports under `android/docs/reports/`.

Do not mark Android compile-backed L12 gates complete from this batch.
