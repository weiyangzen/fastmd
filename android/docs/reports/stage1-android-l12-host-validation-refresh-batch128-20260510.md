# Stage 1 Android L12 Host Validation Refresh Batch 128 - 2026-05-10

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
validation items from `Docs/Stage1_Mobile_Blueprint.md` and
`Docs/todos_20260506.md`:

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

- `android/docs/reports/stage1-android-l12-host-validation-refresh-batch128-20260510.md`

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-10.

- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Explicit JDK used for passing Gradle commands:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
- Explicit Java version:
  `openjdk version "17.0.17" 2025-10-21`.
- Android SDK path:
  `/Users/wangweiyang/Library/Android/sdk`.
- Maven resolution used local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported Homebrew OpenJDK `17.0.17`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true projects` | PASS | Project graph listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; Gradle reported `BUILD SUCCESSFUL in 12s`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true lint` | PASS | Gradle reported `BUILD SUCCESSFUL in 19s`; `201 actionable tasks: 10 executed, 191 up-to-date`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true :core:testDebugUnitTest :feature:reader:testDebugUnitTest :app:assembleDebug` | PASS | Gradle reported `BUILD SUCCESSFUL in 17s`; `132 actionable tasks: 5 executed, 127 up-to-date`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true build` | PASS | Gradle reported `BUILD SUCCESSFUL in 2m 26s`; `474 actionable tasks: 14 executed, 460 up-to-date`. |
| `ANDROID_HOME=... ANDROID_SDK_ROOT=... adb devices -l` | BLOCKED for new connected runtime validation | Printed `List of devices attached` with no attached device rows. |

Gradle printed its standard deprecation warning:

- Deprecated Gradle features were used in this build, making it incompatible
  with Gradle 10.

This warning did not fail any passing validation command.

## Build Gate Coverage

The passing root `./gradlew lint` run covered:

- `:app:lint`
- `:core:lint`
- `:feature:library:lint`
- `:feature:reader:lint`
- `:feature:settings:lint`

The explicit host validation command covered:

- `:core:testDebugUnitTest`
- `:feature:reader:testDebugUnitTest`
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

## Unit Test Evidence

The explicit `:core:testDebugUnitTest :feature:reader:testDebugUnitTest`
command completed successfully in this batch. Gradle considered the test tasks
up-to-date, so existing XML artifacts remain the current on-disk test-result
records:

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

## Android-Local Artifacts

APK artifacts present after this batch:

- `android/app/build/outputs/apk/debug/app-debug.apk`
- `android/app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk`
- `android/app/build/outputs/apk/release/app-release-unsigned.apk`

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

Gradle also refreshed:

- `android/build/reports/problems/problems-report.html`

## Remaining Runtime Scope

This host-validation refresh did not run a new connected/device validation
because the current ADB state has no attached device or booted emulator:

```text
List of devices attached
```

Keep these L12 runtime/device items open unless covered by separate Android
reports from a matching attached device or emulator:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

The existing Android-local performance report remains the evidence for:

- Capture Android performance report.

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

Do not use this report to newly claim completion for connected-device, API 27
runtime, low-memory/small-screen runtime, or modern-device runtime items.
