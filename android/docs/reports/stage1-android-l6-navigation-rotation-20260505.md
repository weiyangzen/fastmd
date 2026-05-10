# Stage 1 Android L6 Navigation And Rotation Report - 2026-05-05

## Scope

Implemented one bounded Android-owned L6 reader navigation and rotation-state batch under `android/**`.

This batch did not edit `ios/**`, `Docs/Stage1_Mobile_Blueprint.md`, `Docs/todos_20260505.md`, or `.cron/**`.

## Blueprint Items Advanced

- L6: Implement Back/navigation behavior for search, block edit, source edit, reader, and recent documents.
- L6: Preserve active document, scroll, font tier, search query, and dirty edit buffer through rotation.

## Changed Files

- `android/app/src/main/java/com/fastmd/mobile/MainActivity.kt`
- `android/app/src/main/java/com/fastmd/mobile/session/FastMdReaderSessionViewModel.kt`
- `android/feature/reader/src/main/java/com/fastmd/mobile/feature/reader/ReaderScreen.kt`
- `android/docs/reports/stage1-android-l6-navigation-rotation-20260505.md`

## Implementation Notes

- Added `FastMdReaderSessionViewModel` as the Android reader-session owner for active `ReaderUiState`, recents, font tier, and theme mode.
- Moved the mutable reader session out of `MainActivity` fields and into the ViewModel so configuration changes retain the active document, search state, selected font tier, and any future dirty edit states represented by `ReaderUiState.EditingSource` or `ReaderUiState.EditingBlock`.
- Guarded initial intent handling so rotation does not reprocess the last `ACTION_VIEW` or `ACTION_SEND` intent when an existing ViewModel session is already active.
- Added Compose `BackHandler` wiring:
  - search back returns to the underlying ready reader state;
  - read-only back returns to the ready reader state;
  - ready/error/loading/rendering/saving/permission-lost back returns to the empty/recent-document surface;
  - dirty edit states are retained rather than discarded until a later explicit dirty-confirmation UI batch exists.
- Added first-visible-block tracking from the reader `LazyColumn` into `ReaderUiState.Ready.scrollBlockId`.
- The reader initializes its lazy list from the retained `scrollBlockId`, preserving block-level scroll position across rotation without storing document source in `Bundle` instance state.
- No React Native, Flutter, Cordova, remote WebView shell, WebView renderer, JavaScript renderer, CDN asset, network permission, or broad storage permission was introduced.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `gradle projects` | PASS | Build succeeded and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `gradle :app:compileDebugKotlin` | BLOCKED | Android SDK location is not configured: `SDK location not found. Define a valid SDK location with an ANDROID_HOME environment variable or by setting the sdk.dir path in your project's local properties file at '/Users/wangweiyang/GitHub/fastmd/android/local.properties'.` |
| `java -version` | BLOCKED | `/usr/bin/java` reported: `Unable to locate a Java Runtime.` |
| `test -x ./gradlew && ./gradlew projects || printf 'gradlew missing or not executable\n'` | BLOCKED | No checked-in Android Gradle wrapper exists under `android/`: `gradlew missing or not executable`. |
| `find android -path 'android/.gradle' -prune -o -path 'android/build' -prune -o -type f -print0 \| xargs -0 perl -ne 'if(/[ \t]$/){print "$ARGV:$.: trailing whitespace\n"; $bad=1} END{exit($bad ? 1 : 0)}'` | PASS | No trailing whitespace found in Android files outside local Gradle/build output. |
| `git diff --check -- android` | PASS | No whitespace errors were reported for tracked Android diffs. The Android tree is currently untracked in this workspace, so direct diff output is not available until it is added to Git. |
| `perl -ne 'print "$ARGV:$.:$_" if /[^\x00-\x7F]/' android/app/src/main/java/com/fastmd/mobile/MainActivity.kt android/app/src/main/java/com/fastmd/mobile/session/FastMdReaderSessionViewModel.kt android/feature/reader/src/main/java/com/fastmd/mobile/feature/reader/ReaderScreen.kt` | PASS | No non-ASCII characters were reported in the touched Kotlin files. |
| `rg -n "<uses-permission\|WebView\|INTERNET\|MANAGE_EXTERNAL_STORAGE\|READ_EXTERNAL_STORAGE\|READ_MEDIA_\|POST_NOTIFICATIONS\|android:allowBackup=\"true\"\|https://\|http://" android/app/src/main android/core/src/main android/feature -S` | PASS | Matches were limited to Android XML namespace declarations in manifest/vector resources and the parser's remote-image classification strings; no broad storage, notification, network permission, WebView usage, backup-enabled posture, or remote renderer dependency was found. |

## Current Blockers

- Android SDK is still not configured through `ANDROID_HOME` or `android/local.properties`, so Android compile, unit test, lint, assemble, and device validation tasks cannot run.
- No checked-in Android Gradle wrapper exists under `android/`, so required wrapper-based validation remains blocked.
- The shell `java -version` cannot locate a Java runtime, while global Gradle can still run `gradle projects` through its own configured runtime.
- Dirty edit confirmation dialogs are not implemented yet. Dirty edit states are intentionally retained instead of being discarded on Back; the final Back/navigation checklist should remain open until the Android editing UI can show the required confirmation.

## Supervisor Reconciliation Notes

The supervisor can mark this Android L6 item complete for the Android lane based on implementation files and validation evidence above, subject to rerunning compile/device gates once Android SDK/JDK 17 are configured:

- Preserve active document, scroll, font tier, search query, and dirty edit buffer through rotation.

The Back/navigation item is advanced but should remain open until a later Android editing batch adds dirty-confirmation UI for source/block editors.

Keep L11 and L12 validation checklist items open because compile, unit test, lint, assemble, wrapper-based, and device validation remain blocked by local SDK/JDK/wrapper setup.
