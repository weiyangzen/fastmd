# Stage 1 Android L7 Process Death Recovery Report - 2026-05-05

## Scope

Implemented one bounded Android-owned L7 process-death recovery batch under `android/**`.

This batch did not edit `ios/**`, `Docs/Stage1_Mobile_Blueprint.md`, `Docs/todos_20260505.md`, or `.cron/**`.

## Blueprint Items Advanced

- L7: Offer process death recovery for unsaved edits where platform lifecycle permits.
- L7: Preserve dirty buffer on app background.
- L7: Keep dirty buffer intact after failed save.

## Changed Files

- `android/app/src/main/java/com/fastmd/mobile/MainActivity.kt`
- `android/app/src/main/java/com/fastmd/mobile/document/AndroidDocumentEntry.kt`
- `android/app/src/main/java/com/fastmd/mobile/recovery/AndroidRecoveryDraftStore.kt`
- `android/app/src/main/java/com/fastmd/mobile/session/FastMdReaderSessionViewModel.kt`
- `android/feature/reader/src/main/java/com/fastmd/mobile/feature/reader/ReaderScreen.kt`
- `android/docs/reports/stage1-android-l7-process-death-recovery-20260505.md`

## Implementation Notes

- Added `AndroidRecoveryDraftStore`, which writes recovery metadata plus dirty source/block draft text to app-private files under `Context.filesDir/recovery-draft`.
- Recovery is limited to Android `content://` and app-owned/readable `file://` handles that can be reopened after process death; unsupported entries such as shared text are not persisted.
- Source editor and block editor dirty draft changes now persist asynchronously, with the latest write job cancelling older pending recovery writes to avoid stale draft overwrite races.
- `onStop()` also requests a recovery persistence pass, covering normal backgrounding before OS process death where Android lifecycle permits it.
- Empty/recent-document UI now offers a native Compose recovery prompt with explicit Restore and Delete actions when an app-private recovery draft exists.
- Restore reopens the original document handle, reinstates the active Android handle/metadata, and returns to the source or block editor with the recovered draft and a visible recovered-draft message.
- Block recovery keeps the captured block id, source range, and original block source so the existing block-save path can still fail closed if the backing source no longer matches.
- Save success, explicit discard, and recovery deletion clear the app-private recovery draft.
- Save failure and block range-mismatch failure keep the dirty editor buffer active and refresh the recovery draft.
- No React Native, Flutter, Cordova, remote WebView shell, WebView renderer, JavaScript renderer, CDN asset, network permission, broad storage permission, or public document-content cache was introduced.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `gradle projects` | PASS | Build succeeded and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `gradle :app:compileDebugKotlin` | BLOCKED | Android SDK location is not configured: `SDK location not found. Define a valid SDK location with an ANDROID_HOME environment variable or by setting the sdk.dir path in your project's local properties file at '/Users/wangweiyang/GitHub/fastmd/android/local.properties'.` |
| `java -version` | BLOCKED | `/usr/bin/java` reported: `Unable to locate a Java Runtime.` |
| `test -x ./gradlew && ./gradlew projects || printf 'gradlew missing or not executable\n'` | BLOCKED | No checked-in Android Gradle wrapper exists under `android/`: `gradlew missing or not executable`. |
| `find android -path 'android/.gradle' -prune -o -path 'android/build' -prune -o -type f -print0 \| xargs -0 perl -ne 'if(/[ \t]$/){print "$ARGV:$.: trailing whitespace\n"; $bad=1} END{exit($bad ? 1 : 0)}'` | PASS | No trailing whitespace found in Android files outside local Gradle/build output. |
| `git diff --check -- android/app/src/main/java/com/fastmd/mobile/MainActivity.kt android/app/src/main/java/com/fastmd/mobile/document/AndroidDocumentEntry.kt android/app/src/main/java/com/fastmd/mobile/recovery/AndroidRecoveryDraftStore.kt android/app/src/main/java/com/fastmd/mobile/session/FastMdReaderSessionViewModel.kt android/feature/reader/src/main/java/com/fastmd/mobile/feature/reader/ReaderScreen.kt` | PASS | No whitespace errors were reported for this batch's Android files. |
| `perl -ne 'print "$ARGV:$.:$_" if /[^\x00-\x7F]/' <touched Kotlin files>` | PASS | No non-ASCII characters were reported in touched Kotlin files. |
| `rg -n "MANAGE_EXTERNAL_STORAGE\|READ_EXTERNAL_STORAGE\|READ_MEDIA_\|POST_NOTIFICATIONS\|INTERNET\|WebView\|ReactNative\|Flutter\|Cordova\|https://\|http://" android/app/src/main android/core/src/main android/feature -S` | PASS | Matches were limited to Android XML namespace declarations in manifest/vector resources and existing remote-image classification strings; no broad storage, notification, network permission, WebView usage, or remote renderer dependency was found. |

## Current Blockers

- Android SDK is still not configured through `ANDROID_HOME` or `android/local.properties`, so Android compile, lint, assemble, unit test, and device validation tasks cannot run.
- No checked-in Android Gradle wrapper exists under `android/`, so required wrapper-based validation remains blocked.
- The shell `java -version` cannot locate a Java runtime, while global Gradle can still run `gradle projects` through its own configured runtime.
- Recovery restore could not be device-validated in this local environment because compile/device gates are blocked by the SDK/JDK/wrapper setup above.

## Supervisor Reconciliation Notes

The supervisor can mark this Android-lane item complete based on the implementation files and validation evidence above, subject to rerunning compile/device gates once Android SDK/JDK 17 are configured:

- Offer process death recovery for unsaved edits where platform lifecycle permits.

`Preserve dirty buffer on app background` and `Keep dirty buffer intact after failed save` were previously implemented and are reinforced by this batch's app-private recovery persistence and failed-save recovery refresh.

Keep L11 and L12 validation checklist items open because compile, unit test, lint, assemble, wrapper-based, and device validation remain blocked by local SDK/JDK/wrapper setup.
