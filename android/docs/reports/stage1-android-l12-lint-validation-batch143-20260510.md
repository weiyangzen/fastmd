# Stage 1 Android L12 Lint Validation Batch 143 - 2026-05-10

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
validation item in `Docs/Stage1_Mobile_Blueprint.md` and
`Docs/todos_20260506.md`:

- Run Android `./gradlew lint`.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android product source changes were required. The only intentional repository
write in this batch is this Android-local evidence report.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-lint-validation-batch143-20260510.md`

Gradle also refreshed generated Android-local build metadata and lint reports
under ignored `build/` directories while running validation tasks.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-10.

- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Android SDK path from `local.properties`:
  `/Users/wangweiyang/Library/Android/sdk`.
- Default shell Java: blocked.
- Explicit JDK used for the canonical successful wrapper validation:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
- Explicit Java version:
  `openjdk version "17.0.17" 2025-10-21`.
- Secondary host JBR also available:
  `/Applications/Android Studio.app/Contents/jbr/Contents/Home`, OpenJDK
  `21.0.6`.

The default shell still does not expose Java:

```text
java -version
The operation couldn't be completed. Unable to locate a Java Runtime.
Please visit http://www.java.com for information on installing Java.
```

The checked-in Gradle wrapper works when `JAVA_HOME` is set to the explicit
Homebrew OpenJDK 17 path above.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version && ./gradlew projects` | BLOCKED | macOS reported `Unable to locate a Java Runtime` before Gradle could start. |
| `JAVA_HOME="/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home" java -version` | PASS | Reported Homebrew OpenJDK `17.0.17`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" java -version` | PASS | Reported OpenJDK `21.0.6` from Android Studio JBR. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew projects --console=plain --no-daemon` | PASS | Project graph listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; Gradle reported `BUILD SUCCESSFUL in 3s`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew lint` | PASS | Secondary JBR validation passed; Gradle reported `BUILD SUCCESSFUL in 36s`; `201 actionable tasks: 35 executed, 166 up-to-date`. |
| `JAVA_HOME="/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home" ./gradlew lint --console=plain --no-daemon` | PASS | Canonical JDK 17 validation passed; Gradle reported `BUILD SUCCESSFUL in 1m 37s`; `201 actionable tasks: 35 executed, 166 up-to-date`. |

Gradle printed its standard deprecation warning:

```text
Deprecated Gradle features were used in this build, making it incompatible with Gradle 10.
```

This warning did not fail the validation command in this batch.

## Gradle Project Graph

`./gradlew projects` listed the expected Android project graph:

- `:app`
- `:core`
- `:feature:library`
- `:feature:reader`
- `:feature:settings`

## Lint Coverage

The successful root `./gradlew lint` run covered the Android Stage 1 module
graph:

- `:app:lint`
- `:core:lint`
- `:feature:library:lint`
- `:feature:reader:lint`
- `:feature:settings:lint`

Representative generated Android-local lint artifacts:

- `android/app/build/reports/lint-results-debug.html`
- `android/core/build/reports/lint-results-debug.html`
- `android/feature/library/build/reports/lint-results-debug.html`
- `android/feature/reader/build/reports/lint-results-debug.html`
- `android/feature/settings/build/reports/lint-results-debug.html`

## Remaining Open Items

This batch did not attempt later L12 validation items. Keep these items open
unless covered by a separate report:

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
marking this Android L12 checklist item complete:

- Run Android `./gradlew lint`.

Use this report as minimum Android validation sanity evidence for:

- `./gradlew projects`.
