# Stage 1 Android L12 Validation Capture Batch 10 - 2026-05-06

## Scope

Android live lane bounded L12 validation batch. This batch re-checked the current
Android Gradle/JDK/SDK environment, attempted the earliest compile-backed Gradle
validation gates, and captured the Android source-level performance, security, and
rich fixture reports through Gradle.

No iOS files or shared `Docs/` checklist files were edited.

## Environment

- Working directory: `/Users/wangweiyang/GitHub/fastmd/android`
- JDK used for Gradle: `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17`
- Default shell `java`: blocked, reports `Unable to locate a Java Runtime`
- Android SDK from `local.properties`: `/Users/wangweiyang/Library/Android/sdk`
- Installed Android platforms include API 31, 32, 33, 34, 35, and 36
- Installed Android system images: API 36 only
- `adb devices`: no attached device or running emulator

## Validation Results

| Command | Result | Notes |
| --- | --- | --- |
| `java -version` | BLOCKED | Default shell Java runtime is not configured: `Unable to locate a Java Runtime`. |
| `./gradlew --version --no-daemon` | BLOCKED without explicit JDK | Wrapper cannot run from the default shell Java environment. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17 PATH=/usr/local/Cellar/openjdk@17/17.0.17/bin:$PATH ./gradlew projects --no-daemon` | PASS | Wrapper evaluated root project `fastmd-android` and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17 PATH=/usr/local/Cellar/openjdk@17/17.0.17/bin:$PATH ./gradlew lint --no-daemon` | BLOCKED | Reached `:core:compileDebugKotlin`, then failed resolving `androidx.compose.compiler:compiler:1.5.14` from Google Maven. One run reported a TLS handshake termination from `dl.google.com`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17 PATH=/usr/local/Cellar/openjdk@17/17.0.17/bin:$PATH ./gradlew build --no-daemon` | BLOCKED | Reached `:core:compileDebugKotlin`, then failed resolving `androidx.compose.compiler:compiler:1.5.14`; the final blocker was `dl.google.com: nodename nor servname provided, or not known`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17 PATH=/usr/local/Cellar/openjdk@17/17.0.17/bin:$PATH ./gradlew :core:testDebugUnitTest --no-daemon` | BLOCKED | Reached `:core:compileDebugKotlin`, then failed resolving `androidx.compose.compiler:compiler:1.5.14`; the final blocker was a connection timeout to `dl.google.com:443`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17 PATH=/usr/local/Cellar/openjdk@17/17.0.17/bin:$PATH ./gradlew stage1AndroidPerformanceReport stage1AndroidSecurityAuditReport stage1AndroidRichFixtureRenderReport --no-daemon` | PASS | Source-level Android performance, security, and rich fixture render capture tasks all executed successfully. |
| `ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk /Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices` | BLOCKED for device validation | `adb` ran, but no devices or emulators were attached. |

## Capture Evidence

The Gradle capture command completed these Android source-level report gates:

- `stage1AndroidPerformanceReport`
  - Printed performance profile limits for `WatchCompact`, `LegacyEfficient`, `ModernStandard`, and `LargeScreen`.
  - Printed the local Markdown fixture size matrix.
  - Ended with `PASS: Android performance report audit completed.`
- `stage1AndroidSecurityAuditReport`
  - Confirmed no `uses-permission` declarations, no broad storage/media/notification/default `INTERNET` permission, `allowBackup=false`, cleartext disabled, only `MainActivity` exported, no WebView implementation, release hardening enabled, no React Native/Flutter/Cordova runtime, and no vendored JS/CSS/font renderer asset tree.
- `stage1AndroidRichFixtureRenderReport`
  - Confirmed native coverage for rich fixture categories including headings, paragraphs/inline styles, links, lists, task lists, tables, code, Mermaid/math fallback cards, images, safe HTML/media fallbacks, footnotes, details, CJK/mixed text, escaped markers, wide-surface containment, remote image privacy placeholders, and no web app runtime.

## Supervisor Checklist Recommendation

The supervisor can consider these Android-owned L12 checklist items complete with
this report as evidence:

- Capture Android performance report.
- Capture Android security audit report.
- Capture rich fixture render report.

Keep these Android-owned L12 checklist items open:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

The compile-backed Gradle gates are blocked by current access to Google Maven for
`androidx.compose.compiler:compiler:1.5.14`, not by missing JDK 17, missing wrapper,
missing `local.properties`, or missing Android API 35 SDK. Device validation remains
blocked because no device/emulator is attached, and API 27 validation remains blocked
because no API 27 system image is installed in the local Android SDK.
