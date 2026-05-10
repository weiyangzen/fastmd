# Stage 1 Android L12 Validation Refresh Batch 23 - 2026-05-06

## Scope

This bounded Android live-lane batch refreshed Android-owned L12 validation evidence
without touching `ios/**`, shared `Docs/**`, or `.cron/**`.

The batch focused on the earliest still-open Android validation items that can be
advanced locally:

- Wrapper project graph validation.
- Android source-level performance report capture.
- Android source-level security audit report capture.
- Android rich fixture render report capture.
- Conditional renderer asset gate capture.
- Compile-backed unit/lint/assemble gate attempts with exact blockers.
- Device availability check for connected/API 27/low-memory/modern validation.

No Android app/source implementation files were changed in this batch. The only
repository change is this platform-local validation report.

## Environment

- Working directory: `/Users/wangweiyang/GitHub/fastmd/android`
- Preferred Stage 1 JDK used for final wrapper checks:
  `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`
- JDK version: OpenJDK `17.0.17`
- Gradle wrapper: `./gradlew`, Gradle `9.3.0`

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME="/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home" ./gradlew projects --no-daemon` | PASS | Wrapper resolved root project `fastmd-android` and modules `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 12s`. |
| `JAVA_HOME="/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home" ./gradlew stage1AndroidPerformanceReport stage1AndroidSecurityAuditReport stage1AndroidRichFixtureRenderReport stage1AndroidRendererAssetGates --no-daemon` | PASS | Ran `auditPerformanceReport`, `auditSecurityReport`, `auditRichFixtureRenderReport`, `auditRendererAssets`, and `testRendererAssetAudit`; `BUILD SUCCESSFUL in 19s`. |
| `bash tools/audit_stage1_manifest.sh && bash tools/audit_renderer_assets.sh && bash tools/audit_rich_fixture_render.sh` | PASS | Confirmed manifest permission/security posture, no WebView/web-runtime/vendored renderer asset tree, and native rich fixture coverage for the required rich Markdown categories. |
| `bash tools/audit_performance_report.sh` | PASS | Captured Android runtime profile limits and fixture size matrix; reported `PASS: Android performance report audit completed.` |
| `JAVA_HOME="/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home" ./gradlew :core:testDebugUnitTest --no-daemon` | BLOCKED | Gradle reached `:core:testDebugUnitTest`, then timed out fetching `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0` from `https://dl.google.com/dl/android/maven2/...`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :feature:reader:testDebugUnitTest --no-daemon` | BLOCKED | Gradle reached `:feature:reader:compileDebugKotlin`, then timed out fetching `androidx.compose.compiler:compiler:1.5.14` from `https://dl.google.com/dl/android/maven2/...`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew lint --no-daemon` | BLOCKED | Gradle reached `:core:extractDebugAnnotations`, then timed out fetching `com.android.tools.lint:lint-gradle:31.13.2` from `https://dl.google.com/dl/android/maven2/...`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :app:assembleDebug --no-daemon` | BLOCKED | Gradle reached `:feature:library:compileDebugKotlin`, then timed out fetching `androidx.compose.compiler:compiler:1.5.14` from `https://dl.google.com/dl/android/maven2/...`. |
| `adb devices` | BLOCKED | `adb` is available, but the device list is empty. No attached device or running emulator was available for `:app:connectedDebugAndroidTest`, API 27, low-memory/small-screen, or modern-device validation. |

## Source-Level Capture Details

The Gradle-backed report capture task confirmed:

- Performance report: Watch Compact, Legacy Efficient, Modern Standard, and Large
  Screen profile limits are available, and the Android fixture size matrix can be
  captured locally.
- Security audit: no `uses-permission` declarations, no broad storage/media,
  notification, default `INTERNET`, backup-enabled posture, unexpected exported
  component, WebView implementation, or missing release hardening posture were
  found.
- Rich fixture render report: the Android native parser/render model covers the
  Stage 1 rich fixture categories, including headings, inline styles, links,
  blockquotes, lists, tables, code fences, Mermaid/math readable source cards,
  images, media placeholders, footnotes, details/summary, generic HTML fallback,
  CJK/Japanese/Korean mixed text, and escaped markers.
- Renderer asset gates: the current Android implementation has no WebView,
  `android.webkit`, React Native, Flutter, Cordova, equivalent web runtime, or
  vendored JS/CSS/font renderer asset tree. The regression audit also verifies
  future renderer assets must be app-local, hash-manifested, offline, and free of
  dangerous remote/navigation references.

## Blockers Preserved

- Android wrapper distribution is now available locally for `./gradlew projects`
  and source-level report tasks.
- Compile-backed Gradle gates remain blocked by `dl.google.com` connection
  timeouts for AndroidX/Compose/lint artifacts.
- `./gradlew lint`, `./gradlew build`, `./gradlew :core:testDebugUnitTest`,
  `./gradlew :feature:reader:testDebugUnitTest`, and
  `./gradlew :app:assembleDebug` must remain open until Google Maven dependency
  resolution succeeds.
- `./gradlew :app:connectedDebugAndroidTest`, Android API 27 validation,
  low-memory/small-screen validation, and modern-device validation must remain
  open until an emulator or physical Android device is attached.

## Supervisor Checklist Recommendation

The supervising session can use this Android-local evidence for:

- L11: Add local renderer packaging/offline tests if JS renderer assets are used,
  Android conditional path.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces
  are used, Android conditional path.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets
  are vendored, Android conditional path.
- L12: Capture Android performance report.
- L12: Capture Android security audit report.
- L12: Capture rich fixture render report, Android portion.
- L13: Record validation reports under `android/docs/reports/`.

Do not mark the compile-backed or device-backed Android L12 gates complete from
this batch:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.
