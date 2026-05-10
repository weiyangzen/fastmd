# Stage 1 Android L12 Build Validation Batch 187 - 2026-05-10

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
platform validation item after the fresh lint evidence:

- Run Android `./gradlew build`.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android product source changes were required. The only intentional repository
write in this batch is this Android-local evidence report.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-build-validation-batch187-20260510.md`

Gradle also refreshed generated Android-local build outputs under ignored
`build/` directories while running validation.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-10 CST.

- Gradle entry point: checked-in wrapper `./gradlew`.
- Android SDK path from `local.properties`:
  `/Users/wangweiyang/Library/Android/sdk`.
- Explicit JDK used for validation:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
- Explicit Java version:
  `openjdk version "17.0.17" 2025-10-21`.
- Maven resolution used local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.

The passing Gradle command used this scoped environment:

```bash
JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
PATH=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin:$PATH
ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk
ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk
```

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` with scoped JDK 17 | PASS | Reported OpenJDK `17.0.17`. |
| `sed -n '1,80p' local.properties` | PASS | Confirmed `sdk.dir=/Users/wangweiyang/Library/Android/sdk`. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true build` | PASS | Gradle reported `BUILD SUCCESSFUL in 3m 41s`; `474 actionable tasks: 39 executed, 435 up-to-date`. |

Gradle printed its standard non-failing deprecation warning:

```text
Deprecated Gradle features were used in this build, making it incompatible with Gradle 10.
```

## Build Coverage

The successful root `build` run covered the Android Stage 1 module graph:

- `:app:build`
- `:core:build`
- `:feature:library:build`
- `:feature:reader:build`
- `:feature:settings:build`

The run also executed or verified the custom Android renderer and security gates
wired into the Gradle graph, including:

- `:auditRendererAssets`
- `:auditRendererRequestBlocking`
- `:testRendererAssetAudit`
- `:testRendererRequestBlockingAudit`
- `:stage1AndroidRendererAssetGates`

Representative passing gate output included:

```text
PASS: No Android WebView or android.webkit implementation is present.
PASS: No React Native, Flutter, Cordova, or equivalent web runtime dependency is present.
PASS: No vendored JS/CSS/font renderer asset tree is present; Android rich blocks use native fallback paths.
PASS: Renderer request policy is a first-class Android core contract.
PASS: native fallback request policy and tests satisfy the gate
```

## Generated Android-Local Artifacts

Representative Android-local artifacts present after this batch:

- `android/app/build/outputs/apk/debug/app-debug.apk` (`9.3M`)
- `android/app/build/outputs/apk/release/app-release-unsigned.apk` (`1.1M`)
- `android/app/build/reports/lint-results-debug.html`
- `android/core/build/reports/lint-results-debug.html`
- `android/feature/library/build/reports/lint-results-debug.html`
- `android/feature/reader/build/reports/lint-results-debug.html`
- `android/feature/settings/build/reports/lint-results-debug.html`
- `android/build/reports/problems/problems-report.html`

Generated lint text summaries after this batch:

| Module | Summary |
| --- | --- |
| `:app` | `0 errors, 25 warnings` |
| `:core` | `0 errors, 1 warning` |
| `:feature:reader` | `0 errors, 4 warnings` |
| `:feature:library` | `0 errors, 1 warning` |
| `:feature:settings` | `0 errors, 1 warning` |

JUnit XML files observed under Android-local `testDebugUnitTest` outputs:

- `app/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.session.FastMdReaderSessionViewModelTest.xml`
- `core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.contracts.CoreContractsTest.xml`
- `core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.document.MarkdownDocumentTest.xml`
- `core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.document.MarkdownSaveIntegrityTest.xml`
- `core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.markdown.StructuredMarkdownParserTest.xml`
- `core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.reader.BlockSourceEditTest.xml`
- `core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.render.RichRendererAssetPolicyTest.xml`
- `core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.search.ReaderSearchEngineTest.xml`
- `feature/reader/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.feature.reader.ReaderSearchHighlightPlannerTest.xml`

## Remaining Open Items

This batch intentionally stopped after the root Android `build` validation item.
Keep these Android L12 items open unless covered by separate Android-local
evidence:

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
marking this L12 Android checklist item complete if not already reconciled:

- Run Android `./gradlew build`.

Do not use this report to newly claim completion for explicit standalone core
unit-test, reader unit-test, assembleDebug, connected-device, API 27 runtime,
low-memory/small-screen runtime, modern-device runtime, or Android performance
report items.
