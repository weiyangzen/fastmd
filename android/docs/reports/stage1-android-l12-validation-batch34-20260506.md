# Stage 1 Android L12 Validation Batch 34 - 2026-05-06

Worker: FastMD Stage 1 Mobile Android live lane

Scope:

- Android-owned L12 validation evidence only.
- No implementation files outside `android/**` were modified.
- No `ios/**`, `Docs/Stage1_Mobile_Blueprint.md`, or `Docs/todos_20260505.md` edits.

## Environment

- Repository: `/Users/wangweiyang/GitHub/fastmd`
- Android project: `/Users/wangweiyang/GitHub/fastmd/android`
- Timestamp: `2026-05-06 07:24:06 CST`
- Default `java -version`: blocked with `Unable to locate a Java Runtime`
- Validation JDK used: `/Applications/Android Studio.app/Contents/jbr/Contents/Home`
- Android SDK from `local.properties`: `/Users/wangweiyang/Library/Android/sdk`
- Installed Android platforms observed: `android-31`, `android-32`, `android-33`, `android-34`, `android-35`, `android-36`

## Commands And Results

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew projects --no-daemon` | PASS | Gradle wrapper resolved the project graph: root `fastmd-android` with `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew lint :core:testDebugUnitTest :feature:reader:testDebugUnitTest :app:assembleDebug build --continue --no-daemon` | BLOCKED | Gradle entered module compile/lint/test/assemble work and ran `stage1AndroidRendererAssetGates`, but the broader task graph failed because Google Maven downloads timed out. Representative blocker: `Could not resolve com.android.tools.lint:lint-gradle:31.13.2` from `https://dl.google.com/dl/android/maven2/...`; later tasks also failed to download `androidx.collection:collection-ktx:1.4.0`, `androidx.concurrent:concurrent-futures:1.1.0`, `androidx.lifecycle:lifecycle-common-java8:2.8.4`, and `androidx.compose.compiler:compiler:1.5.14` after Google repository resolution was disabled by the earlier timeout. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :core:testDebugUnitTest --no-daemon` | BLOCKED | Isolated core test command reached `:core:testDebugUnitTest` but failed resolving `:core:debugUnitTestRuntimeClasspath` because `collection-ktx-1.4.0.jar` and `concurrent-futures-1.1.0.jar` could not be downloaded from `dl.google.com` due connection timeout. |
| `bash tools/audit_performance_report.sh` | PASS | Printed Android performance profile size limits for `WatchCompact`, `LegacyEfficient`, `ModernStandard`, and `LargeScreen`; printed fixture size matrix; completed with `PASS: Android performance report audit completed.` |
| `bash tools/audit_stage1_manifest.sh && bash tools/audit_renderer_assets.sh` | PASS | Confirmed no permission declarations, no broad storage/media/notification/default `INTERNET`, `allowBackup=false`, cleartext disabled, only document-entry `MainActivity` exported, no Android `WebView`/`android.webkit`, no React Native/Flutter/Cordova/equivalent runtime, release hardening enabled, and no vendored JS/CSS/font renderer asset tree. |
| `bash tools/audit_rich_fixture_render.sh` | PASS | Confirmed rich fixture coverage for headings, paragraphs, inline styles, links/autolinks, blockquotes, lists, task lists, tables, code fences, Mermaid fallback, math fallback, images, video HTML placeholder, footnotes, details/summary, generic HTML fallback, CJK/English/Japanese/Korean text, escaped markers, native parser/render model coverage, Compose renderer paths, local horizontal scroll for wide surfaces, remote image placeholders, and no web app runtime. |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Confirmed native fallback without vendored renderer assets; valid app-local JS/CSS/font assets with SHA-256 manifest pass; missing/misplaced/non-main/stale/unlisted/malformed assets fail; escaping/dot/percent/whitespace paths fail; remote/content/protocol-relative/encoded/double-encoded/uppercase dangerous references fail; external navigation, meta refresh, forms, network-capable browser APIs, WebView markers, and React Native runtime markers fail. |

## L12 Status From This Batch

- Android `./gradlew lint`: still open. Blocked by `dl.google.com` timeout resolving `com.android.tools.lint:lint-gradle:31.13.2`.
- Android `./gradlew build`: still open. Blocked by the same Google Maven dependency resolution timeout and downstream missing AndroidX/Compose artifacts.
- Android `./gradlew :core:testDebugUnitTest`: still open. Blocked by `dl.google.com` timeout resolving AndroidX runtime artifacts.
- Android `./gradlew :feature:reader:testDebugUnitTest`: still open. Included in the broader Gradle invocation, but the task graph was blocked before a clean result by Google Maven dependency resolution timeout.
- Android `./gradlew :app:assembleDebug`: still open. Included in the broader Gradle invocation, but the task graph was blocked before a clean result by Google Maven dependency resolution timeout.
- Android `./gradlew :app:connectedDebugAndroidTest`: still open. Not run in this batch because local dependency resolution is blocked and no attached/emulated device validation was established.
- Android API 27 validation: still open. No API 27 platform image/device validation was run in this batch.
- Android low-memory/small-screen profile validation: still open for device/emulator runtime validation. Source-level performance profile audit passed.
- Android modern device validation: still open. No device/emulator runtime validation was run in this batch.
- Capture Android performance report: supervisor can mark complete for source-level report evidence from `bash tools/audit_performance_report.sh`, with this report as evidence.
- Capture Android security audit report: supervisor can mark complete for source-level report evidence from `bash tools/audit_stage1_manifest.sh && bash tools/audit_renderer_assets.sh`, with this report as evidence.
- Capture rich fixture render report: supervisor can mark complete for source-level report evidence from `bash tools/audit_rich_fixture_render.sh`, with this report as evidence.

## L11 Conditional Renderer Gate Evidence

The Android implementation still uses native Kotlin/Compose fallback for Mermaid/math and has no Android `WebView`, `android.webkit`, or vendored JS/CSS/font renderer asset tree.

The renderer audit and regression harness passed again in this batch. This supports the Android side of the conditional L11 renderer items:

- Local renderer packaging/offline tests if JS renderer assets are used.
- WebView request-blocking tests if local JS renderer surfaces are used.
- Renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.

Because no such Android renderer assets or WebView surface are currently used, the applicable Android evidence is the fail-closed audit coverage in `tools/audit_renderer_assets.sh`, `tools/test_renderer_asset_audit.sh`, and `core/src/test/java/com/fastmd/mobile/core/render/RichRendererAssetPolicyTest.kt`.

## Supervisor Checklist Recommendations

The supervising Docs reconciliation can mark these Android-owned items complete, using this report as evidence:

- L12: Capture Android performance report.
- L12: Capture Android security audit report.
- L12: Capture rich fixture render report.

The supervising Docs reconciliation should keep these Android-owned items open:

- L12: Run Android `./gradlew lint`.
- L12: Run Android `./gradlew build`.
- L12: Run Android `./gradlew :core:testDebugUnitTest`.
- L12: Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- L12: Run Android `./gradlew :app:assembleDebug`.
- L12: Run Android `./gradlew :app:connectedDebugAndroidTest`.
- L12: Run Android API 27 validation.
- L12: Run Android low-memory/small-screen profile validation.
- L12: Run Android modern device validation.

