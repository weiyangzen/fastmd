# Stage 1 Android L11 Save Integrity Test Report - 2026-05-05

## Scope

Implemented one bounded Android-owned L11 save-integrity coverage batch under `android/**`.

This batch did not edit `ios/**`, `Docs/Stage1_Mobile_Blueprint.md`, `Docs/todos_20260505.md`, or `.cron/**`.

## Blueprint Items Advanced

- L11: Add save integrity tests for BOM, CRLF/LF, external mutation, and write failure.

## Changed Files

- `android/app/src/main/java/com/fastmd/mobile/document/AndroidDocumentEntry.kt`
- `android/core/src/main/java/com/fastmd/mobile/core/document/MarkdownSourceCodec.kt`
- `android/core/src/test/java/com/fastmd/mobile/core/document/MarkdownSaveIntegrityTest.kt`
- `android/tools/audit_save_integrity.sh`
- `android/docs/reports/stage1-android-l11-save-integrity-tests-20260505.md`

## Implementation Notes

- Added `MarkdownSourceCodec` as a pure Android core document contract for UTF-8 Markdown source decoding and save-byte preparation.
- Moved BOM stripping, one-BOM UTF-8-BOM encoding, loaded line-ending normalization, and line-ending detection into the shared core codec instead of keeping them private inside the Android document loader.
- Updated `AndroidMarkdownDocumentLoader.save` to build the complete prepared source and byte array before opening any destination output stream.
- Kept the existing external-mutation guard in front of `openOutputStream(uri, "wt")` and app-owned file writes.
- Added `MarkdownSaveIntegrityTest` covering:
  - UTF-8-BOM saves do not duplicate a leading BOM.
  - UTF-8 saves strip accidental leading BOM text.
  - CRLF-loaded documents save with CRLF.
  - LF-loaded documents save with LF.
  - Mixed line-ending documents remain unchanged.
  - UTF-8 BOM decoding strips the BOM from in-memory source while retaining encoding metadata.
- Added `tools/audit_save_integrity.sh`, a no-SDK Android audit that verifies:
  - the loader uses the shared save preparation contract;
  - the external mutation comparison exists and happens before opening the output stream;
  - SAF and app-owned file saves write the complete prepared byte array;
  - save IO failure paths are present;
  - source and block save failures restore dirty editor drafts and refresh app-private recovery drafts.
- No React Native, Flutter, Cordova, remote WebView shell, WebView renderer, JavaScript renderer, CDN/network renderer, broad storage permission, notification permission, or default Internet permission was introduced.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `bash -n tools/audit_save_integrity.sh` | PASS | Bash syntax validation completed with no output. |
| `bash tools/audit_save_integrity.sh` | PASS | Reported `PASS: Android save integrity audit completed.` |
| `bash tools/audit_stage1_manifest.sh` | PASS | Reported no permissions, no broad storage/notification/default `INTERNET`, `allowBackup=false`, cleartext disabled, only `MainActivity` exported, no WebView implementation, and release hardening enabled. |
| `bash tools/audit_accessibility_semantics.sh` | PASS | Reported `PASS: Android accessibility semantics audit completed.` |
| `bash tools/audit_diagnostics_redaction.sh` | PASS | Reported `PASS: Android diagnostics redaction audit completed.` |
| `bash tools/audit_font_scale_tiers.sh` | PASS | Printed the 16-row four-tier by four-fontScale matrix and reported `PASS: Android fontScale tier audit completed.` |
| `gradle projects` | PASS | Build succeeded and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `gradle :core:testDebugUnitTest --tests com.fastmd.mobile.core.document.MarkdownSaveIntegrityTest` | BLOCKED | Android SDK location is not configured. Gradle reported: `SDK location not found. Define a valid SDK location with an ANDROID_HOME environment variable or by setting the sdk.dir path in your project's local properties file at '/Users/wangweiyang/GitHub/fastmd/android/local.properties'.` |
| `test -x ./gradlew && ./gradlew projects || printf 'gradlew missing or not executable\n'` | BLOCKED | No checked-in Android Gradle wrapper exists under `android/`: `gradlew missing or not executable`. |
| `java -version` | BLOCKED | `/usr/bin/java` reported: `Unable to locate a Java Runtime.` |
| `git diff --check -- android` | PASS | No whitespace errors were reported. The Android tree is currently untracked in this workspace, so tracked diff output is not available until it is added to Git. |
| `perl -ne 'print "$ARGV:$.: trailing whitespace\n" if /[ \t]$/' <touched files>` | PASS | No trailing whitespace was reported in this batch's touched Kotlin or shell files. |
| `perl -ne 'print "$ARGV:$.:$_" if /[^\x00-\x7F]/' <touched files>` | PASS | No non-ASCII characters were reported in this batch's touched Kotlin or shell files. |

## Current Blockers

- Android SDK remains unavailable to Gradle because neither `ANDROID_HOME` nor `android/local.properties` with `sdk.dir` is configured.
- The checked-in Android Gradle wrapper is still absent under `android/`.
- `/usr/bin/java` still cannot locate a system Java runtime, although the installed `gradle` command can run `gradle projects` through its own configured runtime path.
- The new `MarkdownSaveIntegrityTest` file has not executed locally because `:core:testDebugUnitTest` cannot resolve the Android SDK.

## Supervisor Reconciliation Notes

The supervisor can use this report as Android-lane implementation evidence for:

- L11: Add save integrity tests for BOM, CRLF/LF, external mutation, and write failure.

Keep L11/L12 execution gates open until Android SDK/JDK/wrapper setup allows unit test, compile, lint, assemble, instrumentation, and device validation tasks to run.
