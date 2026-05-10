# Stage 1 Android L12 Validation Refresh Batch 27 - 2026-05-06

## Scope

This bounded Android live-lane batch refreshed the earliest still-open
Android-owned validation evidence that can be advanced without touching iOS or
the authoritative shared Docs checklist.

No Android source implementation files were changed in this batch. The only
repository change is this Android-local validation report.

## Environment

- Working directory: `/Users/wangweiyang/GitHub/fastmd/android`
- Report timestamp: `2026-05-06 06:10:20 CST`
- Shell default Java: blocked. `java -version` reports `Unable to locate a Java Runtime.`
- Explicit validation JDK: `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`
- Explicit validation Java version: OpenJDK `17.0.17`
- Android SDK location: `local.properties` contains `sdk.dir=/Users/wangweiyang/Library/Android/sdk`
- Gradle entry point: `./gradlew`
- Gradle wrapper version observed through successful wrapper runs: Gradle `9.3.0`
- Device availability: `adb devices` returned an empty device list.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED | The shell default Java runtime is not configured: `Unable to locate a Java Runtime.` |
| `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported OpenJDK `17.0.17` Homebrew runtime. |
| `./gradlew projects --no-daemon` | BLOCKED | Without explicit `JAVA_HOME`, the wrapper is blocked by the missing shell default Java runtime. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew projects --no-daemon` | PASS | Root project `fastmd-android` resolved modules `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 15s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew stage1AndroidRendererAssetGates --no-daemon` | PASS | Ran `:auditRendererAssets`, `:testRendererAssetAudit`, and `:stage1AndroidRendererAssetGates`; `BUILD SUCCESSFUL in 22s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew :core:testDebugUnitTest --no-daemon` | BLOCKED | Gradle reached `:core:testDebugUnitTest`, then timed out fetching `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0` from `https://dl.google.com/dl/android/maven2/...`; `BUILD FAILED in 3m 19s`. |
| `bash tools/audit_renderer_assets.sh` | PASS | No Android `WebView` or `android.webkit` implementation, no React Native/Flutter/Cordova/equivalent runtime dependency, and no vendored JS/CSS/font renderer asset tree were found. |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Regression cases passed for native fallback, app-local SHA-256 renderer assets, missing/misplaced/stale/unlisted/malformed assets, dangerous remote/content/protocol-relative/encoded/uppercase references, external navigation APIs, WebView implementation markers, and React Native dependency markers. |
| `bash tools/audit_stage1_manifest.sh` | PASS | No permission declarations, no broad storage/media/notification/default `INTERNET`, `allowBackup=false`, cleartext disabled, only `MainActivity` exported, no WebView implementation, and release hardening posture present. |
| `bash tools/audit_rich_fixture_render.sh` | PASS | Rich fixture coverage passed for native parser/render model coverage, Compose reader paths, wide-surface containment, remote image placeholders, Mermaid/math source-card fallbacks, and absence of WebView/web-runtime rendering. |
| `bash tools/audit_performance_report.sh` | PASS | Captured Android runtime profile limits and fixture size matrix; source-level performance posture audit completed. |
| `bash tools/audit_font_scale_tiers.sh` | PASS | Captured all four font tiers across font scales `0.85`, `1.00`, `1.30`, and `2.00`. |
| `bash tools/audit_accessibility_semantics.sh` | PASS | Android accessibility semantics audit completed. |
| `adb devices` | BLOCKED | `adb` is available, but no emulator or physical Android device is attached. |

## Source-Level Evidence

The current Android implementation remains native Kotlin and Jetpack Compose.
No Android `WebView`, `android.webkit`, React Native, Flutter, Cordova,
remote WebView shell, or vendored JS/CSS/font renderer asset tree is present.

The Gradle-backed renderer asset gate and script-backed regression tests verify
the Android side of the conditional L11 renderer requirements:

- Native fallback passes when no JS/CSS/font renderer assets are vendored.
- Any future renderer asset tree must live under
  `app/src/main/assets/fastmd-renderers/`.
- Future renderer assets must include a valid SHA-256 manifest.
- Future renderer assets fail closed for remote subresources, dangerous URL
  schemes, iframe/source-document markers, and external navigation APIs.
- WebView implementation markers fail the audit until request-blocking coverage
  exists.

The script-backed L12 source reports also remain current for:

- Android performance report capture.
- Android security audit report capture.
- Android rich fixture render report capture.
- Android font scale validation evidence.
- Android accessibility semantics evidence.

## Blockers Preserved

- Shell default Java remains unconfigured. Wrapper commands require explicit
  `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`
  in this environment.
- `./gradlew :core:testDebugUnitTest` remains open because required AndroidX
  artifacts timed out from `dl.google.com`.
- The broader compile-backed L12 gates remain open until dependency resolution
  is reliable: `./gradlew lint`, `./gradlew build`,
  `./gradlew :feature:reader:testDebugUnitTest`, and
  `./gradlew :app:assembleDebug`.
- `./gradlew :app:connectedDebugAndroidTest`, Android API 27 validation,
  low-memory/small-screen validation, and modern-device validation remain open
  until an emulator or physical Android device is attached.

## Supervisor Checklist Recommendation

The supervising session can use this Android-local evidence for:

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used, Android portion.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
- L12: Capture Android performance report.
- L12: Capture Android security audit report.
- L12: Capture rich fixture render report, Android portion.
- L13: Record validation reports under `android/docs/reports/`.

Do not mark these Android L12 gates complete from this batch:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.
