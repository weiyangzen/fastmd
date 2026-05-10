# Stage 1 Android L12 Validation Batch 190 - 2026-05-10

## Scope

Android live-lane bounded validation batch for the earliest still-open
Android-owned L12 checklist items. This batch stayed inside `android/**` and
did not edit `ios/**`, shared `Docs/**`, or `.cron/**`.

No Android product source changes were required. The only intentional repository
write is this Android-local evidence report.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-validation-batch190-20260510.md`

Gradle also refreshed ignored Android build outputs under `android/**/build/`.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-10 CST.

- Checked-in Gradle wrapper: `./gradlew`
- Android SDK: `/Users/wangweiyang/Library/Android/sdk`
- Scoped JDK 17: `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`
- Java version: `openjdk version "17.0.17" 2025-10-21`
- Maven mirror opt-in: `-Pfastmd.useChinaMavenMirror=true`

The default shell still has no discoverable Java runtime:

```text
java -version
The operation couldn't be completed. Unable to locate a Java Runtime.
Please visit http://www.java.com for information on installing Java.
```

All passing Gradle commands used:

```bash
JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
PATH=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin:$PATH
ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk
ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk
```

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `./gradlew projects` with scoped JDK/SDK env | PASS | `BUILD SUCCESSFUL in 27s`; project graph contains `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `./gradlew :core:testDebugUnitTest` with scoped JDK/SDK env | PASS | `BUILD SUCCESSFUL in 18s`; `17 actionable tasks: 1 executed, 16 up-to-date`. |
| `./gradlew :feature:reader:testDebugUnitTest` with scoped JDK/SDK env | PASS | `BUILD SUCCESSFUL in 20s`; `29 actionable tasks: 2 executed, 27 up-to-date`. |
| `./gradlew :app:assembleDebug` with scoped JDK/SDK env | PASS | `BUILD SUCCESSFUL in 19s`; debug APK present at `app/build/outputs/apk/debug/app-debug.apk`. |
| `./gradlew lint` with scoped JDK/SDK env | PASS | `BUILD SUCCESSFUL in 29s`; lint reports refreshed under `app/build/reports/lint-results-debug.*`. |
| `./gradlew build` with scoped JDK/SDK env | PASS | `BUILD SUCCESSFUL in 2m 33s`; includes debug/release assembly, unit checks, lint, and Android renderer/security audit tasks. |
| `./gradlew :app:connectedDebugAndroidTest` with scoped JDK/SDK env | PASS | `BUILD SUCCESSFUL in 41s`; ran 4 instrumented tests on `Medium_Phone(AVD) - 16` with zero failures. |
| `tools/device_validation_preflight.sh` | BLOCKED | Attached `emulator-5554` is API 36 and about 1999 MiB RAM, but no API 27 system image is installed. |
| `./gradlew stage1AndroidPerformanceReport` with scoped JDK/SDK env | PASS | `BUILD SUCCESSFUL in 14s`; `auditPerformanceReport` passed and printed profile limits plus fixture matrix. |

Gradle printed its standard non-failing deprecation warning in the passing
commands:

```text
Deprecated Gradle features were used in this build, making it incompatible with Gradle 10.
```

## Unit Test Evidence

`core/build/test-results/testDebugUnitTest` contains:

| Suite | Tests | Failures | Errors | Skipped |
| --- | ---: | ---: | ---: | ---: |
| `CoreContractsTest` | 15 | 0 | 0 | 0 |
| `MarkdownDocumentTest` | 1 | 0 | 0 | 0 |
| `MarkdownSaveIntegrityTest` | 6 | 0 | 0 | 0 |
| `StructuredMarkdownParserTest` | 12 | 0 | 0 | 0 |
| `BlockSourceEditTest` | 2 | 0 | 0 | 0 |
| `RichRendererAssetPolicyTest` | 24 | 0 | 0 | 0 |
| `ReaderSearchEngineTest` | 4 | 0 | 0 | 0 |

`feature/reader/build/test-results/testDebugUnitTest` contains:

| Suite | Tests | Failures | Errors | Skipped |
| --- | ---: | ---: | ---: | ---: |
| `ReaderSearchHighlightPlannerTest` | 3 | 0 | 0 | 0 |

## Connected Device Evidence

`adb devices -l` reported:

```text
emulator-5554 device product:sdk_gphone16k_arm64 model:sdk_gphone16k_arm64 device:emu64a16k
```

Device properties observed:

- API level: `36`
- Android release: `16`
- Physical size: `1080x2400`
- MemTotal: `2047232 kB` (about 1999 MiB)

`app/build/outputs/androidTest-results/connected/debug/TEST-Medium_Phone(AVD) - 16-_app-.xml`
contains 4 tests, 0 failures, 0 errors, 0 skipped:

- `MainActivityIntentContractTest.markdownViewIntentResolvesToExportedMainActivity`
- `MainActivityIntentContractTest.sharedTextIntentResolvesToExportedMainActivity`
- `MainActivityIntentContractTest.launcherIntentResolvesToExportedMainActivity`
- `MainActivityReaderScenarioTest.sharedMarkdownReaderSupportsRenderSearchAndFontTierOnConstrainedRuntime`

## Performance Report Evidence

`stage1AndroidPerformanceReport` ran `auditPerformanceReport` successfully.
The audit confirmed:

- document load/save IO is dispatched off the main thread;
- Markdown parse/search work uses `Dispatchers.Default`;
- local image decode uses `Dispatchers.IO`;
- reader rendering is virtualized with stable block ids;
- remote media is disabled by default in all Android runtime profiles;
- diagnostics expose redacted parse/render/search/save timing fields.

Profile limits printed by the task:

| Profile | Soft Limit Bytes |
| --- | ---: |
| `WatchCompact` | 262144 |
| `LegacyEfficient` | 1048576 |
| `ModernStandard` | 5242880 |
| `LargeScreen` | 5242880 |

Fixture matrix printed by the task:

| Fixture | Bytes | Lines |
| --- | ---: | ---: |
| `basic.md` | 124 | 7 |
| `rich-preview.md` | 5050 | 246 |
| `long-1mb.md` | 328 | 10 |
| `large-5mb.md` | 296 | 8 |
| `huge-table.md` | 333 | 9 |
| `huge-code-block.md` | 176 | 11 |
| `remote-image.md` | 148 | 5 |
| `local-image.md` | 142 | 5 |

## Remaining Blocker

Android API 27 runtime validation remains blocked:

- `tools/device_validation_preflight.sh` reports no Android API 27 system image
  under `/Users/wangweiyang/Library/Android/sdk/system-images`.
- The attached `Medium_Phone` AVD is API 36, not API 27.

## Supervisor Checklist Recommendation

The supervising session can use this report as Android-lane evidence for marking
these L12 Android checklist items complete:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android low-memory/small-screen profile validation, if the API 36
  `Medium_Phone` AVD with about 1999 MiB RAM is accepted for the low-memory side
  of this checklist item.
- Run Android modern device validation, using the API 36 `Medium_Phone` AVD
  connected instrumentation run.
- Capture Android performance report.

Keep Android API 27 validation open until an API 27 emulator or real Android 8.1
device is installed, booted, and validated.
