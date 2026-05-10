# Stage 1 Android L6 Session Navigation Test Batch - 2026-05-05

## Scope

Ran one bounded Android-owned implementation batch for the earliest still-open Android L6 reader UX items.

This batch stayed under `android/**`. It did not edit `ios/**`, `Docs/Stage1_Mobile_Blueprint.md`, `Docs/todos_20260505.md`, or `.cron/**`.

## Blueprint Items Advanced

- L6: Implement Back/navigation behavior for search, block edit, source edit, reader, and recent documents.
- L6: Preserve active document, scroll, font tier, search query, and dirty edit buffer through rotation.
- L7: Track dirty state consistently.

## Changed Files

- `android/app/src/test/java/com/fastmd/mobile/session/FastMdReaderSessionViewModelTest.kt`
- `android/docs/reports/stage1-android-l6-session-navigation-tests-20260505.md`

## Implementation Notes

- Added JVM unit coverage for `FastMdReaderSessionViewModel`, the Android session owner used by the Compose app shell.
- Covered Back/navigation behavior:
  - Back from `Searching` restores the underlying `Ready` reader.
  - Back from `Ready` returns to `Empty`, which is the recent-document surface.
  - Back from `Empty` returns `false`, allowing system Back to proceed.
  - Back from dirty source edit keeps the draft buffer and opens the discard-confirmation state.
  - Dirty block edit discard returns to reader state and clears the confirmation state.
- Covered rotation-critical retained state:
  - Search query, active result index, result count, font tier, and tracked visible block remain in the ViewModel-owned state.
  - Dirty source draft state remains in the ViewModel-owned state while the discard dialog is shown.
- Covered dirty-state consistency for source editor drafts:
  - Editing away from the loaded source marks the state dirty.
  - Reverting to the original source clears the dirty flag.
- No native behavior outside the test surface was changed in this batch.
- No React Native, Flutter, Cordova, WebView shell, JavaScript renderer, CDN/network renderer, broad storage permission, notification permission, or Internet permission was introduced.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `gradle :app:testDebugUnitTest --tests com.fastmd.mobile.session.FastMdReaderSessionViewModelTest` | BLOCKED | Android SDK location is not configured: `SDK location not found. Define a valid SDK location with an ANDROID_HOME environment variable or by setting the sdk.dir path in your project's local properties file at '/Users/wangweiyang/GitHub/fastmd/android/local.properties'.` |
| `gradle projects` | PASS | Build succeeded and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `git diff --check -- android` | PASS | No whitespace errors were reported for Android diffs. |
| `perl -ne 'print "$ARGV:$.: trailing whitespace\n" if /[ \t]$/' android/app/src/test/java/com/fastmd/mobile/session/FastMdReaderSessionViewModelTest.kt` | PASS | No trailing whitespace was reported in the new Kotlin test file. |
| `perl -ne 'print "$ARGV:$.:$_" if /[^\x00-\x7F]/' android/app/src/test/java/com/fastmd/mobile/session/FastMdReaderSessionViewModelTest.kt` | PASS | No non-ASCII characters were reported in the new Kotlin test file. |
| `test -x ./gradlew && ./gradlew projects || printf 'gradlew missing or not executable\n'` | BLOCKED | No checked-in Android Gradle wrapper exists under `android/`: `gradlew missing or not executable`. |
| `java -version` | BLOCKED | `/usr/bin/java` reported: `Unable to locate a Java Runtime.` |
| `rg -n "<uses-permission\|WebView\|INTERNET\|MANAGE_EXTERNAL_STORAGE\|READ_EXTERNAL_STORAGE\|READ_MEDIA_\|POST_NOTIFICATIONS\|android:allowBackup=\"true\"\|https://\|http://" android/app/src/main android/core/src/main android/feature -S` | PASS | Matches were limited to Android XML namespace declarations and the parser's remote-image classification strings; no broad storage, notification, Internet permission, WebView usage, backup-enabled posture, or remote renderer dependency was found. |

## Current Blockers

- Android SDK remains unavailable to Gradle because neither `ANDROID_HOME` nor `android/local.properties` with `sdk.dir` is configured.
- The checked-in Android Gradle wrapper is still absent under `android/`.
- `/usr/bin/java` still cannot locate a system Java runtime, although the installed `gradle` command can run `gradle projects` through its own runtime path.
- Because `:app:testDebugUnitTest` cannot resolve the Android SDK, the new JVM test file has not executed locally in this environment.

## Supervisor Reconciliation Notes

The supervisor can use this report plus `android/docs/reports/stage1-android-l6-navigation-rotation-20260505.md` as Android-lane evidence that the L6 navigation and rotation-state implementation now has focused test coverage. Final checklist reconciliation should still rerun `:app:testDebugUnitTest` after Android SDK/JDK/wrapper setup is repaired.

Items that can be considered Android-implemented, with validation limited by the recorded SDK blocker:

- L6: Implement Back/navigation behavior for search, block edit, source edit, reader, and recent documents.
- L6: Preserve active document, scroll, font tier, search query, and dirty edit buffer through rotation.
- L7: Track dirty state consistently.

Keep L11 and L12 execution gates open until Android SDK/JDK/wrapper setup allows unit test, compile, lint, assemble, and device validation tasks to run.
