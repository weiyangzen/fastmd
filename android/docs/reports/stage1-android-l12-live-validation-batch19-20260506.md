# Stage 1 Android L12 Live Validation Batch 19 - 2026-05-06

## Scope

This bounded Android live-lane batch advanced the earliest open Android-owned validation cluster that the local environment could execute without touching `ios/**`, shared `Docs/**`, or `.cron/**`.

No production source files were changed in this batch. The Android implementation and gate scripts were already present; this batch produced fresh validation evidence and preserved exact blockers for gates that still cannot be completed locally.

## Environment

| Check | Result |
| --- | --- |
| Working directory | `/Users/wangweiyang/GitHub/fastmd/android` |
| Plain `java -version` | BLOCKED: macOS Java shim reported `Unable to locate a Java Runtime.` |
| Wrapper JDK used | `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home` |
| Gradle wrapper | `./gradlew`, Gradle `9.3.0` |
| System Gradle fallback | Available, Gradle `9.3.0`, but launches with Homebrew JDK `25.0.1`; not used for Android gates because Stage 1 expects JDK 17 |
| Android SDK | `local.properties` contains `sdk.dir=/Users/wangweiyang/Library/Android/sdk` |
| Installed SDK platforms observed | API 31, 32, 33, 34, 35, 36 |
| API 27 system image | Not found under `$HOME/Library/Android/sdk/system-images/android-27` |
| Attached devices | `adb devices` returned no attached device or emulator |

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew projects --no-daemon` | PASS | Wrapper resolved and printed root project `fastmd-android` with modules `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. Build completed successfully in 13s. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew lint --no-daemon` | BLOCKED | Reached `:core:extractDebugAnnotations`, then failed resolving `com.android.tools.lint:lint-gradle:31.13.2` from `https://dl.google.com/...` due `Connect timed out`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew :core:testDebugUnitTest --no-daemon` | BLOCKED | Reached `:core:testDebugUnitTest`, then failed resolving runtime JARs from `dl.google.com`: `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0`, both with `Connect timed out`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew stage1AndroidRendererAssetGates stage1AndroidPerformanceReport stage1AndroidSecurityAuditReport stage1AndroidRichFixtureRenderReport --no-daemon` | PASS | Build successful in 22s; 5 actionable tasks executed. Renderer asset gates, performance report, security audit report, and rich fixture render report all passed. |

## Passed Report Gate Detail

`stage1AndroidRendererAssetGates` passed with:

- No Android `WebView` or `android.webkit` implementation present.
- No React Native, Flutter, Cordova, or equivalent web runtime dependency present.
- No vendored JS/CSS/font renderer asset tree present; Android rich blocks use native fallback paths.
- Regression coverage passed for native fallback, app-local SHA-256 manifest success, missing manifest failure, misplaced asset failure, remote subresource failure, `content://` reference failure, protocol-relative remote URL failure, uppercase dangerous URL failure, external navigation API failure, stale hash failure, unlisted asset failure, manifest path escape failure, WebView marker failure, and React Native runtime marker failure.

`stage1AndroidPerformanceReport` passed with:

- Performance profiles reported for `WatchCompact`, `LegacyEfficient`, `ModernStandard`, and `LargeScreen`.
- Fixture size matrix reported for `basic.md`, `rich-preview.md`, `long-1mb.md`, `large-5mb.md`, `huge-table.md`, `huge-code-block.md`, `remote-image.md`, and `local-image.md`.
- Audit completed with `PASS: Android performance report audit completed.`

`stage1AndroidSecurityAuditReport` passed with:

- No `uses-permission` declarations.
- No broad storage, notification, or default `INTERNET` permission.
- `allowBackup=false` documented and enforced.
- Cleartext network traffic disabled.
- Only document-entry `MainActivity` exported.
- No Android WebView implementation in Stage 1 main code.
- Release build has R8 minify, resource shrinking, non-debuggable output, and app ProGuard rules.
- Renderer asset audit also passed as part of the security report.

`stage1AndroidRichFixtureRenderReport` passed with:

- Rich fixture coverage for headings, paragraphs, emphasis, strikethrough, inline code, mark/highlight, subscript, superscript, links, autolinks, email autolinks, blockquotes, unordered lists, ordered lists, task lists, tables, fenced code, Mermaid fallback, inline math, block math, images, safe video HTML, footnotes, details/summary, generic HTML fallback, CJK/English/Japanese/Korean text, and escaped markers.
- Parser/render model coverage for rich block kinds including heading, paragraph, blockquote, unordered list, ordered list, task list, table, code fence, Mermaid, math block, image, video HTML, horizontal rule, footnote, details, and HTML fallback.
- Compose reader native renderer paths verified, including wide-surface local horizontal scroll, remote image privacy placeholder, Mermaid native source card, and block math native source card.
- Audit confirmed Android rich rendering remains native Kotlin/Compose without a web app runtime.

## Checklist Evidence For Supervisor

The supervisor can use this report as Android-local evidence for completing these checklist items if not already reconciled:

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
- L11: Add WebView request-blocking tests if local JS renderer surfaces are used.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
- L12: Capture Android performance report.
- L12: Capture Android security audit report.
- L12: Capture rich fixture render report.
- L13: Record validation reports under `android/docs/reports/`.

Keep these checklist items open from this batch:

- L12: Run Android `./gradlew lint`.
  - Blocker: Google Maven timeout resolving `com.android.tools.lint:lint-gradle:31.13.2`.
- L12: Run Android `./gradlew build`.
  - Not attempted after `lint` and `:core:testDebugUnitTest` exposed dependency-resolution timeouts.
- L12: Run Android `./gradlew :core:testDebugUnitTest`.
  - Blocker: Google Maven timeout resolving AndroidX runtime JARs.
- L12: Run Android `./gradlew :feature:reader:testDebugUnitTest`.
  - Not attempted after core unit test runtime dependency resolution failed.
- L12: Run Android `./gradlew :app:assembleDebug`.
  - Not attempted after compile/test dependency resolution failed.
- L12: Run Android `./gradlew :app:connectedDebugAndroidTest`.
  - Blockers: no attached device/emulator, and Gradle dependency resolution is not yet reliable.
- L12: Run Android API 27 validation.
  - Blockers: no API 27 system image found and no attached API 27 device/emulator.
- L12: Run Android low-memory/small-screen profile validation.
  - Blocker: no attached device/emulator.
- L12: Run Android modern device validation.
  - Blocker: no attached device/emulator.
