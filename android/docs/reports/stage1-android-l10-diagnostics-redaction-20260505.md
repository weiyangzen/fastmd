# Stage 1 Android L10 Diagnostics Redaction Report - 2026-05-05

## Scope

Implemented one bounded Android-owned L10 diagnostics hardening batch under `android/**`.

This batch did not edit `ios/**`, `Docs/Stage1_Mobile_Blueprint.md`, `Docs/todos_20260505.md`, or `.cron/**`.

## Blueprint Items Advanced

- L10: Add local diagnostics report excluding document content, full path, full URI, query strings, and clipboard.
- L10: Include parse, render, search, save, device class, renderer profile, file size bucket, and last error category in diagnostics.
- L11: Add log redaction tests.

## Changed Files

- `android/core/src/main/java/com/fastmd/mobile/core/diagnostics/DiagnosticsRedactionPolicy.kt`
- `android/core/src/main/java/com/fastmd/mobile/core/diagnostics/LocalDiagnosticsReport.kt`
- `android/core/src/test/java/com/fastmd/mobile/core/contracts/CoreContractsTest.kt`
- `android/tools/audit_diagnostics_redaction.sh`
- `android/docs/reports/stage1-android-l10-diagnostics-redaction-20260505.md`

## Implementation Notes

- Added `DiagnosticsRedactionPolicy` in the Android core diagnostics contract.
- `LocalDiagnosticsReport.toRedactedText()` now passes all generated diagnostics text through the redaction policy before the app can display it.
- The redaction policy rejects URI-like fragments, common local absolute path markers, raw document reference fields, display-name fields, path/URI fields, search query fields, clipboard fields, and document source/body fields.
- The policy also caps each diagnostics line length so diagnostics remain summary-only and cannot quietly become a content dump.
- Existing diagnostics continue to include only platform, Android device class, renderer profile, document presence/origin/writable status, file size bucket, parse/render/search/save operation summaries, and the last error category.
- Added contract-test coverage for both a safe diagnostics string and sensitive fragments that must be rejected.
- Added `android/tools/audit_diagnostics_redaction.sh` as a repeatable local audit that runs without Android SDK access and verifies the diagnostics path remains pre-redacted before reaching `SettingsScreen`.
- No React Native, Flutter, Cordova, remote WebView shell, WebView renderer, JavaScript renderer, CDN asset, network permission, or broad storage permission was introduced.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `bash -n tools/audit_diagnostics_redaction.sh` | PASS | Bash syntax validation completed with no output. |
| `bash tools/audit_diagnostics_redaction.sh` | PASS | Reported `PASS: Android diagnostics redaction audit completed.` |
| `bash tools/audit_accessibility_semantics.sh` | PASS | Reported `PASS: Android accessibility semantics audit completed.` |
| `bash tools/audit_stage1_manifest.sh` | PASS | Reported no permissions, no broad storage/notification/default `INTERNET`, `allowBackup=false`, cleartext disabled, only `MainActivity` exported, no WebView implementation, and release hardening enabled. |
| `gradle projects` | PASS | Build succeeded and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `gradle :core:testDebugUnitTest --tests com.fastmd.mobile.core.contracts.CoreContractsTest` | BLOCKED | Android SDK location is not configured. Gradle reported: `SDK location not found. Define a valid SDK location with an ANDROID_HOME environment variable or by setting the sdk.dir path in your project's local properties file at '/Users/wangweiyang/GitHub/fastmd/android/local.properties'.` |
| `java -version` | BLOCKED | `/usr/bin/java` reported: `Unable to locate a Java Runtime.` |
| `test -x ./gradlew && ./gradlew projects || printf 'gradlew missing or not executable\n'` | BLOCKED | No checked-in Android Gradle wrapper exists under `android/`: `gradlew missing or not executable`. |
| `git diff --check -- android/core/src/main/java/com/fastmd/mobile/core/diagnostics/DiagnosticsRedactionPolicy.kt android/core/src/main/java/com/fastmd/mobile/core/diagnostics/LocalDiagnosticsReport.kt android/core/src/test/java/com/fastmd/mobile/core/contracts/CoreContractsTest.kt android/tools/audit_diagnostics_redaction.sh` | PASS | No whitespace errors were reported. The Android tree is currently untracked in this workspace, so tracked diff output is not available until it is added to Git. |
| `perl -ne 'print "$ARGV:$.: trailing whitespace\n" if /[ \t]$/' <touched files>` | PASS | No trailing whitespace was reported in touched Kotlin or shell files. |
| `perl -ne 'print "$ARGV:$.:$_" if /[^\x00-\x7F]/' <touched files>` | PASS | No non-ASCII characters were reported in touched Kotlin or shell files. |

## Current Blockers

- Android SDK remains unavailable to Gradle because neither `ANDROID_HOME` nor `android/local.properties` with `sdk.dir` is configured.
- The checked-in Android Gradle wrapper is still absent under `android/`.
- `/usr/bin/java` still cannot locate a system Java runtime, although the installed `gradle` command can run `gradle projects` through its own runtime path.
- Compile, unit test, lint, instrumentation, screenshot, and device validation gates remain blocked by the SDK/JDK/wrapper setup above.

## Supervisor Reconciliation Notes

The supervisor can use this report as Android-lane evidence for these items, subject to rerunning compile/unit/device gates after Android SDK/JDK/wrapper setup is repaired:

- Add local diagnostics report excluding document content, full path, full URI, query strings, and clipboard.
- Include parse, render, search, save, device class, renderer profile, file size bucket, and last error category in diagnostics.
- Add log redaction tests.

Keep Android fontScale device validation, screenshot/accessibility smoke validation, and platform validation checklist items open until Android SDK/device validation is available.
