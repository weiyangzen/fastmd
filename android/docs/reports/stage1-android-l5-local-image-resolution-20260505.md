# Stage 1 Android L5 Local Image Resolution Report - 2026-05-05

## Scope

Implemented one bounded Android-owned L5 local image rendering batch under `android/**`.

This batch did not edit `ios/**`, `Docs/Stage1_Mobile_Blueprint.md`, `Docs/todos_20260505.md`, or `.cron/**`.

## Blueprint Items Advanced

- L5: Render local images with bounded decode.
- L8: Decode Android local images with bounded sampling.

## Changed Files

- `android/app/src/main/java/com/fastmd/mobile/MainActivity.kt`
- `android/core/src/main/java/com/fastmd/mobile/core/markdown/StructuredMarkdownParser.kt`
- `android/core/src/test/java/com/fastmd/mobile/core/markdown/StructuredMarkdownParserTest.kt`
- `android/feature/reader/src/main/java/com/fastmd/mobile/feature/reader/ReaderScreen.kt`
- `android/docs/reports/stage1-android-l5-local-image-resolution-20260505.md`

## Implementation Notes

- Added optional `documentBaseUri` metadata to parsed image blocks when the Android load path has an actual document handle.
- Android reader rendering now resolves explicit local image sources before bounded bitmap decode:
  - direct `content://` image sources use `ContentResolver.openInputStream`;
  - direct `file://` image sources use platform URI streams;
  - absolute filesystem paths use direct file streams;
  - relative `./`, `../`, and bare relative paths resolve only against a local `file://` or absolute-path document base.
- SAF `content://` document bases deliberately do not imply sibling-image access. A single document grant is not treated as directory access; unresolved relative image references remain readable placeholders.
- Existing bounded decode behavior is preserved: image bounds are read first with `BitmapFactory.Options.inJustDecodeBounds`, then decoded with `inSampleSize` capped to a `2048px` max dimension.
- Remote images are still never fetched automatically and remain manual-open placeholders.
- Added parser contract test coverage proving local image blocks carry the document base while remote image blocks remain classified as remote.
- No React Native, Flutter, Cordova, remote WebView shell, WebView renderer, JavaScript renderer, CDN asset, network permission, or broad storage permission was introduced.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `gradle projects` | PASS | Build succeeded and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `gradle :core:testDebugUnitTest` | BLOCKED | Android SDK location is not configured: `SDK location not found. Define a valid SDK location with an ANDROID_HOME environment variable or by setting the sdk.dir path in your project's local properties file at '/Users/wangweiyang/GitHub/fastmd/android/local.properties'.` |
| `gradle :feature:reader:compileDebugKotlin` | BLOCKED | Android SDK location is not configured: `SDK location not found. Define a valid SDK location with an ANDROID_HOME environment variable or by setting the sdk.dir path in your project's local properties file at '/Users/wangweiyang/GitHub/fastmd/android/local.properties'.` |
| `java -version` | BLOCKED | `/usr/bin/java` reported: `Unable to locate a Java Runtime.` |
| `test -x ./gradlew && ./gradlew projects \|\| printf 'gradlew missing or not executable\n'` | BLOCKED | No checked-in Android Gradle wrapper exists under `android/`: `gradlew missing or not executable`. |
| `find android -path 'android/.gradle' -prune -o -path 'android/build' -prune -o -type f -print0 \| xargs -0 perl -ne 'if(/[ \t]$/){print "$ARGV:$.: trailing whitespace\n"; $bad=1} END{exit($bad ? 1 : 0)}'` | PASS | No trailing whitespace found in Android files outside local Gradle/build output. |
| `git diff --check -- android` | PASS | No whitespace errors were reported for tracked Android diffs. The Android tree is currently untracked in this workspace, so direct diff output is not available until it is added to Git. |
| `rg -n "<uses-permission\|WebView\|INTERNET\|MANAGE_EXTERNAL_STORAGE\|READ_EXTERNAL_STORAGE\|READ_MEDIA_\|POST_NOTIFICATIONS\|android:allowBackup=\"true\"\|https://\|http://" android/app/src/main android/core/src/main android/feature -S` | PASS | Matches were limited to Android XML namespace declarations in manifest/vector resources and the parser's remote-image classification strings; no broad storage, notification, network permission, WebView usage, backup-enabled posture, or remote renderer dependency was found. |

## Current Blockers

- Android SDK is still not configured through `ANDROID_HOME` or `android/local.properties`, so Android compile, unit test, lint, assemble, and device validation tasks cannot run.
- No checked-in Android Gradle wrapper exists under `android/`, so required wrapper-based validation remains blocked.
- The shell `java -version` cannot locate a Java runtime, while global Gradle can still run `gradle projects` through its own configured runtime.

## Supervisor Reconciliation Notes

The supervisor can mark these Android items complete for the Android lane based on implementation files and validation evidence above, subject to rerunning compile/test gates once Android SDK/JDK 17 are configured:

- L5: Render local images with bounded decode.
- L8: Decode Android local images with bounded sampling.

Keep L11 and L12 validation checklist items open because compile, unit test, lint, assemble, and device validation remain blocked by local SDK/JDK/wrapper setup.
