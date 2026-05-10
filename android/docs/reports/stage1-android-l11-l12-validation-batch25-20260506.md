# Stage 1 Android L11/L12 Validation Batch 25 - 2026-05-06

## Scope

This bounded Android live-lane batch advanced the earliest still-open Android-owned
validation cluster from the 2026-05-05 todo snapshot without touching `ios/**`,
shared `Docs/**`, or `.cron/**`.

The batch focused on:

- L11 conditional renderer asset/WebView gates.
- L12 Android Gradle validation supported by the local environment.
- L12 Android source-level performance, security, and rich fixture report capture.
- L13 Android-local validation evidence under `android/docs/reports/`.

No Android source implementation files were changed in this batch. The only
repository change is this Android-local validation report.

## Environment

- Working directory: `/Users/wangweiyang/GitHub/fastmd/android`
- Report timestamp: `2026-05-06 05:32:51 CST`
- Shell default Java: blocked. `java -version` reports `Unable to locate a Java Runtime.`
- Validation JDK used: `/Applications/Android Studio.app/Contents/jbr/Contents/Home`
- Android SDK location: `local.properties` contains `sdk.dir=/Users/wangweiyang/Library/Android/sdk`
- Android platforms installed: API 31, 32, 33, 34, 35, and 36.
- Android API 27 platform/system image: not present in the local SDK scan.
- Gradle entry point: checked-in wrapper `./gradlew`
- Gradle wrapper distribution: Gradle `9.3.0`
- Device availability: `adb devices -l` printed only `List of devices attached`; no emulator or physical Android device was attached.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED | The shell default Java runtime is not configured: `Unable to locate a Java Runtime.` |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew projects --no-daemon` | PASS | Wrapper evaluated root project `fastmd-android` and modules `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 3s`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :core:testDebugUnitTest :feature:reader:testDebugUnitTest --no-daemon` | BLOCKED | Gradle reached `:core:testDebugUnitTest`, then timed out fetching uncached Google Maven artifacts `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0`; `BUILD FAILED in 3m 7s`. The combined invocation stopped before `:feature:reader:testDebugUnitTest`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew stage1AndroidRendererAssetGates stage1AndroidPerformanceReport stage1AndroidSecurityAuditReport stage1AndroidRichFixtureRenderReport --no-daemon` | PASS | Ran `auditRendererAssets`, `testRendererAssetAudit`, `auditPerformanceReport`, `auditSecurityReport`, and `auditRichFixtureRenderReport`; `BUILD SUCCESSFUL in 10s`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew lint --no-daemon` | BLOCKED | Gradle reached `:core:extractDebugAnnotations`, then timed out fetching `com.android.tools.lint:lint-gradle:31.13.2` from `https://dl.google.com/dl/android/maven2/...`; `BUILD FAILED in 3m 7s`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :feature:reader:testDebugUnitTest --no-daemon` | BLOCKED | Gradle reached `:feature:reader:compileDebugKotlin`, then timed out fetching `androidx.compose.compiler:compiler:1.5.14` from `https://dl.google.com/dl/android/maven2/...`; `BUILD FAILED in 3m 7s`. |
| `adb devices -l` | BLOCKED | `adb` is installed through the configured Android SDK, but no device or emulator is attached. |

## Source-Level Report Capture

The Gradle-backed Android source-level report bundle passed with the Android
Studio JBR:

- Renderer asset gates: no Android `WebView`, `android.webkit`, React Native,
  Flutter, Cordova, equivalent web runtime, or vendored JS/CSS/font renderer asset
  tree is present. The regression audit passed native fallback coverage and
  negative cases for missing renderer hash manifests, misplaced assets, remote or
  dangerous subresource references, stale hashes, unlisted assets, manifest path
  escaping, WebView marker usage without request-blocking evidence, and React
  Native dependency usage.
- Performance report: Watch Compact, Legacy Efficient, Modern Standard, and Large
  Screen profile limits are present; the Android fixture size matrix was captured.
- Security audit: no Android `uses-permission` declarations, broad storage/media,
  notification, default `INTERNET`, backup-enabled posture, unexpected exported
  component, WebView implementation, web runtime dependency, or missing release
  hardening posture was found.
- Rich fixture render audit: native Kotlin/Compose parser and reader paths cover
  Stage 1 rich Markdown categories including headings, inline styles, links,
  blockquotes, lists, task lists, tables, code fences, Mermaid/math readable
  source cards, images, media placeholders, footnotes, details/summary, generic
  HTML fallback, mixed CJK/Japanese/Korean text, and escaped markers. The audit
  also confirms wide code/table/media containment and remote-image placeholder
  posture.

## Blockers Preserved

- `./gradlew lint` remains open until `com.android.tools.lint:lint-gradle:31.13.2`
  can be resolved from Google Maven.
- `./gradlew :core:testDebugUnitTest` remains open until
  `androidx.collection:collection-ktx:1.4.0` and
  `androidx.concurrent:concurrent-futures:1.1.0` can be resolved from Google Maven.
- `./gradlew :feature:reader:testDebugUnitTest` remains open until
  `androidx.compose.compiler:compiler:1.5.14` can be resolved from Google Maven.
- `./gradlew build` and `./gradlew :app:assembleDebug` were not rerun in this
  bounded batch because prior source-level validation already isolated the same
  Google Maven connectivity class, and this batch directly reproduced it on lint,
  core tests, and reader tests.
- `./gradlew :app:connectedDebugAndroidTest`, Android API 27 validation,
  low-memory/small-screen profile validation, and modern-device validation remain
  open because no emulator or physical Android device is attached.
- Android API 27 validation is additionally blocked by the missing API 27 platform
  or system image in the local SDK scan.

## Supervisor Checklist Recommendation

The supervising session can use this report as Android evidence for marking:

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
- L11: Add WebView request-blocking tests if local JS renderer surfaces are used.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
- L12: Capture Android performance report.
- L12: Capture Android security audit report.
- L12: Capture rich fixture render report, Android portion.
- L13: Record validation reports under `android/docs/reports/`.

Keep these Android L12 checklist items open from this batch:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.
