# Stage 1 Android L10 Font Scale Validation Report - 2026-05-05

## Scope

Implemented one bounded Android-owned L10 font-scale validation batch under `android/**`.

This batch did not edit `ios/**`, `Docs/Stage1_Mobile_Blueprint.md`, `Docs/todos_20260505.md`, or `.cron/**`.

## Blueprint Items Advanced

- L10: Validate Android fontScale with all four font tiers.

## Changed Files

- `android/core/src/test/java/com/fastmd/mobile/core/contracts/CoreContractsTest.kt`
- `android/tools/audit_font_scale_tiers.sh`
- `android/docs/reports/stage1-android-l10-fontscale-validation-20260505.md`

## Implementation Notes

- Added `fontTierContractKeepsSystemFontScaleComposable` to the Android core contract tests.
- The contract samples Android fontScale values `0.85`, `1.0`, `1.3`, and `2.0` across all four Stage 1 tiers: Compact, Default, Large, and Reader.
- The sampled contract verifies every tier keeps positive body/code sizes, keeps code text no larger than body text, and keeps body/code line height larger than the scaled text size.
- Added `android/tools/audit_font_scale_tiers.sh` as a repeatable local audit that does not require Android SDK access.
- The audit verifies the Stage 1 tier constants exactly match the blueprint:
  - Compact: body `14sp`, code `13sp`, line height multiplier `1.48`.
  - Default: body `16sp`, code `15sp`, line height multiplier `1.52`.
  - Large: body `18sp`, code `17sp`, line height multiplier `1.56`.
  - Reader: body `21sp`, code `19sp`, line height multiplier `1.60`.
- The audit verifies `ReaderScreen.withFontTier` emits `sp` text units for both `fontSize` and `lineHeight`, which lets Android system font scale compose with the Stage 1 tier base sizes instead of being neutralized by fixed pixels or `dp`.
- The audit scans Android app/core/feature source for `LocalDensity`, explicit `fontScale =`, `TextUnit`, or text size/line-height assignment through `dp`; no matches are allowed.
- The audit prints a 16-row source-level validation matrix covering 4 font tiers by 4 sampled Android fontScale values.
- No React Native, Flutter, Cordova, remote WebView shell, WebView renderer, JavaScript renderer, CDN asset, network permission, or broad storage permission was introduced.

## Font Scale Matrix

`bash tools/audit_font_scale_tiers.sh` produced:

```text
Compact fontScale 0.85 body 11.90sp code 11.05sp lineHeight 17.61sp
Compact fontScale 1.00 body 14.00sp code 13.00sp lineHeight 20.72sp
Compact fontScale 1.30 body 18.20sp code 16.90sp lineHeight 26.94sp
Compact fontScale 2.00 body 28.00sp code 26.00sp lineHeight 41.44sp
Default fontScale 0.85 body 13.60sp code 12.75sp lineHeight 20.67sp
Default fontScale 1.00 body 16.00sp code 15.00sp lineHeight 24.32sp
Default fontScale 1.30 body 20.80sp code 19.50sp lineHeight 31.62sp
Default fontScale 2.00 body 32.00sp code 30.00sp lineHeight 48.64sp
Large fontScale 0.85 body 15.30sp code 14.45sp lineHeight 23.87sp
Large fontScale 1.00 body 18.00sp code 17.00sp lineHeight 28.08sp
Large fontScale 1.30 body 23.40sp code 22.10sp lineHeight 36.50sp
Large fontScale 2.00 body 36.00sp code 34.00sp lineHeight 56.16sp
Reader fontScale 0.85 body 17.85sp code 16.15sp lineHeight 28.56sp
Reader fontScale 1.00 body 21.00sp code 19.00sp lineHeight 33.60sp
Reader fontScale 1.30 body 27.30sp code 24.70sp lineHeight 43.68sp
Reader fontScale 2.00 body 42.00sp code 38.00sp lineHeight 67.20sp
PASS: Android fontScale tier audit completed.
```

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `bash -n tools/audit_font_scale_tiers.sh` | PASS | Bash syntax validation completed with no output. |
| `bash tools/audit_font_scale_tiers.sh` | PASS | Printed the 16-row four-tier by four-fontScale matrix above and reported `PASS: Android fontScale tier audit completed.` |
| `bash tools/audit_accessibility_semantics.sh` | PASS | Reported `PASS: Android accessibility semantics audit completed.` |
| `bash tools/audit_stage1_manifest.sh` | PASS | Reported no permissions, no broad storage/notification/default `INTERNET`, `allowBackup=false`, cleartext disabled, only `MainActivity` exported, no WebView implementation, and release hardening enabled. |
| `gradle projects` | PASS | Build succeeded and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `gradle :core:testDebugUnitTest --tests com.fastmd.mobile.core.contracts.CoreContractsTest` | BLOCKED | Android SDK location is not configured. Gradle reported: `SDK location not found. Define a valid SDK location with an ANDROID_HOME environment variable or by setting the sdk.dir path in your project's local properties file at '/Users/wangweiyang/GitHub/fastmd/android/local.properties'.` |
| `java -version` | BLOCKED | `/usr/bin/java` reported: `Unable to locate a Java Runtime.` |
| `test -x ./gradlew && ./gradlew projects || printf 'gradlew missing or not executable\n'` | BLOCKED | No checked-in Android Gradle wrapper exists under `android/`: `gradlew missing or not executable`. |
| `git diff --check -- android/core/src/test/java/com/fastmd/mobile/core/contracts/CoreContractsTest.kt android/tools/audit_font_scale_tiers.sh` | PASS | No whitespace errors were reported. The Android tree is currently untracked in this workspace, so tracked diff output is not available until it is added to Git. |
| `perl -ne 'print "$ARGV:$.: trailing whitespace\n" if /[ \t]$/' android/core/src/test/java/com/fastmd/mobile/core/contracts/CoreContractsTest.kt android/tools/audit_font_scale_tiers.sh` | PASS | No trailing whitespace was reported in this batch's touched Kotlin or shell files. |
| `perl -ne 'print "$ARGV:$.:$_" if /[^\x00-\x7F]/' android/core/src/test/java/com/fastmd/mobile/core/contracts/CoreContractsTest.kt android/tools/audit_font_scale_tiers.sh` | PASS | No non-ASCII characters were reported in this batch's touched Kotlin or shell files. |

## Current Blockers

- Android SDK remains unavailable to Gradle because neither `ANDROID_HOME` nor `android/local.properties` with `sdk.dir` is configured.
- The checked-in Android Gradle wrapper is still absent under `android/`.
- `/usr/bin/java` still cannot locate a system Java runtime, although the installed `gradle` command can run `gradle projects` through its own configured runtime path.
- Device or emulator font-scale screenshots and TalkBack traversal cannot be captured in this local environment until Android SDK/JDK/wrapper setup is repaired.

## Supervisor Reconciliation Notes

The supervisor can use this report as Android-lane evidence for this L10 item, subject to rerunning device/screenshot accessibility checks once Android SDK/JDK/wrapper setup is repaired:

- Validate Android fontScale with all four font tiers.

Keep L11/L12 compile, unit test, lint, assemble, instrumentation, screenshot, and device validation checklist items open until the Android SDK/JDK/wrapper blockers are resolved.
