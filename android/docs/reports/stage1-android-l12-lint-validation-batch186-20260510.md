# Stage 1 Android L12 Lint Validation Batch 186 - 2026-05-10

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
platform validation item from `Docs/Stage1_Mobile_Blueprint.md` and
`Docs/todos_20260506.md`:

- Run Android `./gradlew lint`.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android product source changes were required. The only intentional repository
write in this batch is this Android-local evidence report.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-lint-validation-batch186-20260510.md`

Gradle also refreshed Android-local generated build metadata and reports under
ignored `build/` directories while running validation.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-10 10:05 CST.

- Gradle entry point: checked-in wrapper `./gradlew`.
- Android SDK path from `local.properties`:
  `/Users/wangweiyang/Library/Android/sdk`.
- Default shell Java: blocked by macOS Java registration.
- Explicit JDK used for passing validation:
  `/Applications/Android Studio.app/Contents/jbr/Contents/Home`.
- Explicit Java version:
  `openjdk version "21.0.6" 2025-01-21`.

The default shell still does not expose Java:

```text
./gradlew lint
The operation couldn't be completed. Unable to locate a Java Runtime.
Please visit http://www.java.com for information on installing Java.
```

The checked-in Gradle wrapper works when `JAVA_HOME` is scoped to the Android
Studio bundled JBR.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `./gradlew lint` | BLOCKED | macOS reported `Unable to locate a Java Runtime` before Gradle could start. |
| `"/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/java" -version` | PASS | Reported OpenJDK `21.0.6`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew lint` | PASS | Gradle reported `BUILD SUCCESSFUL in 37s`; `201 actionable tasks: 35 executed, 166 up-to-date`. |

Gradle printed its standard non-failing deprecation warning:

```text
Deprecated Gradle features were used in this build, making it incompatible with Gradle 10.
```

## Lint Coverage

The successful root `./gradlew lint` run covered the Android Stage 1 module
graph:

- `:app:lint`
- `:core:lint`
- `:feature:library:lint`
- `:feature:reader:lint`
- `:feature:settings:lint`

Generated Android-local lint summaries after this batch:

| Module | Text Report | Summary |
| --- | --- | --- |
| `:app` | `android/app/build/reports/lint-results-debug.txt` | `0 errors, 25 warnings` |
| `:core` | `android/core/build/reports/lint-results-debug.txt` | `0 errors, 1 warning` |
| `:feature:library` | `android/feature/library/build/reports/lint-results-debug.txt` | `0 errors, 1 warning` |
| `:feature:reader` | `android/feature/reader/build/reports/lint-results-debug.txt` | `0 errors, 4 warnings` |
| `:feature:settings` | `android/feature/settings/build/reports/lint-results-debug.txt` | `0 errors, 1 warning` |

Representative generated Android-local lint artifacts present after this batch:

- `android/app/build/reports/lint-results-debug.html`
- `android/core/build/reports/lint-results-debug.html`
- `android/feature/library/build/reports/lint-results-debug.html`
- `android/feature/reader/build/reports/lint-results-debug.html`
- `android/feature/settings/build/reports/lint-results-debug.html`
- `android/build/reports/problems/problems-report.html`

## Remaining Open Items

This batch intentionally did not attempt later L12 validation items. Keep these
items open unless covered by separate Android-local evidence:

- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.
- Capture Android performance report.

## Supervisor Checklist Recommendation

The supervising session can use this report as fresh Android-lane evidence for
marking this L12 Android checklist item complete if not already reconciled:

- Run Android `./gradlew lint`.

Do not use this report to newly claim completion for build, unit-test,
assemble, connected-device, API 27 runtime, low-memory/small-screen runtime,
modern-device runtime, or Android performance report items.
