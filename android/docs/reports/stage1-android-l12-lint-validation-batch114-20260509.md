# Stage 1 Android L12 Lint Validation Batch 114 - 2026-05-09

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
platform validation item:

- Run Android `./gradlew lint`.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android product source changes were made.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-lint-validation-batch114-20260509.md`

## Environment

Command was run from `/Users/wangweiyang/GitHub/fastmd/android` on 2026-05-09.

- Gradle entry point: checked-in wrapper `./gradlew`.
- Explicit JDK:
  `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`.
- Android SDK path:
  `/Users/wangweiyang/Library/Android/sdk`.
- Maven resolution used local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true lint --stacktrace` | PASS | Lint completed for `app`, `core`, `feature:library`, `feature:reader`, and `feature:settings`; Gradle reported `BUILD SUCCESSFUL in 21s`. |

## Android-Local Lint Report Artifacts

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

## Notes

Gradle printed its standard deprecation warning:

- Deprecated Gradle features were used in this build, making it incompatible
  with Gradle 10.

This warning did not fail the lint gate.

## Supervisor Checklist Recommendation

The supervising session can use this Android-local report as evidence for
marking this L12 checklist item complete:

- Run Android `./gradlew lint`.
