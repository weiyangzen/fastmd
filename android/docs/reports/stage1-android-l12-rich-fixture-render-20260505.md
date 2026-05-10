# Stage 1 Android L12 Rich Fixture Render Report - 2026-05-05

## Scope

One bounded Android-owned batch advanced the L12 rich fixture render evidence and fixed one native parser gap found while auditing `android/test-fixtures/markdown/rich-preview.md`.

No iOS files, authoritative `Docs/` checklist files, or `.cron/` files were edited.

## Android Changes

- `core/src/main/java/com/fastmd/mobile/core/markdown/MarkdownInlineParser.kt`
  - Added safe native inline handling for `<mark>...</mark>`, `<sub>...</sub>`, and `<sup>...</sup>`.
  - These tags now convert into existing `MarkdownInlineStyle.Highlight`, `MarkdownInlineStyle.Subscript`, and `MarkdownInlineStyle.Superscript` spans.
  - Link/autolink parsing still runs before inline HTML tag handling, so `<https://...>` and email autolinks continue to route through `LinkPolicy`.
- `core/src/test/java/com/fastmd/mobile/core/markdown/StructuredMarkdownParserTest.kt`
  - Extended inline parser expectations to cover the rich fixture's safe inline HTML mark/sub/sup forms.
- `tools/audit_rich_fixture_render.sh`
  - Added a platform-local audit for the Android rich fixture surface.
  - The audit checks fixture category presence, parser block kinds, inline style declarations, native reader renderer paths, remote-image placeholder posture, Mermaid/math native fallback cards, parser test coverage, and absence of WebView/web-runtime usage.

## Validation Commands

| Command | Result | Evidence |
| --- | --- | --- |
| `./gradlew projects` | BLOCKED | Fails before Gradle project evaluation because macOS cannot locate a Java runtime: `Unable to locate a Java Runtime.` |
| `gradle projects` | PASS | System Gradle successfully lists root project `fastmd-android` with `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `gradle :core:testDebugUnitTest` | BLOCKED | Fails at Android SDK resolution: `SDK location not found. Define a valid SDK location with an ANDROID_HOME environment variable or by setting the sdk.dir path in .../android/local.properties`. |
| `gradle :feature:reader:testDebugUnitTest` | BLOCKED | Same Android SDK locator failure as `:core:testDebugUnitTest`. |
| `/usr/libexec/java_home -V` | BLOCKED | Fails with `Unable to locate a Java Runtime.` |
| `test -f local.properties ...` | BLOCKED | `android/local.properties` is missing. |
| `bash tools/audit_rich_fixture_render.sh` | PASS | Checks all rich fixture categories, native parser/render coverage, mark/sub/sup inline HTML conversion, native reader renderer paths, remote-image placeholder posture, Mermaid/math fallback cards, and no WebView/web-runtime usage. |
| `bash tools/audit_renderer_assets.sh` | PASS | No Android WebView/android.webkit implementation, no React Native/Flutter/Cordova runtime dependency, and no vendored JS/CSS/font renderer asset tree. |
| `bash tools/audit_stage1_manifest.sh` | PASS | No permissions; no broad storage/notification/default `INTERNET`; `allowBackup=false`; cleartext disabled; only `MainActivity` exported; no WebView implementation; release hardening remains enabled. |
| `bash tools/audit_parser_source_ranges.sh` | PASS | Parser/source-range static audit passed. |

## Rich Fixture Coverage Notes

The Android rich fixture audit confirms platform-local evidence for these Stage 1 render categories:

- Headings H1-H6, paragraphs, mixed CJK/English/Japanese/Korean text, and escaped marker characters.
- Bold, italic, bold-italic, strikethrough, inline code, highlight, subscript, superscript, inline math, links, autolinks, and email autolinks.
- Blockquote, unordered list, ordered list, task list, table, fenced code, Mermaid source-card fallback, block math source-card fallback, image placeholder/local resolution path, video HTML placeholder, horizontal rule, footnote, details/summary fallback, and generic HTML fallback.

The implementation remains native Kotlin/Compose. This batch did not introduce WebView, Android `android.webkit`, React Native, Flutter, Cordova, CDN assets, network renderer dependencies, or vendored JS/CSS/font renderers.

## Supervisor Checklist Evidence

The supervising session can use this report as Android-lane evidence for:

- L12: Capture rich fixture render report.

Keep these L12 items open from this batch:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.
- Capture Android performance report.

Those gates still require a working wrapper/JDK path plus Android SDK configuration and, for device gates, emulator or hardware availability.
