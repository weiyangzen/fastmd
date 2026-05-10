# Stage 1 Android L12 Host Validation Refresh Batch 123 - 2026-05-10

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

- `android/docs/reports/stage1-android-l12-host-validation-refresh-batch123-20260510.md`

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-10.

- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Explicit JDK:
  `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`.
- Android SDK path:
  `/Users/wangweiyang/Library/Android/sdk`.
- Maven resolution used local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true projects` | PASS | Project graph listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; Gradle reported `BUILD SUCCESSFUL in 17s`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true lint build :core:testDebugUnitTest :feature:reader:testDebugUnitTest :app:assembleDebug --stacktrace` | PASS | Host validation completed; Gradle reported `BUILD SUCCESSFUL in 3m 21s` with `474 actionable tasks: 39 executed, 435 up-to-date`. |

The combined host validation command exercised the L12-relevant task surfaces:

- `:app:lint`
- `:core:lint`
- `:feature:library:lint`
- `:feature:reader:lint`
- `:feature:settings:lint`
- `:app:build`
- `:core:build`
- `:feature:library:build`
- `:feature:reader:build`
- `:feature:settings:build`
- `:app:assembleDebug`
- `:core:testDebugUnitTest`
- `:feature:reader:testDebugUnitTest`

The same build also ran the Android renderer/security gates wired into
`check`:

- `auditRendererAssets`
- `auditRendererRequestBlocking`
- `testRendererAssetAudit`
- `testRendererRequestBlockingAudit`
- `stage1AndroidRendererAssetGates`

Representative gate output:

```text
PASS: No Android WebView or android.webkit implementation is present.
PASS: No React Native, Flutter, Cordova, or equivalent web runtime dependency is present.
PASS: Renderer request policy is a first-class Android core contract.
PASS: native fallback request policy and tests satisfy the gate
```

Gradle printed its standard deprecation warning:

- Deprecated Gradle features were used in this build, making it incompatible
  with Gradle 10.

This warning did not fail the validation command.

## Unit Test Evidence

Debug unit test XML artifacts present after the successful command:

- `android/core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.contracts.CoreContractsTest.xml`
- `android/core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.document.MarkdownDocumentTest.xml`
- `android/core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.document.MarkdownSaveIntegrityTest.xml`
- `android/core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.markdown.StructuredMarkdownParserTest.xml`
- `android/core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.reader.BlockSourceEditTest.xml`
- `android/core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.render.RichRendererAssetPolicyTest.xml`
- `android/core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.search.ReaderSearchEngineTest.xml`
- `android/feature/reader/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.feature.reader.ReaderSearchHighlightPlannerTest.xml`

The XML suites recorded:

```text
CoreContractsTest tests=15 failures=0 errors=0 skipped=0
MarkdownDocumentTest tests=1 failures=0 errors=0 skipped=0
MarkdownSaveIntegrityTest tests=6 failures=0 errors=0 skipped=0
StructuredMarkdownParserTest tests=12 failures=0 errors=0 skipped=0
BlockSourceEditTest tests=2 failures=0 errors=0 skipped=0
RichRendererAssetPolicyTest tests=24 failures=0 errors=0 skipped=0
ReaderSearchEngineTest tests=4 failures=0 errors=0 skipped=0
ReaderSearchHighlightPlannerTest tests=3 failures=0 errors=0 skipped=0
```

## Android-Local Artifacts

Lint reports:

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

Build artifacts:

- `android/app/build/outputs/apk/debug/app-debug.apk`
- `android/app/build/outputs/apk/release/app-release-unsigned.apk`
- `android/build/reports/problems/problems-report.html`

## Remaining Runtime Items

This bounded batch did not perform connected-device or emulator validation.
Use the fresher runtime evidence from
`android/docs/reports/stage1-android-l12-connected-validation-batch122-20260510.md`
for connected modern-device smoke results.

Keep these L12 runtime/device items open unless separately reconciled from
another Android-local report:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation if the supervisor
  requires explicit small-screen/watch-class runtime evidence.
- Run Android modern device validation if the supervisor requires a fresh
  runtime session beyond the existing API 36 emulator smoke report.

## Supervisor Checklist Recommendation

The supervising session can use this report as fresh Android-lane evidence for
marking these Android L12 checklist items complete if not already reconciled:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.

This report also refreshes minimum Android Gradle sanity evidence for:

- `./gradlew projects`.
