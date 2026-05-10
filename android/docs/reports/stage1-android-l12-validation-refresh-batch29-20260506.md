# Stage 1 Android L12 Validation Refresh Batch 29 - 2026-05-06

## Scope

This bounded Android live-lane batch refreshed the earliest still-open
Android-owned validation surface without touching iOS or the authoritative
shared Docs checklist.

No Android app/source implementation files were changed in this batch. The only
repository change is this Android-local validation report.

## Environment

- Working directory: `/Users/wangweiyang/GitHub/fastmd/android`
- Report timestamp: `2026-05-06 06:47:19 CST`
- Shell default Java: blocked. `java -version` reports `Unable to locate a Java Runtime.`
- Explicit validation JDK: `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`
- Android SDK location: `local.properties` contains `sdk.dir=/Users/wangweiyang/Library/Android/sdk`
- Gradle entry point: `./gradlew`
- Gradle wrapper version observed through successful wrapper runs: Gradle `9.3.0`
- Device availability: `adb devices` returned an empty attached-device list.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED | The shell default Java runtime is not configured: `Unable to locate a Java Runtime.` |
| `./gradlew projects --no-daemon` | BLOCKED | Without explicit `JAVA_HOME`, the wrapper is blocked by the missing shell default Java runtime. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew projects --no-daemon` | PASS | Root project `fastmd-android` resolved modules `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 13s`. |
| `bash tools/audit_stage1_manifest.sh` | PASS | No permission declarations, no broad storage/media/notification/default `INTERNET`, `allowBackup=false`, cleartext disabled, only `MainActivity` exported, no WebView implementation, and release hardening posture present. |
| `bash tools/audit_renderer_assets.sh` | PASS | No Android `WebView` or `android.webkit` implementation, no React Native/Flutter/Cordova/equivalent runtime dependency, and no vendored JS/CSS/font renderer asset tree were found. |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Regression cases passed for native fallback, app-local SHA-256 renderer assets, missing/misplaced/stale/unlisted/malformed assets, dangerous remote/content/protocol-relative/encoded/uppercase references, external navigation APIs, network-capable APIs, WebView implementation markers, and React Native dependency markers. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew stage1AndroidRendererAssetGates stage1AndroidSecurityAuditReport stage1AndroidPerformanceReport stage1AndroidRichFixtureRenderReport --no-daemon` | PASS | Ran the Gradle-backed renderer asset, security, performance, and rich fixture report tasks; `BUILD SUCCESSFUL in 26s`. |
| `bash tools/audit_performance_report.sh` | PASS | Captured Android runtime profile limits and fixture size matrix; source-level performance posture audit completed. |
| `bash tools/audit_rich_fixture_render.sh` | PASS | Rich fixture coverage passed for native parser/render model coverage, Compose reader paths, wide-surface containment, remote image placeholders, Mermaid/math source-card fallbacks, and absence of WebView/web-runtime rendering. |
| `adb devices` | BLOCKED | `adb` is available, but no emulator or physical Android device is attached. Output contained only `List of devices attached`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew lint --no-daemon` | BLOCKED | Gradle reached `:core:extractDebugAnnotations`, then timed out fetching `com.android.tools.lint:lint-gradle:31.13.2` from `https://dl.google.com/dl/android/maven2/...`; `BUILD FAILED in 4m 44s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew build --no-daemon` | BLOCKED | Gradle reached `:feature:library:compileDebugKotlin`, then timed out fetching `androidx.compose.compiler:compiler:1.5.14` from `https://dl.google.com/dl/android/maven2/...`; `BUILD FAILED in 3m 25s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew :core:testDebugUnitTest --no-daemon` | BLOCKED | Gradle reached `:core:testDebugUnitTest`, then timed out fetching `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0` from `https://dl.google.com/dl/android/maven2/...`; `BUILD FAILED in 4m 52s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew :feature:reader:testDebugUnitTest --no-daemon` | BLOCKED | Gradle reached `:feature:reader:compileDebugKotlin`, then timed out fetching `androidx.compose.compiler:compiler:1.5.14` from `https://dl.google.com/dl/android/maven2/...`; `BUILD FAILED in 4m 46s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew :app:assembleDebug --no-daemon` | BLOCKED | Gradle reached `:app:checkDebugDuplicateClasses`, then timed out fetching AndroidX runtime artifacts from `https://dl.google.com/dl/android/maven2/...`, including `lifecycle-common-java8:2.8.4`, `lifecycle-common-jvm:2.8.4`, `concurrent-futures:1.1.0`, `collection-ktx:1.4.0`, and `annotation-jvm:1.8.0`; `BUILD FAILED in 3m 35s`. |

## Notes

The compile-backed Gradle attempts initially reported Kotlin daemon/incremental
cache errors under `core/build/kotlin/compileDebugKotlin/cacheable`, including
`storage size = 4096, file size = 4096` and missing
`core_debug.kotlin_module`, while multiple Gradle tasks were compiling in
parallel. Gradle fell back to non-daemon Kotlin compilation. Subsequent task
failures were artifact-resolution timeouts against `dl.google.com`, not source
compile errors from Android code in this batch.

The Android implementation remains native Kotlin and Jetpack Compose. No
Android `WebView`, `android.webkit`, React Native, Flutter, Cordova, remote
WebView shell, or vendored JS/CSS/font renderer asset tree is present.

## Blockers Preserved

- Shell default Java remains unconfigured. Plain wrapper commands require
  explicit `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`
  in this environment.
- Compile-backed Gradle gates remain open because required AndroidX, Compose,
  and lint artifacts timed out from `dl.google.com:443`.
- Device-backed gates remain open because `adb devices` lists no attached
  emulator or physical Android device.
- Android API 27, low-memory/small-screen, and modern-device validation remain
  open until the corresponding device or emulator targets are available.

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
