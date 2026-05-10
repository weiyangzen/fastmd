# Stage 1 Android L11 Parser And Source Range Test Report - 2026-05-05

## Scope

Implemented one bounded Android-owned L11 automated-test batch under `android/**`.

This batch did not edit `ios/**`, `Docs/Stage1_Mobile_Blueprint.md`, `Docs/todos_20260505.md`, or `.cron/**`.

## Blueprint Items Advanced

- L11: Add parser contract tests.
- L11: Add source range mapping tests.

## Changed Files

- `android/core/src/test/java/com/fastmd/mobile/core/markdown/StructuredMarkdownParserTest.kt`
- `android/tools/audit_parser_source_ranges.sh`
- `android/docs/reports/stage1-android-l11-parser-source-ranges-20260505.md`

## Implementation Notes

- Added `parserContractKeepsStableOrderedRangesForRichBlockSurface` to exercise the Stage 1 native parser contract across the rich block surface.
- The new parser contract test covers headings, paragraphs, blockquotes, unordered lists, ordered lists, task lists, tables, code fences, Mermaid fences, math blocks, local images, video HTML placeholders, horizontal rules, footnotes, details fallback, and generic HTML fallback.
- The contract test verifies stable block ids across repeated parses, contiguous ordinals, unique ids, positive source revision, ordered non-overlapping source ranges, and nonblank source slices for rendered blocks.
- Added `sourceRangesMapBackToExactEditableSourceSlices` to verify parser ranges map back to exact Markdown source substrings used by block editing.
- The source-range test includes CRLF input and verifies exact slices for a heading, multi-line paragraph, fenced code block, and blockquote.
- Added `android/tools/audit_parser_source_ranges.sh`, a no-SDK audit that verifies:
  - parser blocks are constructed with `SourceRange`;
  - parser ranges use original source offsets and one-based source lines;
  - source line splitting preserves original line endings in source slices;
  - parser ordinals are assigned contiguously;
  - parser block ids are source-derived and stable;
  - render model contracts enforce unique ids and contiguous ordinals;
  - block edit application uses parser source ranges as exact source slices and fails closed on mismatch;
  - the focused parser/source-range tests exist.
- No React Native, Flutter, Cordova, remote WebView shell, WebView renderer, JavaScript renderer, CDN/network renderer, broad storage permission, notification permission, or default Internet permission was introduced.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `bash -n tools/audit_parser_source_ranges.sh` | PASS | Bash syntax validation completed with no output. |
| `bash tools/audit_parser_source_ranges.sh` | PASS | Reported `PASS: Android parser/source-range audit completed.` |
| `bash tools/audit_stage1_manifest.sh` | PASS | Reported no permissions, no broad storage/notification/default `INTERNET`, `allowBackup=false`, cleartext disabled, only `MainActivity` exported, no WebView implementation, and release hardening enabled. |
| `gradle projects` | PASS | Build succeeded and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `gradle :core:testDebugUnitTest --tests com.fastmd.mobile.core.markdown.StructuredMarkdownParserTest` | BLOCKED | Android SDK location is not configured. Gradle reported: `SDK location not found. Define a valid SDK location with an ANDROID_HOME environment variable or by setting the sdk.dir path in your project's local properties file at '/Users/wangweiyang/GitHub/fastmd/android/local.properties'.` |
| `test -x ./gradlew && ./gradlew projects || printf 'gradlew missing or not executable\n'` | BLOCKED | No checked-in Android Gradle wrapper exists under `android/`: `gradlew missing or not executable`. |
| `java -version` | BLOCKED | `/usr/bin/java` reported: `Unable to locate a Java Runtime.` |
| `git diff --check -- android/core/src/test/java/com/fastmd/mobile/core/markdown/StructuredMarkdownParserTest.kt android/tools/audit_parser_source_ranges.sh` | PASS | No whitespace errors were reported for this batch's Android files. |
| `perl -ne 'print "$ARGV:$.: trailing whitespace\n" if /[ \t]$/' android/core/src/test/java/com/fastmd/mobile/core/markdown/StructuredMarkdownParserTest.kt android/tools/audit_parser_source_ranges.sh` | PASS | No trailing whitespace was reported in this batch's touched Kotlin or shell files. |

## Current Blockers

- Android SDK remains unavailable to Gradle because neither `ANDROID_HOME` nor `android/local.properties` with `sdk.dir` is configured.
- The checked-in Android Gradle wrapper is still absent under `android/`.
- `/usr/bin/java` still cannot locate a system Java runtime, although the installed `gradle` command can run `gradle projects` through its own runtime path.
- The new parser/source-range unit tests have not executed locally because `:core:testDebugUnitTest` cannot resolve the Android SDK.

## Supervisor Reconciliation Notes

The supervisor can use this report as Android-lane implementation evidence for:

- L11: Add parser contract tests.
- L11: Add source range mapping tests.

Keep L11/L12 execution gates open until Android SDK/JDK/wrapper setup allows unit test, compile, lint, assemble, instrumentation, screenshot, and device validation tasks to run.
