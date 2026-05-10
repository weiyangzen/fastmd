# Stage 1 Android L12 Gradle Validation Refresh Batch 140 - 2026-05-10

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
validation items in `Docs/Stage1_Mobile_Blueprint.md` and
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

- `android/docs/reports/stage1-android-l12-gradle-validation-refresh-batch140-20260510.md`

Gradle also refreshed generated Android-local build metadata under ignored
`build/` directories while running validation tasks.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-10.

- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Android SDK path:
  `/Users/wangweiyang/Library/Android/sdk`.
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

The checked-in Gradle wrapper works when `JAVA_HOME` is set to the explicit
Homebrew OpenJDK 17 path above.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED for default shell | macOS reported `Unable to locate a Java Runtime`. |
| `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported Homebrew OpenJDK `17.0.17`. |
| `JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk ./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true projects` | PASS | Project graph listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; Gradle reported `BUILD SUCCESSFUL in 12s`. |
| `JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk ./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true lint` | PASS | Gradle reported `BUILD SUCCESSFUL in 19s`; `201 actionable tasks: 10 executed, 191 up-to-date`. |
| `JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk ./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true build` | PASS | Gradle reported `BUILD SUCCESSFUL in 2m 17s`; `474 actionable tasks: 14 executed, 460 up-to-date`. |
| `JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk ./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true :core:testDebugUnitTest` | PASS | Gradle reported `BUILD SUCCESSFUL in 15s`; `17 actionable tasks: 1 executed, 16 up-to-date`. |
| `JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk ./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true :feature:reader:testDebugUnitTest` | PASS | Gradle reported `BUILD SUCCESSFUL in 16s`; `29 actionable tasks: 2 executed, 27 up-to-date`. |
| `JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk ./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true :app:assembleDebug` | PASS | Gradle reported `BUILD SUCCESSFUL in 18s`; `122 actionable tasks: 5 executed, 117 up-to-date`. |

Gradle printed its standard deprecation warning:

```text
Deprecated Gradle features were used in this build, making it incompatible with Gradle 10.
```

This warning did not fail any validation command in this batch.

## Gradle Project Graph

`./gradlew projects` listed the expected Android project graph:

- `:app`
- `:core`
- `:feature:library`
- `:feature:reader`
- `:feature:settings`

## Lint Coverage

The successful root `./gradlew lint` run covered the Android Stage 1 module
graph:

- `:app:lint`
- `:core:lint`
- `:feature:library:lint`
- `:feature:reader:lint`
- `:feature:settings:lint`

Representative generated Android-local lint artifacts:

- `android/app/build/reports/lint-results-debug.html`
- `android/core/build/reports/lint-results-debug.html`
- `android/feature/library/build/reports/lint-results-debug.html`
- `android/feature/reader/build/reports/lint-results-debug.html`
- `android/feature/settings/build/reports/lint-results-debug.html`
- `android/build/reports/problems/problems-report.html`

## Unit Test Evidence

Representative generated Android-local unit-test report artifacts:

- `android/core/build/reports/tests/testDebugUnitTest/index.html`
- `android/core/build/reports/tests/testDebugUnitTest/com.fastmd.mobile.core.contracts.CoreContractsTest/index.html`
- `android/core/build/reports/tests/testDebugUnitTest/com.fastmd.mobile.core.document.MarkdownDocumentTest/index.html`
- `android/core/build/reports/tests/testDebugUnitTest/com.fastmd.mobile.core.document.MarkdownSaveIntegrityTest/index.html`
- `android/core/build/reports/tests/testDebugUnitTest/com.fastmd.mobile.core.markdown.StructuredMarkdownParserTest/index.html`
- `android/core/build/reports/tests/testDebugUnitTest/com.fastmd.mobile.core.reader.BlockSourceEditTest/index.html`
- `android/core/build/reports/tests/testDebugUnitTest/com.fastmd.mobile.core.render.RichRendererAssetPolicyTest/index.html`
- `android/core/build/reports/tests/testDebugUnitTest/com.fastmd.mobile.core.search.ReaderSearchEngineTest/index.html`
- `android/feature/reader/build/reports/tests/testDebugUnitTest/index.html`
- `android/feature/reader/build/reports/tests/testDebugUnitTest/com.fastmd.mobile.feature.reader.ReaderSearchHighlightPlannerTest/index.html`

## APK Evidence

The successful `:app:assembleDebug` run produced:

- `android/app/build/outputs/apk/debug/app-debug.apk`

## Build Gate Notes

The successful root `./gradlew build` run also exercised:

- Debug and release assembly for `:app`.
- Debug and release AAR assembly for `:core`, `:feature:library`,
  `:feature:reader`, and `:feature:settings`.
- Debug and release unit-test tasks where tests exist.
- Lint tasks across the Android project graph.
- Stage 1 renderer asset and request-blocking gates wired into `check`.

Renderer security gate evidence from the root build included:

- `PASS: No Android WebView or android.webkit implementation is present.`
- `PASS: No React Native, Flutter, Cordova, or equivalent web runtime dependency is present.`
- `PASS: No vendored JS/CSS/font renderer asset tree is present; Android rich blocks use native fallback paths.`
- `PASS: Renderer request policy is a first-class Android core contract.`
- `PASS: Unit tests cover allowlisting of bundled Android renderer assets.`
- `PASS: Unit tests cover remote and dangerous renderer request blocking.`
- `PASS: Unit tests cover percent-encoded dangerous renderer requests.`
- `PASS: Unit tests cover external navigation and iframe blocking.`
- `PASS: No Android WebView or android.webkit implementation is present; rich Markdown uses native fallback surfaces.`

## Remaining Open Items

This batch did not attempt connected or real/emulated device validation. Keep
these L12 items open unless covered by a separate device-backed report:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

The Android performance report item has separate evidence in
`android/docs/reports/stage1-android-l12-device-performance-batch139-20260510.md`.

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
