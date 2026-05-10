# Stage 1 Android L12 Host Validation Refresh Batch 136 - 2026-05-10

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
host validation cluster from `Docs/Stage1_Mobile_Blueprint.md` and
`Docs/todos_20260506.md`:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android product source changes were made. The only intentional repository
write in this batch is this Android-local evidence report.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-host-validation-refresh-batch136-20260510.md`

Gradle also refreshed generated Android-local build artifacts and reports under
`android/build/`, `android/app/build/`, `android/core/build/`, and
`android/feature/*/build/`.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-10.

- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Android SDK path from `android/local.properties`:
  `/Users/wangweiyang/Library/Android/sdk`.
- Installed Android SDK platforms include `android-35`, matching the Stage 1
  `compileSdk = 35` requirement.
- Explicit JDK used for passing Gradle commands:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
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

Android Studio's bundled JBR is also present and reports OpenJDK `21.0.6`, but
this batch used Homebrew OpenJDK 17 for the Gradle validation commands.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED for default shell | macOS reported `Unable to locate a Java Runtime`. |
| `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported Homebrew OpenJDK `17.0.17`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true projects` | PASS | Project graph listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; Gradle reported `BUILD SUCCESSFUL in 13s`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true lint` | PASS | Root lint completed; Gradle reported `BUILD SUCCESSFUL in 1m 32s`; `201 actionable tasks: 30 executed, 171 up-to-date`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true :core:testDebugUnitTest` | PASS | Core debug unit tests completed; Gradle reported `BUILD SUCCESSFUL in 44s`; `17 actionable tasks: 3 executed, 14 up-to-date`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true :feature:reader:testDebugUnitTest` | PASS | Reader debug unit tests completed; Gradle reported `BUILD SUCCESSFUL in 35s`; `29 actionable tasks: 4 executed, 25 up-to-date`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true :app:assembleDebug` | PASS | Debug APK assembly completed; Gradle reported `BUILD SUCCESSFUL in 19s`; `122 actionable tasks: 5 executed, 117 up-to-date`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true build` | PASS | Full Android host build completed; Gradle reported `BUILD SUCCESSFUL in 3m 44s`; `474 actionable tasks: 35 executed, 439 up-to-date`. |

Gradle printed its standard deprecation warning:

```text
Deprecated Gradle features were used in this build, making it incompatible with Gradle 10.
```

The explicit `:feature:reader:testDebugUnitTest` command also printed:

```text
w: Detected multiple Kotlin daemon sessions at kotlin/sessions
```

Neither warning failed validation.

## Gradle Project Graph

`./gradlew projects` listed the expected Android project graph:

- `:app`
- `:core`
- `:feature:library`
- `:feature:reader`
- `:feature:settings`

## Host Gate Coverage

The passing root `./gradlew lint` run covered:

- `:app:lint`
- `:core:lint`
- `:feature:library:lint`
- `:feature:reader:lint`
- `:feature:settings:lint`

The explicit unit-test commands covered:

- `:core:testDebugUnitTest`
- `:feature:reader:testDebugUnitTest`

The explicit debug assembly command covered:

- `:app:assembleDebug`

The passing root `./gradlew build` run covered debug and release assembly,
debug and release unit-test tasks, lint tasks, and Stage 1 renderer/security
gates, including:

- `auditRendererAssets`
- `auditRendererRequestBlocking`
- `testRendererAssetAudit`
- `testRendererRequestBlockingAudit`
- `stage1AndroidRendererAssetGates`

Representative renderer/security gate output from this batch:

- `PASS: No Android WebView or android.webkit implementation is present.`
- `PASS: No React Native, Flutter, Cordova, or equivalent web runtime dependency is present.`
- `PASS: No vendored JS/CSS/font renderer asset tree is present; Android rich blocks use native fallback paths.`
- `PASS: Renderer request policy is a first-class Android core contract.`
- `PASS: native fallback request policy and tests satisfy the gate.`

## Android-Local Evidence Artifacts

Representative lint reports present after this batch:

- `android/app/build/reports/lint-results-debug.html`
- `android/app/build/reports/lint-results-debug.txt`
- `android/app/build/reports/lint-results-debug.xml`
- `android/core/build/reports/lint-results-debug.html`
- `android/core/build/reports/lint-results-debug.txt`
- `android/core/build/reports/lint-results-debug.xml`
- `android/feature/library/build/reports/lint-results-debug.html`
- `android/feature/library/build/reports/lint-results-debug.txt`
- `android/feature/library/build/reports/lint-results-debug.xml`
- `android/feature/reader/build/reports/lint-results-debug.html`
- `android/feature/reader/build/reports/lint-results-debug.txt`
- `android/feature/reader/build/reports/lint-results-debug.xml`
- `android/feature/settings/build/reports/lint-results-debug.html`
- `android/feature/settings/build/reports/lint-results-debug.txt`
- `android/feature/settings/build/reports/lint-results-debug.xml`

Representative unit-test reports present after this batch:

- `android/core/build/reports/tests/testDebugUnitTest/index.html`
- `android/core/build/reports/tests/testReleaseUnitTest/index.html`
- `android/feature/reader/build/reports/tests/testDebugUnitTest/index.html`
- `android/feature/reader/build/reports/tests/testReleaseUnitTest/index.html`
- `android/app/build/reports/tests/testDebugUnitTest/index.html`
- `android/app/build/reports/tests/testReleaseUnitTest/index.html`

Representative APK artifacts present after this batch:

- `android/app/build/outputs/apk/debug/app-debug.apk`
- `android/app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk`
- `android/app/build/outputs/apk/release/app-release-unsigned.apk`

Gradle also refreshed:

- `android/build/reports/problems/problems-report.html`

## Remaining Runtime Scope

Runtime/device validation remains blocked in the current local environment:

- `adb devices -l` printed `List of devices attached` with no device rows.
- `emulator -list-avds` listed one AVD: `Medium_Phone`.
- Installed local system images are Android 36 only; no `android-27` system
  image is installed under `/Users/wangweiyang/Library/Android/sdk/system-images`.

This host-validation batch did not run a new connected/device validation,
Android API 27 runtime validation, low-memory/small-screen runtime validation,
modern-device runtime validation, or a new Android performance capture. Keep
those L12 runtime/device/performance items open unless covered by separate
Android-local reports from a matching attached device, emulator, or performance
capture batch.

## Supervisor Checklist Recommendation

The supervising session can use this report as fresh Android-lane evidence for
marking these Android L12 checklist items complete if not already reconciled:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.

Use this report as minimum Android validation sanity evidence for:

- `./gradlew projects`.

Keep these L12 runtime/device/performance items open:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.
- Capture Android performance report.
