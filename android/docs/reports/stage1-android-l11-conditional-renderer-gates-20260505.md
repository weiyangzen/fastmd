# Stage 1 Android L11 Conditional Renderer Gates - 2026-05-05

## Scope

This bounded Android live-lane batch advanced the earliest still-open Android-owned L11 conditional renderer gates without editing shared `Docs/**`, `ios/**`, or `.cron/**` files.

The current Android implementation remains native Kotlin/Jetpack Compose for ordinary Markdown and rich fallback blocks. No Android `WebView`, `android.webkit`, React Native, Flutter, Cordova, remote WebView shell, or vendored JS/CSS/font renderer asset tree is present.

## Android Changes

- Updated `android/README.md` to list `bash tools/test_renderer_asset_audit.sh` as a local Android-owned audit gate.
- Added this Android-local report under `android/docs/reports/`.

No Android app source code changed in this batch.

## Conditional Renderer Gate Evidence

The Android renderer asset audit covers the conditional L11 items as follows:

- If no vendored JS/CSS/font renderer assets are present, native fallback rendering is accepted and no packaging/offline renderer asset gate is required.
- If a future renderer asset tree is added, it must live under `app/src/main/assets/fastmd-renderers/`.
- Any future renderer asset tree must include `renderer-assets.sha256`.
- The manifest must verify with `shasum -a 256 -c renderer-assets.sha256`.
- Packaged assets missing from the manifest fail the audit.
- Manifest paths that escape the asset root fail the audit.
- Remote subresources and dangerous URL forms in JS/CSS/HTML assets fail the audit, including `http://`, `https://`, CDN references, `iframe`, `srcdoc`, `javascript:`, and `data:`.
- A WebView implementation currently fails the audit until a separate request-blocking test gate exists.

## Validation Commands

All commands were run from `/Users/wangweiyang/GitHub/fastmd/android`.

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew projects` | BLOCKED | Wrapper attempted to download `https://services.gradle.org/distributions/gradle-9.3.0-bin.zip` and failed with `java.net.UnknownHostException: services.gradle.org`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle projects` | PASS | System Gradle resolved root project `fastmd-android` with modules `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle lint` | BLOCKED | Reached `:core:checkDebugAarMetadata`, then failed resolving `androidx.datastore:datastore-preferences:1.1.1`, `org.jetbrains.kotlin:kotlin-stdlib:1.9.24`, and `androidx.compose:compose-bom:2024.06.00` from `https://dl.google.com/dl/android/maven2/`; DNS reported `dl.google.com` unavailable. |
| `bash tools/audit_renderer_assets.sh` | PASS | Confirmed no Android WebView/android.webkit implementation, no React Native/Flutter/Cordova runtime dependency, and no vendored JS/CSS/font renderer asset tree. |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Covered native fallback pass, app-local renderer asset pass, missing manifest failure, misplaced asset failure, remote subresource failure, uppercase dangerous URL failure, stale SHA-256 manifest failure, unlisted packaged asset failure, escaping manifest path failure, and WebView-without-request-blocking-gate failure. |
| `bash tools/audit_stage1_manifest.sh` | PASS | Confirmed no permissions, no broad storage/notification/default `INTERNET`, `allowBackup=false`, cleartext disabled, only document-entry `MainActivity` exported, no WebView implementation, and release hardening posture. |

## Blockers Preserved

- Wrapper-based validation remains blocked by DNS failure for `services.gradle.org`.
- The system Gradle fallback can evaluate the project graph, but compile-backed Android gates remain blocked by DNS failure for `dl.google.com`.
- `./gradlew lint`, `./gradlew build`, unit tests, assemble, and connected Android tests should remain open until wrapper and dependency resolution are available.
- Device/emulator validation remains open until suitable API 27, low-memory/small-screen, and modern Android targets are available.

## Supervisor Checklist Recommendation

The supervising session can use this report as Android-lane evidence for:

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
- L13: Record validation reports under `android/docs/reports/`.

These L11 items are conditional for Android in the current native-fallback implementation. The evidence above shows no local JS renderer assets or WebView surface are present, and the Android-local audit self-test will fail future JS renderer or WebView additions unless the required packaging, manifest/hash, remote-subresource, and request-blocking gates are added.

Keep L12 Gradle, compile, assemble, connected device, API 27, low-memory/small-screen, modern device, and Android performance validation gates open from this batch.
