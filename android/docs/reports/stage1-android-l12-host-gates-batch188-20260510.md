# Stage 1 Android L12 Host Gates Batch 188 - 2026-05-10

## Scope

Android live-lane bounded batch for the next still-open Android-owned L12
platform validation items after the existing lint and root build evidence:

- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android product source changes were required. The only intentional repository
write in this batch is this Android-local evidence report.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-host-gates-batch188-20260510.md`

Gradle also refreshed generated Android-local build outputs under ignored
`build/` directories while running validation.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-10 CST.

- Gradle entry point: checked-in wrapper `./gradlew`.
- Android SDK path from `local.properties`:
  `/Users/wangweiyang/Library/Android/sdk`.
- Explicit JDK used for passing validation:
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

The passing Gradle commands used this scoped environment:

```bash
JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
PATH=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin:$PATH
ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk
ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk
```

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED | macOS reported `Unable to locate a Java Runtime` before Gradle could start. |
| `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported OpenJDK `17.0.17`. |
| `sed -n '1,80p' local.properties` | PASS | Confirmed `sdk.dir=/Users/wangweiyang/Library/Android/sdk`. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true :core:testDebugUnitTest` with scoped JDK 17/SDK env | PASS | Gradle reported `BUILD SUCCESSFUL in 16s`; `17 actionable tasks: 1 executed, 16 up-to-date`. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true :feature:reader:testDebugUnitTest` with scoped JDK 17/SDK env | PASS | Gradle reported `BUILD SUCCESSFUL in 16s`; `29 actionable tasks: 2 executed, 27 up-to-date`. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true :app:assembleDebug` with scoped JDK 17/SDK env | PASS | Gradle reported `BUILD SUCCESSFUL in 17s`; `122 actionable tasks: 5 executed, 117 up-to-date`. |

Gradle printed its standard non-failing deprecation warning in each passing
command:

```text
Deprecated Gradle features were used in this build, making it incompatible with Gradle 10.
```

## Unit Test Evidence

`core/build/test-results/testDebugUnitTest` contains these JUnit XML result
files after this batch:

- `TEST-com.fastmd.mobile.core.contracts.CoreContractsTest.xml`
- `TEST-com.fastmd.mobile.core.document.MarkdownDocumentTest.xml`
- `TEST-com.fastmd.mobile.core.document.MarkdownSaveIntegrityTest.xml`
- `TEST-com.fastmd.mobile.core.markdown.StructuredMarkdownParserTest.xml`
- `TEST-com.fastmd.mobile.core.reader.BlockSourceEditTest.xml`
- `TEST-com.fastmd.mobile.core.render.RichRendererAssetPolicyTest.xml`
- `TEST-com.fastmd.mobile.core.search.ReaderSearchEngineTest.xml`

Observed core suite totals:

| Suite | Tests | Failures | Errors | Skipped |
| --- | ---: | ---: | ---: | ---: |
| `CoreContractsTest` | 15 | 0 | 0 | 0 |
| `MarkdownDocumentTest` | 1 | 0 | 0 | 0 |
| `MarkdownSaveIntegrityTest` | 6 | 0 | 0 | 0 |
| `StructuredMarkdownParserTest` | 12 | 0 | 0 | 0 |
| `BlockSourceEditTest` | 2 | 0 | 0 | 0 |
| `RichRendererAssetPolicyTest` | 24 | 0 | 0 | 0 |
| `ReaderSearchEngineTest` | 4 | 0 | 0 | 0 |

`feature/reader/build/test-results/testDebugUnitTest` contains this JUnit XML
result file after this batch:

- `TEST-com.fastmd.mobile.feature.reader.ReaderSearchHighlightPlannerTest.xml`

Observed reader suite total:

| Suite | Tests | Failures | Errors | Skipped |
| --- | ---: | ---: | ---: | ---: |
| `ReaderSearchHighlightPlannerTest` | 3 | 0 | 0 | 0 |

## Assemble Evidence

The debug APK artifact is present after `:app:assembleDebug`:

- `app/build/outputs/apk/debug/app-debug.apk` (`9.3M`)
- `app/build/outputs/apk/debug/output-metadata.json` (`408B`)

## Remaining Open Items

This batch intentionally stopped after host-side unit-test and debug-assemble
gates. Keep these Android L12 items open unless covered by separate
Android-local evidence:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.
- Capture Android performance report.

## Supervisor Checklist Recommendation

The supervising session can use this report as fresh Android-lane evidence for
marking these L12 Android checklist items complete if not already reconciled:

- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.

Do not use this report to newly claim completion for connected-device, API 27
runtime, low-memory/small-screen runtime, modern-device runtime, or Android
performance report items.
