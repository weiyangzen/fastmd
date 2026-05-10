# Stage 1 Android L12 Validation Refresh Batch 24 - 2026-05-06

## Scope

This bounded Android live-lane batch advanced the earliest still-open Android-owned
L12 validation items that can be exercised from the local environment:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Refresh Gradle-backed Android source-level performance, security, rich fixture,
  and renderer asset reports.
- Preserve device validation blockers for connected/API 27/low-memory/modern gates.

No Android source implementation files were changed in this batch. The only
repository change is this platform-local validation report.

## Environment

- Working directory: `/Users/wangweiyang/GitHub/fastmd/android`
- Report timestamp: `2026-05-06 05:11:34 CST`
- Default shell Java: blocked, `java -version` reports `Unable to locate a Java Runtime.`
- Validation JDK used: `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`
- Android SDK location: `local.properties` contains `sdk.dir=/Users/wangweiyang/Library/Android/sdk`
- Gradle entry point: `./gradlew`
- Gradle wrapper version observed through successful project graph run: Gradle `9.3.0`
- `adb`: `/usr/local/bin/adb`

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED | Shell default Java is not configured: `Unable to locate a Java Runtime.` |
| `adb devices` | BLOCKED | `adb` is installed, but the device list is empty. No attached device or running emulator is available. |
| `JAVA_HOME="/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home" ./gradlew projects --no-daemon` | PASS | Wrapper resolved root project `fastmd-android` and modules `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 13s`. |
| `JAVA_HOME="/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home" ./gradlew lint --no-daemon` | BLOCKED | Gradle reached `:core:extractDebugAnnotations`, then timed out fetching `com.android.tools.lint:lint-gradle:31.13.2` from `https://dl.google.com/dl/android/maven2/...`; `BUILD FAILED in 3m 19s`. |
| `JAVA_HOME="/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home" ./gradlew :core:testDebugUnitTest --no-daemon` | BLOCKED | Gradle reached `:core:testDebugUnitTest`, then timed out fetching `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0` from Google Maven; `BUILD FAILED in 3m 18s`. |
| `JAVA_HOME="/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home" ./gradlew stage1AndroidPerformanceReport stage1AndroidSecurityAuditReport stage1AndroidRichFixtureRenderReport stage1AndroidRendererAssetGates --no-daemon` | PASS | Ran `auditPerformanceReport`, `auditSecurityReport`, `auditRichFixtureRenderReport`, `auditRendererAssets`, and `testRendererAssetAudit`; `BUILD SUCCESSFUL in 21s`. |
| `JAVA_HOME="/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home" ./gradlew :app:assembleDebug --no-daemon` | BLOCKED | Gradle reached `:feature:library:compileDebugKotlin`, then timed out fetching `androidx.compose.compiler:compiler:1.5.14` from Google Maven; `BUILD FAILED in 3m 20s`. |
| `JAVA_HOME="/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home" ./gradlew :feature:reader:testDebugUnitTest --no-daemon` | BLOCKED | Gradle reached `:feature:reader:compileDebugKotlin`, then timed out fetching `androidx.compose.compiler:compiler:1.5.14` from Google Maven; `BUILD FAILED in 3m 19s`. |
| `JAVA_HOME="/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home" ./gradlew build --no-daemon` | BLOCKED | Gradle reached `:feature:library:compileDebugKotlin`, then timed out fetching `androidx.compose.compiler:compiler:1.5.14` from Google Maven; `BUILD FAILED in 3m 21s`. |

## Source-Level Report Capture

The Gradle-backed Android report capture passed and produced the following
current evidence:

- Performance report: Watch Compact, Legacy Efficient, Modern Standard, and Large
  Screen profile limits are present; Android fixture size matrix is captured.
- Security audit: no Android `uses-permission` declarations, broad storage/media,
  notification, default `INTERNET`, backup-enabled posture, unexpected exported
  component, WebView implementation, or missing release hardening posture were
  found.
- Rich fixture render audit: native Kotlin/Compose parser and reader paths cover
  the required Stage 1 rich Markdown categories, including headings, inline styles,
  links, blockquotes, lists, task lists, tables, code fences, Mermaid/math readable
  source cards, images, media placeholders, footnotes, details/summary, generic
  HTML fallback, CJK/Japanese/Korean mixed text, and escaped markers.
- Renderer asset gates: no WebView, `android.webkit`, React Native, Flutter,
  Cordova, equivalent web runtime, or vendored JS/CSS/font renderer asset tree is
  present. The regression audit verifies that future renderer assets must be
  app-local, hash-manifested, offline, and free of dangerous remote/navigation
  references.

## Blockers Preserved

- Compile-backed Android L12 gates remain blocked by Google Maven connectivity
  timeouts to `dl.google.com`.
- `./gradlew lint` remains open until `com.android.tools.lint:lint-gradle:31.13.2`
  can be resolved.
- `./gradlew build`, `./gradlew :feature:reader:testDebugUnitTest`, and
  `./gradlew :app:assembleDebug` remain open until
  `androidx.compose.compiler:compiler:1.5.14` can be resolved.
- `./gradlew :core:testDebugUnitTest` remains open until
  `androidx.collection:collection-ktx:1.4.0` and
  `androidx.concurrent:concurrent-futures:1.1.0` can be resolved.
- `./gradlew :app:connectedDebugAndroidTest`, Android API 27 validation,
  low-memory/small-screen validation, and modern-device validation remain open
  until an emulator or physical Android device is attached.

## Supervisor Checklist Recommendation

The supervising session can use this Android-local evidence for:

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
