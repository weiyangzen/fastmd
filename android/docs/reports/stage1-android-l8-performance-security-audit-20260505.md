# Stage 1 Android L8 Performance And Security Audit Batch - 2026-05-05

## Scope

Ran one bounded Android-owned L8 implementation batch under `android/**`.

This batch did not edit `ios/**`, `Docs/Stage1_Mobile_Blueprint.md`, `Docs/todos_20260505.md`, or `.cron/**`.

## Blueprint Items Advanced

- L8: Disable expensive animations on Android 8.1 low-memory profile.
- L8: Add Android manifest audit for broad storage, notification, unexpected network, and exported components.
- L8: Ensure Android Stage 1 has no `MANAGE_EXTERNAL_STORAGE`, `READ_EXTERNAL_STORAGE`, `READ_MEDIA_*`, or `POST_NOTIFICATIONS`.
- L8: Ensure Android Stage 1 has no default `INTERNET` permission.
- L8: Ensure Android `allowBackup` posture is documented and disabled for Stage 1 unless explicitly changed.
- L8: Block Android dangerous link schemes by default.

## Changed Files

- `android/core/src/main/java/com/fastmd/mobile/core/performance/LocalAndroidPerformanceProfile.kt`
- `android/app/src/main/java/com/fastmd/mobile/performance/AndroidRuntimeProfileProvider.kt`
- `android/app/src/main/java/com/fastmd/mobile/session/FastMdReaderSessionViewModel.kt`
- `android/app/src/main/java/com/fastmd/mobile/theme/FastMdTheme.kt`
- `android/app/src/main/java/com/fastmd/mobile/MainActivity.kt`
- `android/feature/reader/src/main/java/com/fastmd/mobile/feature/reader/ReaderScreen.kt`
- `android/core/src/test/java/com/fastmd/mobile/core/contracts/CoreContractsTest.kt`
- `android/tools/audit_stage1_manifest.sh`
- `android/docs/reports/stage1-android-l8-performance-security-audit-20260505.md`

## Implementation Notes

- Added `AndroidRuntimeProfileProvider` in the Android app module. It selects the Stage 1 runtime profile from Android platform inputs:
  - `Build.VERSION.SDK_INT`
  - `ActivityManager.isLowRamDevice`
  - `ActivityManager.memoryClass`
  - current resource configuration screen width, height, and smallest width
- Added `LocalAndroidPerformanceProfile` so Compose surfaces can consume the selected platform profile without threading profile flags through every reader component.
- Stored the selected profile in `FastMdReaderSessionViewModel` and provided it through `FastMdTheme`.
- Applied the profile in `ReaderScreen` by using compact reader block spacing and reduced reader viewport height for compact profiles. The underlying profile contract continues to set `disableExpensiveAnimations = true` for `WatchCompact` and `LegacyEfficient`, covering Android 8.1/API 27 and low-memory profiles.
- Verified by source audit that the Android main code does not currently use Compose animation APIs, Android `WebView`, or `android.webkit`; no expensive animation path remains to gate in this batch.
- Added `android/tools/audit_stage1_manifest.sh` as a repeatable local manifest/security audit. It checks:
  - no `<uses-permission>` declarations;
  - no broad storage, notification, or default `INTERNET` permissions;
  - `android:allowBackup="false"` in the app manifest;
  - only the document-entry `MainActivity` is exported;
  - no Android WebView implementation is present in Stage 1 main code.
- Strengthened core contract tests so default `LinkPolicy` blocks dangerous Android-relevant schemes:
  - `javascript:`
  - mixed-case `javascript:`
  - `data:`
  - `file:`
  - `content:`
  - `intent:`
  - `android-app:`
  - `vbscript:`
- No React Native, Flutter, Cordova, remote WebView shell, JavaScript renderer, CDN/network renderer, broad storage permission, notification permission, or default Internet permission was introduced.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `bash tools/audit_stage1_manifest.sh` | PASS | Reported no permissions, no broad storage/notification/default `INTERNET`, `allowBackup=false`, only `MainActivity` exported, and no WebView implementation. |
| `gradle projects` | PASS | Build succeeded and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `gradle :core:testDebugUnitTest --tests com.fastmd.mobile.core.contracts.CoreContractsTest` | BLOCKED | Android SDK location is not configured: `SDK location not found. Define a valid SDK location with an ANDROID_HOME environment variable or by setting the sdk.dir path in your project's local properties file at '/Users/wangweiyang/GitHub/fastmd/android/local.properties'.` |
| `test -x ./gradlew && ./gradlew projects || printf 'gradlew missing or not executable\n'` | BLOCKED | No checked-in Android Gradle wrapper exists under `android/`: `gradlew missing or not executable`. |
| `bash -n tools/audit_stage1_manifest.sh` | PASS | Bash syntax validation completed with no output. |
| `git diff --check -- android` | PASS | No whitespace errors were reported. The Android tree is currently untracked in this workspace, so tracked diff output is not available until it is added to Git. |
| `perl -ne 'print "$ARGV:$.: trailing whitespace\n" if /[ \t]$/' ...touched files...` | PASS | No trailing whitespace was reported in touched Kotlin, script, or report files checked before this report was added. |
| `java -version` | BLOCKED | `/usr/bin/java` reported: `Unable to locate a Java Runtime.` |
| `rg -n "animate\|Animated\|Crossfade\|rememberInfiniteTransition\|WebView\|android.webkit\|<uses-permission\|MANAGE_EXTERNAL_STORAGE\|READ_EXTERNAL_STORAGE\|READ_MEDIA_\|POST_NOTIFICATIONS\|INTERNET\|android:allowBackup=\"true\"" android/app/src/main android/core/src/main android/feature -S` | PASS | No matches were reported. |

## Current Blockers

- Android SDK remains unavailable to Gradle because neither `ANDROID_HOME` nor `android/local.properties` with `sdk.dir` is configured.
- The checked-in Android Gradle wrapper is still absent under `android/`.
- `/usr/bin/java` still cannot locate a system Java runtime, although the installed `gradle` command can run `gradle projects` through its own runtime path.
- Because `:core:testDebugUnitTest` cannot resolve the Android SDK, the strengthened JVM contract tests have not executed locally in this environment.

## Supervisor Reconciliation Notes

The supervisor can use this report as Android-lane evidence for the following L8 items, subject to rerunning compile/unit/lint/device gates after Android SDK/JDK/wrapper setup is repaired:

- Disable expensive animations on Android 8.1 low-memory profile.
- Add Android manifest audit for broad storage, notification, unexpected network, and exported components.
- Ensure Android Stage 1 has no `MANAGE_EXTERNAL_STORAGE`, `READ_EXTERNAL_STORAGE`, `READ_MEDIA_*`, or `POST_NOTIFICATIONS`.
- Ensure Android Stage 1 has no default `INTERNET` permission.
- Ensure Android `allowBackup` posture is documented and disabled for Stage 1 unless explicitly changed.
- Block Android dangerous link schemes by default.

Keep L11 and L12 execution gates open until Android SDK/JDK/wrapper setup allows unit test, compile, lint, assemble, and device validation tasks to run.
