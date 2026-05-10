# Stage 1 Android L3 Recents And PermissionLost Report - 2026-05-05

## Scope

Implemented one bounded Android-owned L3 document entry batch under `android/**`.

This batch did not edit `ios/**`, `Docs/Stage1_Mobile_Blueprint.md`, `Docs/todos_20260505.md`, or `.cron/**`.

## Blueprint Items Advanced

- L3: Store Android recent document metadata without storing document content.
- L3: Handle Android stale URI permission with `PermissionLost` state.

## Changed Files

- `android/app/src/main/java/com/fastmd/mobile/MainActivity.kt`
- `android/app/src/main/java/com/fastmd/mobile/document/AndroidDocumentEntry.kt`
- `android/app/src/main/java/com/fastmd/mobile/recent/AndroidRecentDocumentStore.kt`
- `android/core/src/main/java/com/fastmd/mobile/core/document/RecentDocumentMetadata.kt`
- `android/core/src/test/java/com/fastmd/mobile/core/contracts/CoreContractsTest.kt`
- `android/feature/reader/src/main/java/com/fastmd/mobile/feature/reader/ReaderScreen.kt`
- `android/docs/reports/stage1-android-l3-recents-permissionlost-20260505.md`

## Implementation Notes

- Added an Android-side recent document metadata model and DataStore-backed platform store.
- Recent records persist only document handle metadata: handle id, platform reference, display name, permission grant, size, modified time, last-opened time, and write capability.
- Shared text entries are deliberately excluded from recents so shared Markdown body content is not persisted as a recent document.
- The empty reader state now shows stored recent document display names and can reopen a recent handle.
- Reopening a stored content URI uses the saved persisted grant state when present.
- If a stored URI can no longer be read and Android raises `SecurityException`, the load path maps it to `FastMdErrorCode.PermissionLost` and `ReaderUiState.PermissionLost`.
- Recent metadata read/write errors are fail-soft and do not block opening the active document.
- No React Native, Flutter, Cordova, remote WebView shell, WebView renderer, JS renderer, network permission, or broad storage permission was introduced.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `gradle projects` | PASS | Build succeeded and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `gradle :app:compileDebugKotlin` | BLOCKED | Android SDK location is not configured: `SDK location not found. Define a valid SDK location with an ANDROID_HOME environment variable or by setting the sdk.dir path in your project's local properties file at '/Users/wangweiyang/GitHub/fastmd/android/local.properties'.` |
| `gradle :core:testDebugUnitTest` | BLOCKED | Android SDK location is not configured: `SDK location not found. Define a valid SDK location with an ANDROID_HOME environment variable or by setting the sdk.dir path in your project's local properties file at '/Users/wangweiyang/GitHub/fastmd/android/local.properties'.` |
| `java -version` | BLOCKED | `/usr/bin/java` reported: `Unable to locate a Java Runtime.` |
| `test -x ./gradlew && ./gradlew projects || printf 'gradlew missing or not executable\n'` | BLOCKED | No Gradle wrapper exists under `android/`: `gradlew missing or not executable`. |
| `git diff --check -- android` | PASS | No whitespace errors were reported for tracked Android diffs. |
| `find android -path 'android/.gradle' -prune -o -path 'android/build' -prune -o -type f -print0 \| xargs -0 perl -ne 'if(/[ \t]$/){print "$ARGV:$.: trailing whitespace\n"; $bad=1} END{exit($bad ? 1 : 0)}'` | PASS | No trailing whitespace found in Android files outside local Gradle/build output. |
| `rg -n "<uses-permission\|INTERNET\|MANAGE_EXTERNAL_STORAGE\|READ_EXTERNAL_STORAGE\|READ_MEDIA_\|POST_NOTIFICATIONS\|WebView\|android:allowBackup=\"true\"\|android:exported=\"true\"" android/app/src/main/AndroidManifest.xml android/app/src/main/java android/feature android/core/src/main -S` | PASS | The only match is the expected launcher/document entry activity export in `AndroidManifest.xml`; no broad storage, notification, network permission, WebView usage, or backup-enabled posture was found. |

## Current Blockers

- Android SDK is still not configured through `ANDROID_HOME` or `android/local.properties`, so Android compile, unit test, lint, and assemble tasks cannot run.
- No checked-in Android Gradle wrapper exists under `android/`, so required wrapper-based validation remains blocked.
- The shell `java -version` cannot locate a Java runtime, while global Gradle can still run `gradle projects` through its own configured runtime.

## Supervisor Reconciliation Notes

The supervisor can mark these Android L3 items complete for the Android lane based on implementation files and the validation evidence above:

- Store Android recent document metadata without storing document content.
- Handle Android stale URI permission with `PermissionLost` state.

Keep L12 platform validation items open because compile, lint, unit test, assemble, and device validation remain blocked by local SDK/JDK/wrapper setup.
