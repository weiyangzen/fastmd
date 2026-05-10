# Stage 1 Android L12 Host Validation Batch 125 - 2026-05-10

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
host validation items from the authoritative blueprint:

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

- `android/docs/reports/stage1-android-l12-host-validation-batch125-20260510.md`

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-10 around 00:29-00:38 CST.

- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Explicit JDK:
  `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`.
- Android SDK path:
  `/Users/wangweiyang/Library/Android/sdk`.
- Installed SDK platforms include `android-35`, matching the Stage 1
  `compileSdk = 35` requirement.
- Maven resolution used local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.

The default shell Java remains unavailable unless `JAVA_HOME` is set:

```text
android/gradlew --version
The operation couldn't be completed. Unable to locate a Java Runtime.
```

All passing Gradle commands below used the explicit Homebrew OpenJDK 17 path.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true projects` | PASS | Project graph listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; Gradle reported `BUILD SUCCESSFUL in 13s`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Dorg.gradle.jvmargs='-Xmx1536m -Dfile.encoding=UTF-8' -Pfastmd.useChinaMavenMirror=true lint --stacktrace` | PASS after retry | First `lint` attempt with the default `-Xmx2048m` single-use daemon exited with `DaemonDisappearedException` before lint tasks ran. Retrying with `-Xmx1536m` reached all lint tasks and Gradle reported `BUILD SUCCESSFUL in 23s` with `201 actionable tasks: 10 executed, 191 up-to-date`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Dorg.gradle.jvmargs='-Xmx1536m -Dfile.encoding=UTF-8' -Pfastmd.useChinaMavenMirror=true build --stacktrace` | BLOCKED by single-use Gradle daemon handling | The command reached package/build tasks and Android renderer gates, then the single-use daemon disappeared while executing `testRendererAssetAudit`. The daemon log ended with `Daemon vm is shutting down...` and `Remove shutdown hook failed`. |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Direct execution of the same renderer asset audit regression script completed all cases, including blob/filesystem URL, dynamic code, worker, manifest, metadata, WebView, and React Native runtime checks. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew -Dorg.gradle.jvmargs='-Xmx1536m -Dfile.encoding=UTF-8' -Pfastmd.useChinaMavenMirror=true build --stacktrace` | PASS | Re-running `build` with the reusable Gradle daemon completed Android build, lint, unit tests, package tasks, and renderer/security gates; Gradle reported `BUILD SUCCESSFUL in 2m 25s` with `474 actionable tasks: 14 executed, 460 up-to-date`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew -Dorg.gradle.jvmargs='-Xmx1536m -Dfile.encoding=UTF-8' -Pfastmd.useChinaMavenMirror=true :core:testDebugUnitTest --stacktrace` | PASS | Explicit core unit-test task passed; initial explicit run was up-to-date and Gradle reported `BUILD SUCCESSFUL in 2s`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew -Dorg.gradle.jvmargs='-Xmx1536m -Dfile.encoding=UTF-8' -Pfastmd.useChinaMavenMirror=true :feature:reader:testDebugUnitTest --stacktrace` | PASS | Explicit reader unit-test task passed; initial explicit run was up-to-date and Gradle reported `BUILD SUCCESSFUL in 2s`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew -Dorg.gradle.jvmargs='-Xmx1536m -Dfile.encoding=UTF-8' -Pfastmd.useChinaMavenMirror=true :app:assembleDebug --stacktrace` | PASS | Debug APK assembly completed; Gradle reported `BUILD SUCCESSFUL in 2s` with `122 actionable tasks: 5 executed, 117 up-to-date`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew -Dorg.gradle.jvmargs='-Xmx1536m -Dfile.encoding=UTF-8' -Pfastmd.useChinaMavenMirror=true :core:testDebugUnitTest :feature:reader:testDebugUnitTest --rerun-tasks --stacktrace` | PASS | Fresh core and reader unit-test artifacts were regenerated; Gradle reported `BUILD SUCCESSFUL in 53s` with `34 actionable tasks: 34 executed`. |

Gradle printed its standard deprecation warning:

- Deprecated Gradle features were used in this build, making it incompatible
  with Gradle 10.

This warning did not fail any passing validation command.

## Unit Test Evidence

Fresh `--rerun-tasks` unit-test XML artifacts were generated at:

- `android/core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.contracts.CoreContractsTest.xml`
- `android/core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.document.MarkdownDocumentTest.xml`
- `android/core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.document.MarkdownSaveIntegrityTest.xml`
- `android/core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.markdown.StructuredMarkdownParserTest.xml`
- `android/core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.reader.BlockSourceEditTest.xml`
- `android/core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.render.RichRendererAssetPolicyTest.xml`
- `android/core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.search.ReaderSearchEngineTest.xml`
- `android/feature/reader/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.feature.reader.ReaderSearchHighlightPlannerTest.xml`

The regenerated XML suites record:

- Core: 64 tests, 0 skipped, 0 failures, 0 errors.
- Feature reader: 3 tests, 0 skipped, 0 failures, 0 errors.

## Android-Local Artifacts

Lint reports refreshed by this batch:

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

APK artifacts present after this batch:

- `android/app/build/outputs/apk/debug/app-debug.apk`
- `android/app/build/outputs/apk/debug/output-metadata.json`

Gradle also refreshed:

- `android/build/reports/problems/problems-report.html`

## Build Gate Coverage

The passing `./gradlew build` run included these L12-relevant task surfaces:

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

The build also ran the Android-local renderer/security gates wired into
`check`, including:

- `auditRendererAssets`
- `auditRendererRequestBlocking`
- `testRendererAssetAudit`
- `testRendererRequestBlockingAudit`
- `stage1AndroidRendererAssetGates`

Representative gate output:

- `PASS: No Android WebView or android.webkit implementation is present.`
- `PASS: No React Native, Flutter, Cordova, or equivalent web runtime dependency is present.`
- `PASS: No vendored JS/CSS/font renderer asset tree is present; Android rich blocks use native fallback paths.`
- `PASS: Renderer request policy is a first-class Android core contract.`
- `PASS: native fallback request policy and tests satisfy the gate.`

## Remaining Runtime Scope

This host-validation batch did not run connected/device validation. Use the
existing Android-local runtime reports for connected, modern, and constrained
small-screen evidence. Android API 27 runtime validation remains open unless a
matching API 27 device or emulator image is made available.

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

This report does not claim completion for:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.
- Capture Android performance report.
