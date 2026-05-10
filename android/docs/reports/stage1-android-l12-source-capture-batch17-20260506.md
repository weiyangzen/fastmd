# Stage 1 Android L12 Source Capture Batch 17 - 2026-05-06

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
platform validation cluster. This batch retried the earliest Gradle gates and then
advanced the Android source-level report capture gates that the local environment
can execute without an attached emulator.

No `ios/**`, shared `Docs/**`, or `.cron/**` files were edited.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-source-capture-batch17-20260506.md`

## Environment

- Repository: `/Users/wangweiyang/GitHub/fastmd`
- Android working directory: `/Users/wangweiyang/GitHub/fastmd/android`
- Gradle entry point: checked-in wrapper `./gradlew`
- `local.properties`: present, with `sdk.dir=/Users/wangweiyang/Library/Android/sdk`
- Installed Android platforms observed: `android-31`, `android-32`, `android-33`,
  `android-34`, `android-35`, `android-36`
- API 27 system-image directory: not present at
  `/Users/wangweiyang/Library/Android/sdk/system-images/android-27`
- Device state: `adb devices` reported no attached devices or running emulators
- Java runtime used for Gradle:
  `/Applications/Android Studio.app/Contents/jbr/Contents/Home`

```text
openjdk version "21.0.6" 2025-01-21
OpenJDK Runtime Environment (build 21.0.6+-13391695-b895.109)
OpenJDK 64-Bit Server VM (build 21.0.6+-13391695-b895.109, mixed mode)
```

System Java discovery remains blocked:

```text
/usr/libexec/java_home -V
The operation couldn't be completed. Unable to locate a Java Runtime.
```

## Validation Results

All Gradle commands were run with:

```bash
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
```

| Command | Result | Evidence |
| --- | --- | --- |
| `./gradlew projects --no-daemon` | PASS | Wrapper-backed Gradle evaluated root project `fastmd-android` and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `./gradlew lint --no-daemon` | BLOCKED | Gradle reached `:core:extractDebugAnnotations`, then timed out fetching `com.android.tools.lint:lint-gradle:31.13.2` from `https://dl.google.com/dl/android/maven2/...`. |
| `./gradlew :core:testDebugUnitTest --no-daemon` | BLOCKED | Gradle reached `:core:testDebugUnitTest`, then timed out fetching AndroidX runtime jars `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0` from Google Maven. |
| `./gradlew stage1AndroidPerformanceReport stage1AndroidSecurityAuditReport stage1AndroidRichFixtureRenderReport --no-daemon` | PASS | Ran the Android-local source capture gates for performance posture, security posture, and native rich fixture rendering. |
| `adb devices` | BLOCKED | Command ran, but no attached device or emulator was listed. |

## Source Capture Gate Evidence

### Android Performance Report

`stage1AndroidPerformanceReport` passed through `:auditPerformanceReport`.

Evidence captured by the task:

- Android performance profiles are declared for Watch Compact, Legacy Efficient,
  Modern Standard, and Large Screen.
- The audit printed the local fixture size matrix for representative Markdown
  documents including `basic.md`, `rich-preview.md`, `long-1mb.md`,
  `large-5mb.md`, `huge-table.md`, `huge-code-block.md`, `remote-image.md`, and
  `local-image.md`.
- The audit completed with `PASS: Android performance report audit completed.`

### Android Security Audit Report

`stage1AndroidSecurityAuditReport` passed through `:auditSecurityReport`.

Evidence captured by the task:

- No `uses-permission` declarations are present.
- No broad storage, notification, or default `INTERNET` permission is present.
- The app manifest documents Stage 1 backup posture with `allowBackup=false`.
- Cleartext network traffic is disabled.
- Only the document-entry `MainActivity` is exported.
- No Android WebView implementation is present in Stage 1 main code.
- Release build type enables R8 minify, resource shrinking, non-debuggable
  output, and app ProGuard rules.
- No React Native, Flutter, Cordova, or equivalent web runtime dependency is
  present.
- No vendored JS/CSS/font renderer asset tree is present; Android rich blocks use
  native fallback paths.

### Android Rich Fixture Render Report

`stage1AndroidRichFixtureRenderReport` passed through
`:auditRichFixtureRenderReport`.

Evidence captured by the task:

- The rich fixture includes coverage for headings, emphasis, strikethrough,
  inline code, highlight, subscript, superscript, links, autolinks, email
  autolinks, blockquotes, unordered lists, ordered lists, task lists, tables,
  fenced code, Mermaid fallback, inline math, block math, images, video HTML,
  footnotes, details/summary, generic HTML fallback, mixed CJK/Japanese/Korean
  content, and escaped markers.
- The structured render model and parser declare/emit the expected native block
  kinds: heading, paragraph, blockquote, unordered list, ordered list, task list,
  table, code fence, Mermaid, math block, image, video HTML, horizontal rule,
  footnote, details, and HTML fallback.
- The inline render model declares bold, italic, strikethrough, inline code,
  highlight, subscript, superscript, and math styles.
- The reader has native Kotlin/Compose render paths for block previews,
  blockquotes, lists, tables, code-like blocks, image placeholders, media
  placeholders, footnotes, details, safe fallback blocks, and annotated strings.
- Wide code/table/media surfaces are constrained with local horizontal scroll.
- Remote images preserve privacy through placeholders.
- Mermaid and block math render as native readable source cards.
- Parser tests cover inline styles, safe inline HTML conversions, rich block
  kinds, math, image, footnote, and safe HTML fallback attributes.
- The audit completed with:
  `PASS: Android rich rendering remains native Kotlin/Compose without a web app runtime.`

## Remaining Blockers

- L12 `./gradlew lint` remains open because Google Maven timed out resolving
  `com.android.tools.lint:lint-gradle:31.13.2`.
- L12 `./gradlew :core:testDebugUnitTest` remains open because Google Maven timed
  out resolving AndroidX runtime jars.
- L12 `./gradlew build`, `./gradlew :feature:reader:testDebugUnitTest`,
  `./gradlew :app:assembleDebug`, and `./gradlew :app:connectedDebugAndroidTest`
  remain open behind the same dependency/device availability blockers until
  resolved by a later batch.
- L12 Android API 27 validation remains open because no API 27 system image is
  installed locally and no device/emulator is attached.
- L12 Android low-memory/small-screen and modern-device validation remain open
  because `adb devices` lists no validation target.
- The blueprint calls for JDK 17, but no system JDK 17 is registered in this
  environment. Gradle validation in this batch used Android Studio's bundled
  Java 21 runtime.

## Supervisor Checklist Recommendation

The supervising session can use this report as Android-lane evidence for:

- L12: Run Android `./gradlew projects` as the minimum wrapper-backed Gradle
  project validation.
- L12: Capture Android performance report.
- L12: Capture Android security audit report.
- L12: Capture rich fixture render report.
- L13: Record validation reports under `android/docs/reports/`.

Do not mark Android lint, build, unit-test, assemble, connected-device, API 27,
low-memory/small-screen, or modern-device validation complete from this batch.
