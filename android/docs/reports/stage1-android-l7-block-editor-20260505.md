# Stage 1 Android L7 Block Editor Report - 2026-05-05

## Scope

Implemented one bounded Android-owned L7 block source editor batch under `android/**`.

This batch did not edit `ios/**`, `Docs/Stage1_Mobile_Blueprint.md`, `Docs/todos_20260505.md`, or `.cron/**`.

## Blueprint Items Advanced

- L7: Implement block source editor on Android.
- L7: Fail closed when block source ranges no longer match.

## Changed Files

- `android/app/src/main/java/com/fastmd/mobile/MainActivity.kt`
- `android/app/src/main/java/com/fastmd/mobile/session/FastMdReaderSessionViewModel.kt`
- `android/core/src/main/java/com/fastmd/mobile/core/reader/BlockSourceEdit.kt`
- `android/core/src/main/java/com/fastmd/mobile/core/reader/ReaderUiState.kt`
- `android/core/src/test/java/com/fastmd/mobile/core/contracts/CoreContractsTest.kt`
- `android/core/src/test/java/com/fastmd/mobile/core/reader/BlockSourceEditTest.kt`
- `android/feature/reader/src/main/java/com/fastmd/mobile/feature/reader/ReaderScreen.kt`
- `android/docs/reports/stage1-android-l7-block-editor-20260505.md`

## Implementation Notes

- Added `BlockSourceEditSnapshot`, `BlockSourceEditResult`, and `BlockSourceEdit.apply` in core reader contracts.
- `BlockSourceEdit.apply` replaces only the source slice captured from the rendered block range.
- The apply path fails closed if the saved source range is outside the current document or if the current source slice differs from the captured original block source.
- Extended `ReaderUiState.EditingBlock` to retain the block id, source range, original block source, draft source, dirty state, and a save error message.
- Added ViewModel actions to begin block editing from a rendered block, update the block draft, cancel with dirty confirmation, and restore failed block saves without dropping the draft.
- Added a native Compose block source editor using `TextField`, explicit Save Block / Cancel actions, read-only handling, dirty state display, line-range context, and save error display.
- Wired rendered blocks to expose a block edit action and save the block by building a complete updated source document before using the existing Android save path.
- Block edit save success reparses the full saved document and returns to the ready reader state.
- Block edit validation or save failure keeps the dirty block draft intact and shows the failure in the block editor.
- Removed the outer page `verticalScroll` around the reader screen so the existing block `LazyColumn` remains the active virtualized reader scroller.
- No React Native, Flutter, Cordova, remote WebView shell, WebView renderer, JavaScript renderer, CDN asset, network permission, or broad storage permission was introduced.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `gradle projects` | PASS | Build succeeded and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `gradle :app:compileDebugKotlin` | BLOCKED | Android SDK location is not configured: `SDK location not found. Define a valid SDK location with an ANDROID_HOME environment variable or by setting the sdk.dir path in your project's local properties file at '/Users/wangweiyang/GitHub/fastmd/android/local.properties'.` |
| `gradle :core:testDebugUnitTest` | BLOCKED | Android SDK location is not configured: `SDK location not found. Define a valid SDK location with an ANDROID_HOME environment variable or by setting the sdk.dir path in your project's local properties file at '/Users/wangweiyang/GitHub/fastmd/android/local.properties'.` |
| `java -version` | BLOCKED | `/usr/bin/java` reported: `Unable to locate a Java Runtime.` |
| `test -x ./gradlew && ./gradlew projects || printf 'gradlew missing or not executable\n'` | BLOCKED | No checked-in Android Gradle wrapper exists under `android/`: `gradlew missing or not executable`. |
| `find android -path 'android/.gradle' -prune -o -path 'android/build' -prune -o -type f -print0 \| xargs -0 perl -ne 'if(/[ \t]$/){print "$ARGV:$.: trailing whitespace\n"; $bad=1} END{exit($bad ? 1 : 0)}'` | PASS | No trailing whitespace found in Android files outside local Gradle/build output. |
| `git diff --check -- android` | PASS | No whitespace errors were reported for tracked Android diffs. The Android tree is currently untracked in this workspace, so direct diff output is not available until it is added to Git. |
| `perl -ne 'print "$ARGV:$.:$_" if /[^\x00-\x7F]/' <touched Kotlin files>` | PASS | No non-ASCII characters were reported in touched Kotlin files. |
| `rg -n "MANAGE_EXTERNAL_STORAGE\|READ_EXTERNAL_STORAGE\|READ_MEDIA_\|POST_NOTIFICATIONS\|INTERNET\|WebView\|ReactNative\|Flutter\|Cordova" android/app/src/main android/core/src/main android/feature -S` | PASS | No matches were found. |

## Current Blockers

- Android SDK is still not configured through `ANDROID_HOME` or `android/local.properties`, so Android compile, lint, assemble, unit test, and device validation tasks cannot run.
- No checked-in Android Gradle wrapper exists under `android/`, so required wrapper-based validation remains blocked.
- The shell `java -version` cannot locate a Java runtime, while global Gradle can still run `gradle projects` through its own configured runtime.
- External document mutation detection before save remains open. This batch validates the in-memory mapped block source range before applying a block edit, but it does not re-query the backing document provider for external mutation.
- Durable process death recovery remains open.

## Supervisor Reconciliation Notes

The supervisor can mark these Android-lane items complete based on the implementation files and validation evidence above, subject to rerunning compile/device gates once Android SDK/JDK 17 are configured:

- Implement block source editor on Android.
- Fail closed when block source ranges no longer match.

Keep L7 external mutation, blind overwrite prevention, process recovery, unsupported legacy encoding save posture, and platform validation items open.
