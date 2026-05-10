# Stage 1 Android L3 Document Entry Report - 2026-05-05

## Scope

Implemented one bounded Android-owned L3 document entry batch under `android/**`.

This batch did not edit `ios/**`, `Docs/Stage1_Mobile_Blueprint.md`, `Docs/todos_20260505.md`, or `.cron/**`.

## Blueprint Items Advanced

- L3: Implement Android launcher entry.
- L3: Implement Android SAF open through `ACTION_OPEN_DOCUMENT`.
- L3: Implement Android `ACTION_VIEW` for Markdown-like documents.
- L3: Implement Android `ACTION_SEND` for shared text.
- L3: Implement Android `ACTION_SEND` for single document URI.
- L3: Persist Android URI permission only when flags allow.
- L3: Normalize Android `file://` fallback as read-only unless app-owned.

## Changed Files

- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/java/com/fastmd/mobile/MainActivity.kt`
- `android/app/src/main/java/com/fastmd/mobile/document/AndroidDocumentEntry.kt`
- `android/feature/reader/src/main/java/com/fastmd/mobile/feature/reader/ReaderScreen.kt`
- `android/docs/reports/stage1-android-l3-document-entry-20260505.md`

## Implementation Notes

- Added an Android document entry parser for launcher, `ACTION_VIEW`, shared text, and shared URI intents.
- Added a native Kotlin Android document loader that reads through `ContentResolver` streams on `Dispatchers.IO`.
- Added UTF-8/BOM and LF/CRLF/Mixed line-ending detection for loaded documents.
- Document entry loading fails closed for unsupported URI schemes; only `content://` and `file://` document references are accepted.
- Added SAF open through `ActivityResultContracts.OpenDocument`, launched from the reader empty state.
- Routed successful loads into `ReaderUiState.Ready` and failures into structured `ReaderUiState.Error`.
- Persistable URI permission is attempted only for explicit SAF/view URI entry paths that carry or synthesize the read grant; failures remain non-fatal and fall back to transient/read-only handling.
- `file://` entries are normalized into a `DocumentOrigin.FileUriFallback` handle and are read-only unless the canonical file path is app-owned.
- Hardened the manifest with `android:allowBackup="false"` and `singleTop` activity delivery for repeated document opens.
- No React Native, Flutter, Cordova, remote WebView shell, WebView renderer, JS renderer, network permission, or broad storage permission was introduced.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `gradle projects` | PASS | Build succeeded and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `gradle :app:compileDebugKotlin` | BLOCKED | Android SDK location is not configured: `SDK location not found. Define a valid SDK location with an ANDROID_HOME environment variable or by setting the sdk.dir path in your project's local properties file at '/Users/wangweiyang/GitHub/fastmd/android/local.properties'.` |
| `java -version` | BLOCKED | `/usr/bin/java` reported: `Unable to locate a Java Runtime.` |
| `test -x ./gradlew && ./gradlew projects || printf 'gradlew missing or not executable\n'` | BLOCKED | No Gradle wrapper exists under `android/`: `gradlew missing or not executable`. |
| `find android -path 'android/.gradle' -prune -o -path 'android/build' -prune -o -type f -print0 \| xargs -0 perl -ne 'if(/[ \t]$/){print "$ARGV:$.: trailing whitespace\n"; $bad=1} END{exit($bad ? 1 : 0)}'` | PASS | No trailing whitespace found in Android files outside local Gradle/build output. |
| `rg -n "<uses-permission\|INTERNET\|MANAGE_EXTERNAL_STORAGE\|READ_EXTERNAL_STORAGE\|READ_MEDIA_\|POST_NOTIFICATIONS\|WebView\|android:allowBackup=\"true\"\|android:exported=\"true\"" android/app/src/main/AndroidManifest.xml android/app/src/main/java android/feature android/core/src/main -S` | PASS | The only match is the expected launcher/document entry activity export in `AndroidManifest.xml`; no broad storage, notification, network permission, WebView usage, or backup-enabled posture was found. |

## Current Blockers

- Android SDK is still not configured through `ANDROID_HOME` or `android/local.properties`, so Android compile, unit test, lint, and assemble tasks cannot run.
- No checked-in Android Gradle wrapper exists under `android/`, so required wrapper-based validation remains blocked.
- The shell `java -version` cannot locate a Java runtime, while global Gradle can still run `gradle projects` through its own configured runtime.

## Supervisor Reconciliation Notes

The supervisor can mark the listed Android L3 document entry items complete for the Android lane based on implementation files and the validation evidence above, subject to rerunning compile/test gates once Android SDK/JDK 17 are configured.

Keep L12 platform validation items open because compile, lint, unit test, assemble, and device validation remain blocked by local SDK/JDK/wrapper setup.
