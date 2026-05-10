# Stage 1 Android L7 External Mutation Save Report - 2026-05-05

## Scope

Implemented one bounded Android-owned L7 save-integrity batch under `android/**`.

This batch did not edit `ios/**`, `Docs/Stage1_Mobile_Blueprint.md`, `Docs/todos_20260505.md`, or `.cron/**`.

## Blueprint Items Advanced

- L7: Fail read-only on unsupported legacy encoding instead of corrupting saves.
- L7: Detect external document mutation before save.
- L7: Block blind overwrite after external mutation.
- L7: Keep dirty buffer intact after failed save.

## Changed Files

- `android/app/src/main/java/com/fastmd/mobile/document/AndroidDocumentEntry.kt`
- `android/app/src/main/java/com/fastmd/mobile/MainActivity.kt`
- `android/docs/reports/stage1-android-l7-external-mutation-save-20260505.md`

## Implementation Notes

- Extended the Android save contract to pass the original loaded source into `AndroidMarkdownDocumentLoader.save`.
- Before opening the writable output stream, Android now rereads the active `content://` or app-owned `file://` backing document and decodes it as UTF-8 using the same strict decoder used by load.
- If the reread source differs from the original source held by the active editor, save returns `SaveExternalMutationConflict` and does not open the output stream, preventing a blind overwrite.
- If the backing document is no longer valid UTF-8 at save time, save returns `ReadUnsupportedEncoding` and leaves the editor draft unsaved rather than transcoding or corrupting the destination.
- Source editor and block editor failure paths already restore the dirty draft into their editor state, so the new conflict and encoding failures keep the dirty buffer intact.
- The existing full-output-before-write behavior is preserved: normalized draft bytes are built before the reread/conflict check and before any destination stream is opened.
- No React Native, Flutter, Cordova, remote WebView shell, WebView renderer, JavaScript renderer, CDN asset, network permission, or broad storage permission was introduced.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `gradle projects` | PASS | Build succeeded and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `gradle :app:compileDebugKotlin` | BLOCKED | Android SDK location is not configured: `SDK location not found. Define a valid SDK location with an ANDROID_HOME environment variable or by setting the sdk.dir path in your project's local properties file at '/Users/wangweiyang/GitHub/fastmd/android/local.properties'.` |
| `gradle :core:testDebugUnitTest` | BLOCKED | Android SDK location is not configured: `SDK location not found. Define a valid SDK location with an ANDROID_HOME environment variable or by setting the sdk.dir path in your project's local properties file at '/Users/wangweiyang/GitHub/fastmd/android/local.properties'.` |
| `java -version` | BLOCKED | `/usr/bin/java` reported: `Unable to locate a Java Runtime.` |
| `test -x ./gradlew && ./gradlew projects || printf 'gradlew missing or not executable\n'` | BLOCKED | No checked-in Android Gradle wrapper exists under `android/`: `gradlew missing or not executable`. |
| `git diff --check -- android/app/src/main/java/com/fastmd/mobile/document/AndroidDocumentEntry.kt android/app/src/main/java/com/fastmd/mobile/MainActivity.kt` | PASS | No whitespace errors were reported for this batch's tracked Android diffs. |
| `perl -ne 'if(/[ \t]$/){print "$ARGV:$.: trailing whitespace\n"; $bad=1} END{exit($bad ? 1 : 0)}' <touched Kotlin files>` | PASS | No trailing whitespace found in this batch's touched Kotlin files. |
| `perl -ne 'print "$ARGV:$.:$_" if /[^\x00-\x7F]/' <touched Kotlin files>` | PASS | No non-ASCII characters were reported in this batch's touched Kotlin files. |

## Current Blockers

- Android SDK is still not configured through `ANDROID_HOME` or `android/local.properties`, so Android compile, lint, assemble, unit test, and device validation tasks cannot run.
- No checked-in Android Gradle wrapper exists under `android/`, so required wrapper-based validation remains blocked.
- The shell `java -version` cannot locate a Java runtime, while global Gradle can still run `gradle projects` through its own configured runtime.
- Process death recovery remains open.

## Supervisor Reconciliation Notes

The supervisor can mark these Android-lane items complete based on the implementation files and validation evidence above, subject to rerunning compile/device gates once Android SDK/JDK 17 are configured:

- Detect external document mutation before save.
- Block blind overwrite after external mutation.
- Fail read-only on unsupported legacy encoding instead of corrupting saves.

`Keep dirty buffer intact after failed save` was already implemented by the source/block editor batches and is additionally exercised by the new failure results in this batch.

Keep L7 process death recovery and L11/L12 validation checklist items open because compile, unit test, lint, assemble, wrapper-based, and device validation remain blocked by local SDK/JDK/wrapper setup.
