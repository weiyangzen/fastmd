# Stage 1 Android L12 Wrapper Validation Batch - 2026-05-06

## Scope

This Android live-lane batch advanced the earliest still-open Android-owned validation gates under
L12 without editing `Docs/**`, `ios/**`, or `.cron/**`.

The batch focused on wrapper-backed Gradle validation because earlier Android reports preserved a
wrapper distribution blocker. In this run, the Gradle wrapper successfully downloaded Gradle 9.3.0
and evaluated the Android project. Compile-backed gates then reached Android/Kotlin compilation and
were blocked by Maven Central returning HTTP 403 for uncached dependencies.

No product code changed in this batch. Android implementation remains native Kotlin with Jetpack
Compose and Android platform APIs. No Android WebView, React Native, Flutter, Cordova, remote
WebView app shell, or vendored JS/CSS/font renderer asset tree is present.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-wrapper-validation-batch-20260506.md`

## Validation Commands

All commands were run from `/Users/wangweiyang/GitHub/fastmd/android`.

| Command | Result | Notes |
| --- | --- | --- |
| `java -version` | BLOCKED | The shell default Java runtime is unavailable: `Unable to locate a Java Runtime.` |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew projects --no-daemon` | PASS | Wrapper downloaded Gradle 9.3.0 and listed root project `fastmd-android` with `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 9m 23s`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew lint --no-daemon` | BLOCKED | Reached `:core:compileDebugKotlin`, then Maven Central returned HTTP 403 for uncached `org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1` and `com.squareup.okio:okio-jvm:3.4.0` jars. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew build --no-daemon` | BLOCKED | Reached `:core:compileDebugKotlin`, then Maven Central returned HTTP 403 for uncached `kotlinx-coroutines-android-1.8.1.jar` and `okio-jvm-3.4.0.jar`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :core:testDebugUnitTest --no-daemon` | BLOCKED | Reached `:core:compileDebugKotlin`, then Maven Central returned HTTP 403 for `org.jetbrains.kotlin:kotlin-script-runtime:1.9.24`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :feature:reader:testDebugUnitTest --no-daemon` | BLOCKED | Reached `:core:compileDebugKotlin`, then Maven Central returned HTTP 403 for `org.jetbrains.kotlin:kotlin-script-runtime:1.9.24`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :app:assembleDebug --no-daemon` | BLOCKED | Reached `:core:compileDebugKotlin`, then Maven Central returned HTTP 403 for `org.jetbrains.kotlin:kotlin-script-runtime:1.9.24`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :app:connectedDebugAndroidTest --no-daemon` | BLOCKED | Reached `:core:compileDebugKotlin`, then Maven Central returned HTTP 403 for `org.jetbrains.kotlin:kotlin-script-runtime:1.9.24`; did not reach device execution. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :core:testDebugUnitTest --no-daemon --offline` | BLOCKED | Offline mode confirmed no cached versions are available for `kotlinx-coroutines-android-1.8.1.jar` and `okio-jvm-3.4.0.jar`. |
| `adb devices` | BLOCKED | `adb` is available, but no device or emulator target is attached. Output contained only `List of devices attached`. |
| `ls /Users/wangweiyang/Library/Android/sdk/system-images/android-27` | BLOCKED | No local API 27 system image directory is installed at that SDK path. |
| `bash tools/audit_stage1_manifest.sh` | PASS | No permissions, no broad storage/notification/default `INTERNET`, `allowBackup=false`, cleartext disabled, only `MainActivity` exported, no WebView implementation, and release hardening posture is present. |
| `bash tools/audit_performance_report.sh` | PASS | Source-level performance posture and fixture/profile matrix report passed. |
| `bash tools/audit_rich_fixture_render.sh` | PASS | Rich fixture coverage, native parser/render paths, safe Mermaid/math fallback, remote image privacy placeholder, and no web runtime were verified. |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Native fallback and future local renderer asset/hash/request-blocking regression cases passed. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew stage1AndroidRendererAssetGates --no-daemon` | PASS | Wrapper-backed renderer asset gate executed `auditRendererAssets` and `testRendererAssetAudit`; `BUILD SUCCESSFUL in 11s`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew stage1AndroidPerformanceReport --no-daemon` | PASS | Wrapper-backed performance report task executed `auditPerformanceReport`; `BUILD SUCCESSFUL in 8s`. |

## Positive Evidence

- The Android Gradle wrapper now evaluates the project successfully with Android Studio JBR 17.
- Source-level Android security audit passes.
- Source-level Android performance report passes and records the profile limits:
  - Watch Compact: `262144` bytes
  - Legacy Efficient: `1048576` bytes
  - Modern Standard: `5242880` bytes
  - Large Screen: `5242880` bytes
- Rich fixture render audit passes for headings, paragraphs, inline styles, lists, tables, code,
  Mermaid/math source-card fallback, images, safe media placeholders, footnotes, details/summary,
  generic HTML fallback, multilingual wrapping fixtures, and escaped markers.
- Renderer asset gates pass for the current native-fallback implementation and fail closed for
  future WebView or vendored JS/CSS/font renderer additions unless local packaging, manifest hashes,
  and request-blocking coverage are present.

## Blockers Preserved

- `./gradlew lint`, `./gradlew build`, `./gradlew :core:testDebugUnitTest`,
  `./gradlew :feature:reader:testDebugUnitTest`, `./gradlew :app:assembleDebug`, and
  `./gradlew :app:connectedDebugAndroidTest` should remain open because Maven Central returned HTTP
  403 for required uncached artifacts during `:core:compileDebugKotlin`.
- Connected Android validation remains open because the build cannot produce/install test artifacts,
  and `adb devices` shows no attached device or emulator.
- Android API 27 validation remains open because no local API 27 system image is installed.
- Android low-memory/small-screen and modern-device validation remain open until suitable
  emulator/device targets are available and compile-backed build gates pass.

## Supervisor Checklist Recommendation

The supervising session can use this Android-local report as evidence for:

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
- L12: Capture Android performance report.
- L12: Capture Android security audit report.
- L12: Capture rich fixture render report.
- L13: Record validation reports under `android/docs/reports/`.

Keep the Android wrapper-backed compile, lint, build, assemble, connected test, API 27,
low-memory/small-screen, and modern-device gates open until Maven artifact access and device targets
are available.
