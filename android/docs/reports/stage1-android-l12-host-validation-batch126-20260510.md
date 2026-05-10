# Stage 1 Android L12 Host Validation Batch 126 - 2026-05-10

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
validation items in `Docs/Stage1_Mobile_Blueprint.md`:

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

- `android/docs/reports/stage1-android-l12-host-validation-batch126-20260510.md`

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-10 around 00:39-00:46 CST.

- Default shell Java lookup is blocked:
  `The operation couldn't be completed. Unable to locate a Java Runtime.`
- Explicit JDK used for passing Gradle commands:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
- Android SDK path from `local.properties`:
  `/Users/wangweiyang/Library/Android/sdk`.
- Maven mirror opt-in used:
  `-Pfastmd.useChinaMavenMirror=true`.
- JVM args used for host validation:
  `-Dorg.gradle.jvmargs='-Xmx1536m -Dfile.encoding=UTF-8'`.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED for default shell | macOS reported no located Java Runtime. |
| `./gradlew --version` | BLOCKED for default shell | macOS reported no located Java Runtime before Gradle could start. |
| `./gradlew projects` | BLOCKED for default shell | macOS reported no located Java Runtime before Gradle could start. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true projects` | PASS | Project graph listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; Gradle reported `BUILD SUCCESSFUL in 12s`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew -Dorg.gradle.jvmargs='-Xmx1536m -Dfile.encoding=UTF-8' -Pfastmd.useChinaMavenMirror=true lint` | PASS | Gradle reported `BUILD SUCCESSFUL in 1m 25s` with `201 actionable tasks: 30 executed, 171 up-to-date`; lint reports were written for app, core, library, reader, and settings modules. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew -Dorg.gradle.jvmargs='-Xmx1536m -Dfile.encoding=UTF-8' -Pfastmd.useChinaMavenMirror=true :core:testDebugUnitTest :feature:reader:testDebugUnitTest` | PASS | Gradle reported `BUILD SUCCESSFUL in 3s` with `34 actionable tasks: 2 executed, 32 up-to-date`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew -Dorg.gradle.jvmargs='-Xmx1536m -Dfile.encoding=UTF-8' -Pfastmd.useChinaMavenMirror=true :app:assembleDebug` | PASS | Gradle reported `BUILD SUCCESSFUL in 2s` with `122 actionable tasks: 5 executed, 117 up-to-date`; debug APK output is present. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew -Dorg.gradle.jvmargs='-Xmx1536m -Dfile.encoding=UTF-8' -Pfastmd.useChinaMavenMirror=true build` | PASS | Gradle reported `BUILD SUCCESSFUL in 2m 10s` with `474 actionable tasks: 19 executed, 455 up-to-date`; build included debug/release assembly, lint, unit tests, and renderer/security gates. |

Gradle printed its standard deprecation warning:

- Deprecated Gradle features were used in this build, making it incompatible
  with Gradle 10.

This warning did not fail any passing validation command.

## Build Gate Coverage

The passing `./gradlew build` run included these relevant task surfaces:

- `:app:assembleDebug`
- `:app:assembleRelease`
- `:app:lint`
- `:app:testDebugUnitTest`
- `:app:testReleaseUnitTest`
- `:core:lint`
- `:core:testDebugUnitTest`
- `:core:testReleaseUnitTest`
- `:feature:library:lint`
- `:feature:reader:lint`
- `:feature:reader:testDebugUnitTest`
- `:feature:reader:testReleaseUnitTest`
- `:feature:settings:lint`
- `auditRendererAssets`
- `auditRendererRequestBlocking`
- `testRendererAssetAudit`
- `testRendererRequestBlockingAudit`
- `stage1AndroidRendererAssetGates`

Representative renderer/security gate output:

- `PASS: No Android WebView or android.webkit implementation is present.`
- `PASS: No React Native, Flutter, Cordova, or equivalent web runtime dependency is present.`
- `PASS: No vendored JS/CSS/font renderer asset tree is present; Android rich blocks use native fallback paths.`
- `PASS: Renderer request policy is a first-class Android core contract.`
- `PASS: native fallback request policy and tests satisfy the gate.`

## Unit Test Evidence

Existing debug unit-test XML artifacts remain present and record zero failures:

- `android/core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.contracts.CoreContractsTest.xml`:
  15 tests, 0 skipped, 0 failures, 0 errors.
- `android/core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.document.MarkdownDocumentTest.xml`:
  1 test, 0 skipped, 0 failures, 0 errors.
- `android/core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.document.MarkdownSaveIntegrityTest.xml`:
  6 tests, 0 skipped, 0 failures, 0 errors.
- `android/core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.markdown.StructuredMarkdownParserTest.xml`:
  12 tests, 0 skipped, 0 failures, 0 errors.
- `android/core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.reader.BlockSourceEditTest.xml`:
  2 tests, 0 skipped, 0 failures, 0 errors.
- `android/core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.render.RichRendererAssetPolicyTest.xml`:
  24 tests, 0 skipped, 0 failures, 0 errors.
- `android/core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.search.ReaderSearchEngineTest.xml`:
  4 tests, 0 skipped, 0 failures, 0 errors.
- `android/feature/reader/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.feature.reader.ReaderSearchHighlightPlannerTest.xml`:
  3 tests, 0 skipped, 0 failures, 0 errors.

The explicit `:core:testDebugUnitTest :feature:reader:testDebugUnitTest` command
completed successfully in this batch; Gradle considered the test tasks
up-to-date.

## Android-Local Artifacts

APK artifacts present after this batch:

- `android/app/build/outputs/apk/debug/app-debug.apk`
- `android/app/build/outputs/apk/debug/output-metadata.json`
- `android/app/build/outputs/apk/release/app-release-unsigned.apk`
- `android/app/build/outputs/apk/release/output-metadata.json`

Lint reports present after this batch:

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

Gradle also refreshed:

- `android/build/reports/problems/problems-report.html`

## Remaining Runtime Scope

This host-validation batch did not run connected/device validation. These L12
items remain open unless separately supported by a matching attached device or
emulator:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.
- Capture Android performance report.

The default shell Java runtime lookup also remains blocked unless `JAVA_HOME`
is set explicitly to the Homebrew OpenJDK 17 path above.

## Supervisor Checklist Recommendation

The supervising session can use this report as Android-lane evidence for
marking these Android L12 checklist items complete:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.

Use this report as minimum Android validation sanity evidence for:

- `./gradlew projects`.

This report does not claim completion for any connected-device, API 27 runtime,
small-screen runtime, modern-device runtime, or Android performance-report item.
