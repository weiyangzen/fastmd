# Stage 1 Android L11 Renderer Contract Hardening - 2026-05-06

## Scope

This bounded Android-owned batch hardened the conditional L11 renderer gates without touching `ios/**`, shared `Docs/**`, or `.cron/**`.

The current Android implementation remains native Kotlin with Jetpack Compose for ordinary Markdown and rich fallback blocks. No Android `WebView`, `android.webkit`, React Native, Flutter, Cordova, remote WebView shell, or vendored JS/CSS/font renderer asset tree is present.

## Android Changes

- `core/src/test/java/com/fastmd/mobile/core/render/RichRendererAssetPolicyTest.kt`
  - Verifies every declared rich-renderer surface uses no vendored assets when native fallback is selected.
  - Verifies every native fallback surface keeps network requests, external navigation, `javascript:`, `data:`, iframes, and remote subresources blocked.
  - Extends local asset path rejection to `file://` and `content://` URI forms.
- `tools/audit_renderer_assets.sh`
  - Keeps the existing fail-closed audit for WebView, vendored renderer assets, hash manifests, and remote subresources.
  - Expands web-runtime detection to case-insensitive React Native spellings, Flutter, Cordova, and Capacitor forms.
  - Treats `file:` and `content:` references inside JS/CSS/HTML renderer assets as blocked subresource forms.
- `tools/test_renderer_asset_audit.sh`
  - Adds regression coverage for `content://` renderer subresource references.
  - Adds regression coverage for React Native Gradle dependency detection.

## Validation

Commands are recorded with exact results from `/Users/wangweiyang/GitHub/fastmd/android`.

| Command | Result | Notes |
| --- | --- | --- |
| `bash tools/audit_renderer_assets.sh` | PASS | No Android WebView/android.webkit implementation, no React Native/Flutter/Cordova/Capacitor runtime dependency, and no vendored JS/CSS/font renderer asset tree were found. |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Covered native fallback pass, app-local renderer asset pass, missing manifest failure, misplaced asset failure, remote/protocol-relative/content URI subresource failures, uppercase dangerous URL failure, external navigation API failure, stale SHA-256 manifest failure, unlisted packaged asset failure, escaping manifest path failure, WebView-without-request-blocking-gate failure, and React Native dependency failure. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle stage1AndroidRendererAssetGates --no-daemon` | PASS | Gradle evaluated the project and executed `auditRendererAssets` plus `testRendererAssetAudit`; `BUILD SUCCESSFUL in 8s`. |
| `bash tools/audit_stage1_manifest.sh` | PASS | Confirmed no permissions, no broad storage/notification/default `INTERNET`, `allowBackup=false`, cleartext disabled, only document-entry `MainActivity` exported, no WebView implementation, and release hardening posture. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew projects --no-daemon` | BLOCKED | Wrapper attempted to download `https://services.gradle.org/distributions/gradle-9.3.0-bin.zip` and failed with `java.net.UnknownHostException: services.gradle.org`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :core:testDebugUnitTest --no-daemon` | BLOCKED | Same wrapper distribution DNS blocker: `java.net.UnknownHostException: services.gradle.org`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle projects --no-daemon` | PASS | System Gradle resolved root project `fastmd-android` with modules `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 4s`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle :core:testDebugUnitTest --no-daemon` | BLOCKED | Project evaluation and early resource tasks started, then `:core:compileDebugKotlin` failed resolving Android/Kotlin artifacts from `dl.google.com`, including `org.jetbrains.kotlin:kotlin-stdlib:1.9.24` and `androidx.datastore:datastore-preferences:1.1.1`. |

## Blockers Preserved

- Wrapper-based validation remains blocked by DNS failure for `services.gradle.org`.
- Compile-backed Android gates remain blocked by dependency resolution failure for `dl.google.com`.
- `./gradlew lint`, `./gradlew build`, module unit tests, assemble, connected Android tests, API 27 validation, low-memory/small-screen validation, and modern-device validation should remain open until wrapper/dependency resolution and device or emulator targets are available.

## Supervisor Checklist Recommendation

If the validation commands above pass or are blocked only by recorded environment constraints, the supervising session can use this report as additional Android-lane evidence for:

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
- L13: Record validation reports under `android/docs/reports/`.

These L11 renderer items are conditional for Android because the current implementation has no WebView or vendored JS/CSS/font renderer assets. The Android-local audit fails future additions unless the required local packaging, manifest/hash, blocked-subresource, web-runtime exclusion, and WebView request-blocking gates are satisfied.
