# Stage 1 Android L7 Source Editor And Save Report - 2026-05-05

## Scope

Implemented one bounded Android-owned L7 editing and save-integrity batch under `android/**`.

This batch did not edit `ios/**`, `Docs/Stage1_Mobile_Blueprint.md`, `Docs/todos_20260505.md`, or `.cron/**`.

## Blueprint Items Advanced

- L7: Implement full source editor on Android.
- L7: Track dirty state consistently.
- L7: Preserve dirty buffer on app background.
- L7: Detect UTF-8 BOM and avoid duplicate BOM on save.
- L7: Preserve CRLF/LF line endings where possible.
- L7: Build complete output before writing to destination.
- L7: Keep dirty buffer intact after failed save.

## Changed Files

- `android/core/src/main/java/com/fastmd/mobile/core/document/MarkdownLoadResult.kt`
- `android/core/src/main/java/com/fastmd/mobile/core/reader/ReaderUiState.kt`
- `android/app/src/main/java/com/fastmd/mobile/document/AndroidDocumentEntry.kt`
- `android/app/src/main/java/com/fastmd/mobile/MainActivity.kt`
- `android/app/src/main/java/com/fastmd/mobile/session/FastMdReaderSessionViewModel.kt`
- `android/app/src/main/java/com/fastmd/mobile/recent/AndroidRecentDocumentStore.kt`
- `android/feature/reader/src/main/java/com/fastmd/mobile/feature/reader/ReaderScreen.kt`
- `android/docs/reports/stage1-android-l7-source-editor-save-20260505.md`

## Implementation Notes

- Added `MarkdownSaveResult` to the core document contract so Android save calls can return either updated document metadata or a typed failure without dropping the active draft.
- Added Android same-document save support in `AndroidMarkdownDocumentLoader.save`.
- Builds the full UTF-8 output byte array before opening the destination writer.
- Writes Android `content://` destinations through `ContentResolver.openOutputStream(uri, "wt")`.
- Keeps non app-owned `file://` documents read-only and allows only app-owned `file://` save paths.
- Preserves original UTF-8 BOM posture by stripping any editor-entered leading BOM before encoding and adding exactly one BOM only when the loaded metadata was `Utf8Bom`.
- Preserves CRLF or LF line endings when the loaded metadata identified a stable line-ending style; mixed or unknown input is left unchanged.
- Stores active Android document handle and metadata in `FastMdReaderSessionViewModel`, alongside the source edit draft, so the dirty buffer survives rotation and ordinary app background/foreground transitions while the process remains alive.
- Added a native Compose source editor using `TextField`, font-tier-aware monospace text, dirty/read-only/save-error state, Save and Cancel actions, and a dirty-discard confirmation dialog for Back/Cancel.
- On save success, reparses the saved source on `Dispatchers.Default`, updates active metadata, refreshes recents without storing document content, and returns to reader state.
- On save failure, restores `ReaderUiState.EditingSource` with the original dirty draft and an error message instead of replacing it with an error screen.
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
| `perl -ne 'print "$ARGV:$.:$_" if /[^\x00-\x7F]/' <touched Kotlin files>` | PASS | No non-ASCII characters were reported in touched Kotlin files. |
| `rg -n "ReactNative\|Flutter\|Cordova\|WebView\|INTERNET\|MANAGE_EXTERNAL_STORAGE\|READ_EXTERNAL_STORAGE\|READ_MEDIA_\|POST_NOTIFICATIONS\|https://\|http://" android/app/src/main android/core/src/main android/feature -S` | PASS | Matches were limited to Android XML namespace declarations in manifest/vector resources and existing remote-image classification strings; no broad storage, notification, network permission, WebView usage, or remote renderer dependency was found. |

## Current Blockers

- Android SDK is still not configured through `ANDROID_HOME` or `android/local.properties`, so Android compile, lint, assemble, unit test, and device validation tasks cannot run.
- No checked-in Android Gradle wrapper exists under `android/`, so required wrapper-based validation remains blocked.
- The shell `java -version` cannot locate a Java runtime, while global Gradle can still run `gradle projects` through its own configured runtime.
- Full external mutation conflict detection remains open. This batch does not claim the external mutation or blind-overwrite L7 checklist items.
- Process death recovery remains open. This batch preserves drafts through rotation and normal backgrounding via the ViewModel, but does not add durable draft recovery after OS process death.

## Supervisor Reconciliation Notes

The supervisor can mark these Android-lane items complete based on the implementation files and validation evidence above, subject to rerunning compile/device gates once Android SDK/JDK 17 are configured:

- Implement full source editor on Android.
- Track dirty state consistently.
- Preserve dirty buffer on app background.
- Detect UTF-8 BOM and avoid duplicate BOM on save.
- Preserve CRLF/LF line endings where possible.
- Build complete output before writing to destination.
- Keep dirty buffer intact after failed save.

Keep remaining L7 external mutation, block editor, unsupported legacy encoding, process death recovery, and platform validation items open.
