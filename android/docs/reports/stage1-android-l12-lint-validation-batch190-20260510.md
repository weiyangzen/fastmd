# Stage 1 Android L12 Lint Validation Batch 190 - 2026-05-10

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
platform validation item:

- Run Android `./gradlew lint`.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android product source changes were required. The only intentional repository
write in this batch is this Android-local evidence report.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-lint-validation-batch190-20260510.md`

Gradle also refreshed ignored Android-local generated outputs under module
`build/` directories while running validation.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-10 12:13 CST.

- Gradle entry point: checked-in wrapper `./gradlew`.
- Android SDK path from `local.properties`:
  `/Users/wangweiyang/Library/Android/sdk`.
- Default shell Java discovery: blocked by macOS Java registration.
- Android Studio bundled JBR:
  `/Applications/Android Studio.app/Contents/jbr/Contents/Home`, Java `21.0.6`.
- Passing scoped JDK:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
- Maven resolution used the repository-local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `./gradlew projects` | BLOCKED | Default shell Java discovery failed before Gradle startup with `Unable to locate a Java Runtime`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew projects` | BLOCKED | Java startup succeeded, but Google Maven artifact resolution timed out against `https://dl.google.com/dl/android/maven2/...`; first observed blocker was `com.android.tools.build:gradle:8.13.2`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew lint` | BLOCKED | Same Google Maven classpath resolution blocker; first observed blocker was `com.android.application:com.android.application.gradle.plugin:8.13.2` from `dl.google.com`. |
| `JAVA_HOME="/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home" PATH=".../bin:$PATH" ANDROID_HOME="$HOME/Library/Android/sdk" ANDROID_SDK_ROOT="$HOME/Library/Android/sdk" ./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true lint` | PASS | Gradle reported `BUILD SUCCESSFUL in 2m 20s`; `201 actionable tasks: 35 executed, 166 up-to-date`. |

Gradle printed its standard non-failing deprecation warning in the passing run:

```text
Deprecated Gradle features were used in this build, making it incompatible with Gradle 10.
```

## Lint Coverage

The successful root `lint` run covered the Android Stage 1 module graph:

- `:app:lint`
- `:core:lint`
- `:feature:library:lint`
- `:feature:reader:lint`
- `:feature:settings:lint`

Generated Android-local lint artifacts present after this batch:

- `android/app/build/reports/lint-results-debug.html` (`143934` bytes)
- `android/core/build/reports/lint-results-debug.html` (`64829` bytes)
- `android/feature/reader/build/reports/lint-results-debug.html` (`96184` bytes)
- `android/feature/library/build/reports/lint-results-debug.html` (`85026` bytes)
- `android/feature/settings/build/reports/lint-results-debug.html` (`85027` bytes)
- `android/build/reports/problems/problems-report.html` (`139831` bytes)

## Remaining Open Items

This batch intentionally stopped after the earliest open host lint validation
item. Keep these L12 items open unless covered by separate Android-local
evidence:

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
marking this L12 Android checklist item complete if it is not already
reconciled:

- Run Android `./gradlew lint`.

Do not use this report to newly claim completion for build, unit-test,
assemble, connected-device, API 27 runtime, low-memory/small-screen runtime,
modern-device runtime, or Android performance report items.
