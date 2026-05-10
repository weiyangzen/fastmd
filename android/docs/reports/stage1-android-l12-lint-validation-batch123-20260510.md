# Stage 1 Android L12 Lint Validation Batch 123 - 2026-05-10

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
validation item from `Docs/todos_20260506.md` and
`Docs/Stage1_Mobile_Blueprint.md`:

- Run Android `./gradlew lint`.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android product source changes were made. The only repository write in this
batch is this Android-local evidence report.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-lint-validation-batch123-20260510.md`

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-10.

- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Android SDK path:
  `/Users/wangweiyang/Library/Android/sdk`.
- Explicit JDK used for passing Gradle commands:
  `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`.
- Explicit Java version:
  `openjdk version "17.0.17" 2025-10-21`.
- Maven resolution used local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.

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
| `java -version` | BLOCKED for default shell | macOS reported `Unable to locate a Java Runtime`. |
| `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported Homebrew OpenJDK `17.0.17`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true lint` | PASS | Gradle reported `BUILD SUCCESSFUL in 19s`; `201 actionable tasks: 10 executed, 191 up-to-date`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true projects` | PASS | Project graph listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; Gradle reported `BUILD SUCCESSFUL in 12s`. |

Gradle printed its standard deprecation warning:

```text
Deprecated Gradle features were used in this build, making it incompatible with Gradle 10.
```

This warning did not fail the lint or project graph validation commands.

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
- `android/app/build/reports/lint-results-debug.xml`
- `android/core/build/reports/lint-results-debug.html`
- `android/core/build/reports/lint-results-debug.xml`
- `android/feature/library/build/reports/lint-results-debug.html`
- `android/feature/library/build/reports/lint-results-debug.xml`
- `android/feature/reader/build/reports/lint-results-debug.html`
- `android/feature/reader/build/reports/lint-results-debug.xml`
- `android/feature/settings/build/reports/lint-results-debug.html`
- `android/feature/settings/build/reports/lint-results-debug.xml`
- `android/build/reports/problems/problems-report.html`

## Gradle Project Graph

`./gradlew projects` listed the expected Android project graph:

- `:app`
- `:core`
- `:feature:library`
- `:feature:reader`
- `:feature:settings`

## Supervisor Checklist Recommendation

The supervising session can use this report as fresh Android-lane evidence for
marking this Android L12 checklist item complete:

- Run Android `./gradlew lint`.

Use this report as minimum Android validation sanity evidence for:

- `./gradlew projects`.

Keep the remaining L12 runtime/device items open unless covered by separate
reports:

- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.
- Capture Android performance report.

