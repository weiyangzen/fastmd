# Stage 1 Android L12 Build Validation Batch 119 - 2026-05-09

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
host validation cluster from `Docs/todos_20260506.md`:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android product source changes were made. The only repository write in this
batch is this Android-local evidence report.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-build-validation-batch119-20260509.md`

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-09.

- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Android SDK path from `local.properties`:
  `/Users/wangweiyang/Library/Android/sdk`.
- Explicit JDK used for passing Gradle commands:
  `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`.
- Explicit Java version:
  `openjdk version "17.0.17" 2025-10-21`.
- Maven resolution used local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.

The default shell `PATH` still does not expose a Java runtime:

- `java -version` failed with `Unable to locate a Java Runtime`.
- `/usr/libexec/java_home -V` failed with `Unable to locate a Java Runtime`.

The checked-in Gradle wrapper works when `JAVA_HOME` is set to the explicit
Homebrew OpenJDK 17 path above.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported Homebrew OpenJDK `17.0.17`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true projects` | PASS | Listed expected project graph; Gradle reported `BUILD SUCCESSFUL in 20s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true build` | PASS | Full Android build completed; Gradle reported `BUILD SUCCESSFUL in 3m 31s` with `474 actionable tasks: 39 executed, 435 up-to-date`. |
| `/Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices -l` | BLOCKED for device work | Printed `List of devices attached` with no attached device rows. |
| `/Users/wangweiyang/Library/Android/sdk/emulator/emulator -list-avds` | PASS | Listed one AVD: `Medium_Phone`. |
| `find /Users/wangweiyang/Library/Android/sdk/platforms -maxdepth 1 -type d -name 'android-*'` | PASS | Installed SDK platforms include `android-35`, matching the Stage 1 `compileSdk = 35` requirement. |

## Gradle Project Graph

`./gradlew projects` listed the expected Android project graph:

- `:app`
- `:core`
- `:feature:library`
- `:feature:reader`
- `:feature:settings`

## Build Coverage

The successful `./gradlew build` run included these L12-relevant task surfaces:

- `:app:assembleDebug`
- `:app:lint`
- `:core:lint`
- `:feature:library:lint`
- `:feature:reader:lint`
- `:feature:settings:lint`
- `:core:testDebugUnitTest`
- `:feature:reader:testDebugUnitTest`
- `:app:testDebugUnitTest`
- `:app:assembleRelease`
- `:core:build`
- `:feature:library:build`
- `:feature:reader:build`
- `:feature:settings:build`
- `:app:build`

The build also reran Android-local renderer/security Gradle gates, including:

- `auditRendererAssets`
- `auditRendererRequestBlocking`
- `testRendererAssetAudit`
- `testRendererRequestBlockingAudit`
- `stage1AndroidRendererAssetGates`

Representative gate output:

- `PASS: No Android WebView or android.webkit implementation is present.`
- `PASS: No React Native, Flutter, Cordova, or equivalent web runtime dependency is present.`
- `PASS: Renderer request policy is a first-class Android core contract.`
- `PASS: native fallback request policy and tests satisfy the gate.`

Gradle printed its standard deprecation warning:

- Deprecated Gradle features were used in this build, making it incompatible
  with Gradle 10.

This warning did not fail the validation command.

## Android-Local Evidence Artifacts

Relevant Android-local artifacts after this batch:

- `android/app/build/reports/lint-results-debug.html`
- `android/app/build/reports/lint-results-debug.xml`
- `android/core/build/reports/lint-results-debug.html`
- `android/core/build/reports/lint-results-debug.xml`
- `android/feature/reader/build/reports/lint-results-debug.html`
- `android/feature/reader/build/reports/lint-results-debug.xml`
- `android/feature/library/build/reports/lint-results-debug.html`
- `android/feature/library/build/reports/lint-results-debug.xml`
- `android/feature/settings/build/reports/lint-results-debug.html`
- `android/feature/settings/build/reports/lint-results-debug.xml`
- `android/core/build/test-results/testDebugUnitTest/`
- `android/feature/reader/build/test-results/testDebugUnitTest/`
- `android/app/build/outputs/apk/debug/app-debug.apk`
- `android/build/reports/problems/problems-report.html`

## Remaining Runtime Blockers

Runtime/device validation remains blocked in the current local environment:

- `adb devices -l` lists no attached Android device or booted emulator.
- `emulator -list-avds` lists `Medium_Phone`, but it was not booted during this
  batch.
- The SDK has API 35 platform support installed, but this batch did not run a
  device/emulator session.
- Android API 27, low-memory/small-screen, modern-device runtime validation,
  and `:app:connectedDebugAndroidTest` remain open until a matching attached
  device or booted emulator is available.

## Supervisor Checklist Recommendation

The supervising session can use this report as fresh Android-lane evidence for
marking these Android L12 checklist items complete:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.

Use this report as minimum Android validation sanity evidence for:

- `./gradlew projects`.

Keep these L12 runtime/device items open:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

This batch did not capture a new Android performance report; use the existing
Android-local performance evidence report until a later batch refreshes it.
