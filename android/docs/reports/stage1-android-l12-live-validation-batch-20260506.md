# Stage 1 Android L12 Live Validation Batch - 2026-05-06

## Scope

This bounded Android-owned batch advanced the earliest still-open Android lane cluster in L12 Platform Validation. It did not edit `ios/**`, shared `Docs/**`, or `.cron/**`.

The batch used the local Android Studio JBR because the default shell still has no Java runtime on `PATH`.

```text
JAVA_HOME=/Applications/Android Studio.app/Contents/jbr/Contents/Home
JBR version=OpenJDK 21.0.6
System Gradle version=9.3.0
Android SDK path=/Users/wangweiyang/Library/Android/sdk
Installed platform includes android-35
```

## Validation Results

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android`.

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED | Default shell reports: `Unable to locate a Java Runtime.` |
| `'/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/java' -version` | PASS | Android Studio JBR is available: OpenJDK `21.0.6`. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew --version` | BLOCKED | Wrapper attempted `https://services.gradle.org/distributions/gradle-9.3.0-bin.zip` and failed with `java.net.UnknownHostException: services.gradle.org`. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew lint --no-daemon` | BLOCKED | Same wrapper distribution DNS blocker: `java.net.UnknownHostException: services.gradle.org`. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' gradle --version` | PASS | System Gradle `9.3.0` is installed and runs on the Android Studio JBR. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' gradle projects --no-daemon` | PASS | Resolved root project `fastmd-android` with modules `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 3s`. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' gradle :core:testDebugUnitTest --no-daemon` | BLOCKED | Gradle reached `:core:compileDebugKotlin`, then dependency resolution failed for `dl.google.com`, including `androidx.datastore:datastore-preferences:1.1.1` and `androidx.compose:compose-bom:2024.06.00`. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' gradle lint --no-daemon` | BLOCKED | Gradle reached `:core:checkDebugAarMetadata`, then dependency resolution failed for `dl.google.com`, including `androidx.datastore:datastore-preferences:1.1.1`, `org.jetbrains.kotlin:kotlin-stdlib:1.9.24`, and `androidx.compose:compose-bom:2024.06.00`. |
| `bash tools/audit_stage1_manifest.sh` | PASS | No permissions, no broad storage/notification/default `INTERNET`, `allowBackup=false`, cleartext disabled, only `MainActivity` exported, no WebView implementation, and release hardening posture verified. |
| `bash tools/audit_performance_report.sh` | PASS | Performance profiles and fixture size matrix printed; audit completed. |
| `bash tools/audit_rich_fixture_render.sh` | PASS | Rich fixture coverage, render model block/inline declarations, parser coverage, native Compose render paths, horizontal scroll constraints, remote image privacy placeholder, Mermaid/math fallback cards, and no web runtime verified. |
| `bash tools/audit_renderer_assets.sh` | PASS | No Android WebView/android.webkit implementation, no React Native/Flutter/Cordova runtime dependency, and no vendored JS/CSS/font renderer asset tree found. |

## Source Audit Summaries

### Android Security Audit

`bash tools/audit_stage1_manifest.sh` passed the Android security posture checks:

- No `uses-permission` declarations are present.
- No broad storage, notification, or default `INTERNET` permission is present.
- App manifest documents Stage 1 backup posture with `allowBackup=false`.
- Cleartext network traffic is disabled.
- Only the document-entry `MainActivity` is exported.
- No Android WebView implementation is present in Stage 1 main code.
- Release build type enables R8 minify, resource shrinking, non-debuggable output, and app ProGuard rules.

### Android Performance Report

`bash tools/audit_performance_report.sh` passed and printed the Android performance profile limits:

| Profile | Soft Limit |
| --- | ---: |
| `WatchCompact` | 262144 bytes |
| `LegacyEfficient` | 1048576 bytes |
| `ModernStandard` | 5242880 bytes |
| `LargeScreen` | 5242880 bytes |

The audit also confirmed the Android fixture size matrix was readable, including `rich-preview.md`.

### Rich Fixture Render Report

`bash tools/audit_rich_fixture_render.sh` passed. It verified fixture coverage and Android implementation hooks for:

- H1-H6 headings, paragraphs, bold, italic, bold-italic, strikethrough, inline code, mark/highlight, subscript, superscript, links, autolinks, email autolinks, blockquotes, unordered lists, ordered lists, task lists, tables, fenced code, Mermaid fallback, inline math, block math, images, safe video HTML, footnotes, details/summary, generic HTML fallback, mixed CJK/English/Japanese/Korean, and escaped markers.
- Render model block kinds for heading, paragraph, blockquote, unordered list, ordered list, task list, table, code fence, Mermaid, math block, image, video HTML, horizontal rule, footnote, details, and HTML fallback.
- Inline styles for bold, italic, strikethrough, inline code, highlight, subscript, superscript, and math.
- Native Compose reader paths for block preview, blockquote, list, table, code-like blocks, image, media placeholder, footnote, details, fallback, and annotated inline strings.
- Local horizontal scroll constraints for wide code/table/media surfaces.
- Remote image privacy placeholder behavior.
- Mermaid and block math native readable source cards.
- Android rich rendering remains native Kotlin/Compose without a web app runtime.

## Open Blockers Preserved

- Exact wrapper-based L12 commands remain blocked by DNS resolution for `services.gradle.org`.
- Compile-backed system Gradle gates remain blocked by DNS resolution for `dl.google.com`.
- Device/emulator validation remains open because this batch did not run `connectedDebugAndroidTest`, API 27, low-memory/small-screen, or modern-device flows.
- `./gradlew lint`, `./gradlew build`, `./gradlew :core:testDebugUnitTest`, `./gradlew :feature:reader:testDebugUnitTest`, `./gradlew :app:assembleDebug`, and `./gradlew :app:connectedDebugAndroidTest` should remain open until wrapper and dependency resolution are available.

## Supervisor Checklist Recommendation

The supervising session can use this report as Android-owned evidence for:

- L12: Capture Android performance report.
- L12: Capture Android security audit report.
- L12: Capture rich fixture render report.
- L13: Record validation reports under `android/docs/reports/`.

The supervising session should not mark the wrapper-based Android Gradle command gates complete from this batch because the exact `./gradlew` commands remain blocked by `services.gradle.org` DNS, and compile-backed system Gradle commands remain blocked by `dl.google.com` DNS.
