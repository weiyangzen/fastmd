# Stage 1 Android L12 Host Validation JBR Batch 182 - 2026-05-10

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
platform validation items in `Docs/Stage1_Mobile_Blueprint.md` and
`Docs/todos_20260506.md`.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android product source changes were required. The only intentional repository
write in this batch is this Android-local evidence report.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-host-validation-jbr-batch182-20260510.md`

Gradle also refreshed Android-local generated build metadata, lint reports, test
reports, APK outputs, and the Gradle problems report under generated `build/`
directories while running validation.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-10 CST.

- Timestamp captured by `date`: `2026-05-10 09:31:23 CST +0800`.
- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Android SDK path from `android/local.properties`:
  `/Users/wangweiyang/Library/Android/sdk`.
- Default shell `./gradlew --no-daemon projects`: BLOCKED before Gradle startup
  because macOS reported `Unable to locate a Java Runtime`.
- Default shell `JAVA_HOME` was empty.
- Explicit JDK used for passing Gradle commands:
  `/Applications/Android Studio.app/Contents/jbr/Contents/Home`.
- Explicit Java version: OpenJDK `21.0.6` bundled with Android Studio.

Passing Gradle commands used this scoped environment prefix:

```bash
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew --no-daemon ...
```

Gradle printed the standard non-failing deprecation warning during Gradle
commands:

```text
Deprecated Gradle features were used in this build, making it incompatible with Gradle 10.
```

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `./gradlew --no-daemon projects` with default shell environment | BLOCKED | macOS reported `Unable to locate a Java Runtime`; Gradle did not start. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew --no-daemon projects` | PASS | `BUILD SUCCESSFUL in 3s`; confirmed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew --no-daemon lint` | PASS | `BUILD SUCCESSFUL in 35s`; `201 actionable tasks: 35 executed, 166 up-to-date`; wrote lint reports for app, core, reader, library, and settings. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew --no-daemon build` | PASS | `BUILD SUCCESSFUL in 2m 21s`; `474 actionable tasks: 39 executed, 435 up-to-date`; included debug/release assembly, lint, unit tests, and Stage 1 renderer asset/request-blocking audit gates. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew --no-daemon :core:testDebugUnitTest` | PASS | `BUILD SUCCESSFUL in 4s`; `:core:testDebugUnitTest UP-TO-DATE`; prior XML remains zero-failure. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew --no-daemon :feature:reader:testDebugUnitTest` | PASS | `BUILD SUCCESSFUL in 6s`; `:feature:reader:testDebugUnitTest UP-TO-DATE`; prior XML remains zero-failure. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew --no-daemon :app:assembleDebug` | PASS | `BUILD SUCCESSFUL in 5s`; `:app:assembleDebug UP-TO-DATE`; debug APK present at `android/app/build/outputs/apk/debug/app-debug.apk`. |
| `/Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices -l` | BLOCKED for device validation | Printed only `List of devices attached`; no device rows. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew --no-daemon :app:connectedDebugAndroidTest` | BLOCKED | Built and packaged instrumentation inputs, then failed at `:app:connectedDebugAndroidTest` with `DeviceException: No connected devices!`. |

## Host Gradle Coverage

The passing commands in this batch cover these Android L12 checklist items:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.

The `build` task also exercised the Stage 1 renderer asset and request-blocking
audit gates wired into `check`; those gates passed without WebView,
web-runtime, remote-subresource, dynamic-code, or renderer request-policy
violations.

Representative Android-local artifacts present after this batch:

- `android/app/build/outputs/apk/debug/app-debug.apk`
- `android/app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk`
- `android/app/build/outputs/apk/release/app-release-unsigned.apk`
- `android/app/build/reports/lint-results-debug.html`
- `android/core/build/reports/lint-results-debug.html`
- `android/feature/reader/build/reports/lint-results-debug.html`
- `android/feature/library/build/reports/lint-results-debug.html`
- `android/feature/settings/build/reports/lint-results-debug.html`
- `android/app/build/reports/tests/testDebugUnitTest/index.html`
- `android/core/build/reports/tests/testDebugUnitTest/index.html`
- `android/feature/reader/build/reports/tests/testDebugUnitTest/index.html`
- `android/build/reports/problems/problems-report.html`

Debug unit-test XML under `build/test-results/testDebugUnitTest` remains present
for:

- `app/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.session.FastMdReaderSessionViewModelTest.xml`
- `core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.contracts.CoreContractsTest.xml`
- `core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.document.MarkdownDocumentTest.xml`
- `core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.document.MarkdownSaveIntegrityTest.xml`
- `core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.markdown.StructuredMarkdownParserTest.xml`
- `core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.reader.BlockSourceEditTest.xml`
- `core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.render.RichRendererAssetPolicyTest.xml`
- `core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.search.ReaderSearchEngineTest.xml`
- `feature/reader/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.feature.reader.ReaderSearchHighlightPlannerTest.xml`

## Runtime Validation Status

The connected Android instrumentation task remains open because no device or
running emulator is visible to ADB in this shell:

```text
List of devices attached
```

`./gradlew :app:connectedDebugAndroidTest` failed with:

```text
Execution failed for task ':app:connectedDebugAndroidTest'.
> com.android.builder.testing.api.DeviceException: No connected devices!
```

Keep these Android L12 checklist items open until separate device-backed
evidence exists:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.
- Capture Android performance report if the supervisor requires device-timing
  performance evidence rather than the source-level performance report already
  captured in earlier Android reports.

## Checklist Evidence For Supervisor

The supervising session can use this report as current Android-lane evidence for
marking these L12 checklist items complete:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.

Do not mark the connected/API/device validation items complete from this batch;
the exact blocker is `No connected devices!`.
