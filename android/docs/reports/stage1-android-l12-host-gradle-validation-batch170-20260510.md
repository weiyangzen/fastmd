# Stage 1 Android L12 Host Gradle Validation Batch 170 - 2026-05-10

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
platform validation surface in `Docs/Stage1_Mobile_Blueprint.md` and
`Docs/todos_20260506.md`.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android product source changes were required. The only intentional repository
write in this batch is this Android-local evidence report.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-host-gradle-validation-batch170-20260510.md`

Gradle also refreshed Android-local generated build metadata, lint reports, test
reports, and APK outputs under ignored `build/` directories while running
validation.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-10 around 07:27 CST.

- Gradle entry point: checked-in wrapper `./gradlew`.
- Android SDK path from `local.properties`:
  `/Users/wangweiyang/Library/Android/sdk`.
- Maven mirror opt-in used for Gradle commands:
  `-Pfastmd.useChinaMavenMirror=true`.
- Default shell Java remains blocked by macOS Java registration.
- Explicit JDK used for passing Gradle commands:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
- Explicit Java version: OpenJDK `17.0.17`.

Passing Gradle commands used this scoped environment:

```bash
JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home \
PATH=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin:$PATH \
ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk \
ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk
```

The default shell Java command still fails before Gradle can start:

```text
The operation couldn't be completed. Unable to locate a Java Runtime.
Please visit http://www.java.com for information on installing Java.
```

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `date '+%Y-%m-%d %H:%M:%S %Z %z'` | PASS | Printed `2026-05-10 07:27:33 CST +0800`. |
| `java -version` | BLOCKED | macOS reported `Unable to locate a Java Runtime`. |
| `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported OpenJDK `17.0.17`. |
| `./gradlew projects --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true` with explicit JDK 17 and SDK env | PASS | `BUILD SUCCESSFUL in 13s`; module graph includes `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `./gradlew lint build :core:testDebugUnitTest :feature:reader:testDebugUnitTest :app:assembleDebug --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true` with explicit JDK 17 and SDK env | PASS | `BUILD SUCCESSFUL in 3m 25s`; `474 actionable tasks: 36 executed, 438 up-to-date`. |

Gradle printed its standard non-failing deprecation warning during the passing
host-side commands:

```text
Deprecated Gradle features were used in this build, making it incompatible with Gradle 10.
```

## Host Gradle Coverage

The successful combined Gradle command covers these Android L12 checklist items:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.

The root `build` task also ran the Stage 1 renderer asset and request-blocking
audit gates wired into `check`; those gates passed without WebView,
web-runtime, remote-subresource, dynamic-code, or renderer request-policy
violations.

Generated debug unit-test XML under `build/test-results/testDebugUnitTest`
summarizes to:

```text
tests=82 skipped=0 failures=0 errors=0
```

Debug test result XML was produced for:

- `app/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.session.FastMdReaderSessionViewModelTest.xml`
- `core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.contracts.CoreContractsTest.xml`
- `core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.document.MarkdownDocumentTest.xml`
- `core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.document.MarkdownSaveIntegrityTest.xml`
- `core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.markdown.StructuredMarkdownParserTest.xml`
- `core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.reader.BlockSourceEditTest.xml`
- `core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.render.RichRendererAssetPolicyTest.xml`
- `core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.search.ReaderSearchEngineTest.xml`
- `feature/reader/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.feature.reader.ReaderSearchHighlightPlannerTest.xml`

Representative Android-local artifacts present after this batch:

- `android/app/build/outputs/apk/debug/app-debug.apk` (`9.3M`)
- `android/app/build/outputs/apk/release/app-release-unsigned.apk` (`1.1M`)
- `android/app/build/reports/lint-results-debug.html`
- `android/core/build/reports/lint-results-debug.html`
- `android/feature/library/build/reports/lint-results-debug.html`
- `android/feature/reader/build/reports/lint-results-debug.html`
- `android/feature/settings/build/reports/lint-results-debug.html`
- `android/app/build/reports/tests/testDebugUnitTest/index.html`
- `android/core/build/reports/tests/testDebugUnitTest/index.html`
- `android/feature/reader/build/reports/tests/testDebugUnitTest/index.html`
- `android/build/reports/problems/problems-report.html`

## Remaining Runtime Validation

This bounded batch intentionally covered host-side Gradle validation only. Keep
these Android L12 checklist items open until separate device-backed or
performance-specific evidence exists:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.
- Capture Android performance report.

## Supervisor Checklist Recommendation

The supervising session can use this report as fresh Android-lane evidence for
marking these L12 Android checklist items complete if they have not already been
reconciled:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.

Do not use this report to newly claim completion for connected-device, API 27
runtime, low-memory/small-screen runtime, modern-device runtime, or Android
performance report items.
