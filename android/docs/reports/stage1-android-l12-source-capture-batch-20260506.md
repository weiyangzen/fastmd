# Stage 1 Android L12 Source Capture Batch - 2026-05-06

## Scope

Android live-lane bounded validation batch for the earliest still-open Android-owned
L12 platform validation items that can be advanced without touching iOS or shared Docs.

This batch did not change Android app implementation code. It verified that the checked-in
Gradle wrapper can evaluate the Android project with an explicit JDK 17 path, captured the
Android source-level performance/security/rich-render reports through Gradle, and preserved
the exact blockers for compile-backed and device-backed gates.

## Environment

- Working directory: `/Users/wangweiyang/GitHub/fastmd/android`
- Timestamp: `2026-05-06 01:17:18 CST`
- Wrapper: `./gradlew`, Gradle distribution `9.3.0`
- Explicit JDK for wrapper commands: `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`
- Shell default `java -version`: blocked, macOS reported `Unable to locate a Java Runtime.`
- Android SDK: `local.properties` contains `sdk.dir=/Users/wangweiyang/Library/Android/sdk`
- Installed Android platforms observed: API 31, 32, 33, 34, 35, 36
- Installed build tools observed: 34.0.0, 35.0.0, 36.0.0, 36.1.0-rc1
- API 27 system image observed: none under `$HOME/Library/Android/sdk/system-images/android-27`
- `adb devices`: no attached devices or running emulators

## Validation Results

| Command | Result | Notes |
| --- | --- | --- |
| `java -version` | BLOCKED | Default Java shim is not configured: `Unable to locate a Java Runtime.` |
| `gradle --version` | PASS | System Gradle `9.3.0` is installed and runs on Homebrew JDK 25. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew projects --no-daemon` | PASS | Wrapper evaluated root project `fastmd-android` and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew :core:testDebugUnitTest --no-daemon` | BLOCKED | Reached `:core:compileDebugKotlin`, then dependency resolution timed out fetching `androidx.compose.compiler:compiler:1.5.14` from Google Maven at `https://dl.google.com/dl/android/maven2/.../compiler-1.5.14.pom`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew :feature:reader:testDebugUnitTest --no-daemon` | BLOCKED | Same blocker as core tests: `:core:compileDebugKotlin` could not resolve `androidx.compose.compiler:compiler:1.5.14` because the Google Maven request timed out. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew :app:assembleDebug --no-daemon` | BLOCKED | Same blocker as core tests: app assemble reached `:core:compileDebugKotlin` and timed out resolving `androidx.compose.compiler:compiler:1.5.14` from Google Maven. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew stage1AndroidPerformanceReport stage1AndroidSecurityAuditReport stage1AndroidRichFixtureRenderReport --no-daemon` | PASS | Gradle executed all three Android-local source-level capture gates successfully. |
| `adb devices` | BLOCKED | `adb` is installed, but no devices or running emulators were listed. Device-backed validation remains open. |

## Captured L12 Report Evidence

The combined Gradle report command passed these Android-owned capture gates:

- `stage1AndroidPerformanceReport`
  - Emitted the runtime profile limits for Watch Compact, Legacy Efficient, Modern Standard, and Large Screen.
  - Emitted the Android fixture size matrix.
  - Completed with `PASS: Android performance report audit completed.`
- `stage1AndroidSecurityAuditReport`
  - Confirmed no `uses-permission` declarations, no broad storage/media/notification/default `INTERNET` permission, `allowBackup=false`, cleartext disabled, only `MainActivity` exported, no Android WebView implementation, release minify/resource shrinking/non-debuggable posture, no React Native/Flutter/Cordova runtime, and no vendored JS/CSS/font renderer asset tree.
- `stage1AndroidRichFixtureRenderReport`
  - Confirmed rich fixture coverage for headings, inline styles, links/autolinks/email, blockquote, lists, task lists, tables, fenced code, Mermaid/math fallback, images/media placeholders, footnotes, details/summary, safe HTML fallback, CJK/mixed-language content, escaped markers, parser/render model block kinds, safe inline HTML mappings, Compose reader render paths, wide-surface containment, remote-image privacy placeholder, and no web app runtime.

## Remaining Blockers

- Compile-backed Gradle gates remain open until Google Maven dependency resolution succeeds for
  `androidx.compose.compiler:compiler:1.5.14`.
- `./gradlew lint` and `./gradlew build` were not rerun in this bounded batch after three compile-backed
  gates reproduced the same `:core:compileDebugKotlin` dependency-resolution blocker.
- `:app:connectedDebugAndroidTest`, API 27 validation, low-memory/small-screen validation, and modern-device
  validation remain open because `adb devices` lists no target.
- Android API 27 validation also remains open because no API 27 system image was observed locally.

## Supervisor Checklist Candidates

The supervising session can use this report as Android-lane evidence for the following L12 checklist items:

- Capture Android performance report.
- Capture Android security audit report.
- Capture rich fixture render report.

Keep the compile-backed and device-backed Android L12 gates open:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.
