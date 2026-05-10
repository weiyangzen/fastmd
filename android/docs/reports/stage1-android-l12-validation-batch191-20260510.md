# Stage 1 Android L12 Validation Batch 191 - 2026-05-10

## Scope

Android live-lane bounded validation batch for the earliest still-open
Android-owned L12 checklist items in `Docs/Stage1_Mobile_Blueprint.md` and
`Docs/todos_20260506.md`.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android product source changes were required. The only intentional repository
write is this Android-local evidence report.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-validation-batch191-20260510.md`

Gradle also refreshed generated Android-local build outputs under ignored
`android/**/build/` directories while running validation.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-10 CST.

- Checked-in Gradle wrapper: `./gradlew`, Gradle `9.3.0`.
- Android SDK from `local.properties`: `/Users/wangweiyang/Library/Android/sdk`.
- Explicit JDK 17 used for passing Gradle commands:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
- Explicit Java version: OpenJDK `17.0.17`.
- Maven mirror opt-in: `-Pfastmd.useChinaMavenMirror=true`.

The default shell still does not expose Java through macOS discovery:

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
| `java -version` | BLOCKED without scoped env | macOS reported no discoverable Java runtime. |
| `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported OpenJDK `17.0.17`. |
| `sed -n '1,80p' local.properties` | PASS | Confirmed `sdk.dir=/Users/wangweiyang/Library/Android/sdk`. |
| `adb devices -l` | PASS | Found attached `emulator-5554` with model `sdk_gphone16k_arm64`. |
| `./gradlew projects lint :core:testDebugUnitTest :feature:reader:testDebugUnitTest :app:assembleDebug stage1AndroidPerformanceReport` with scoped JDK/SDK env | PASS | `BUILD SUCCESSFUL in 26s`; project graph contains `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; lint, the two requested unit-test modules, debug assemble, and performance audit passed. |
| `./gradlew build` with scoped JDK/SDK env | PASS | `BUILD SUCCESSFUL in 2m 24s`; covered app/core/feature build, host unit tests, lint, release/debug assembly, and Android renderer asset/request-blocking audit gates. |
| `./gradlew :app:connectedDebugAndroidTest` with scoped JDK/SDK env | PASS | `BUILD SUCCESSFUL in 33s`; ran 4 tests on `Medium_Phone(AVD) - 16` with zero failures. |
| `bash tools/device_validation_preflight.sh` | BLOCKED for API 27 only | Found one attached API 36 emulator and reported low-memory and modern-device readiness, but no Android API 27 system image is installed. |

Gradle printed its standard non-failing deprecation warning in passing commands:

```text
Deprecated Gradle features were used in this build, making it incompatible with Gradle 10.
```

## Host Unit Test Evidence

JUnit XML under `core/build/test-results/testDebugUnitTest` and
`feature/reader/build/test-results/testDebugUnitTest` reported:

| Suite | Tests | Failures | Errors | Skipped |
| --- | ---: | ---: | ---: | ---: |
| `CoreContractsTest` | 15 | 0 | 0 | 0 |
| `MarkdownDocumentTest` | 1 | 0 | 0 | 0 |
| `MarkdownSaveIntegrityTest` | 6 | 0 | 0 | 0 |
| `StructuredMarkdownParserTest` | 12 | 0 | 0 | 0 |
| `BlockSourceEditTest` | 2 | 0 | 0 | 0 |
| `RichRendererAssetPolicyTest` | 24 | 0 | 0 | 0 |
| `ReaderSearchEngineTest` | 4 | 0 | 0 | 0 |
| `ReaderSearchHighlightPlannerTest` | 3 | 0 | 0 | 0 |

Observed host suite total for the explicitly requested core and reader modules:
67 tests, 0 failures, 0 errors, 0 skipped.

## Connected Device Evidence

`adb devices -l` reported:

```text
emulator-5554 device product:sdk_gphone16k_arm64 model:sdk_gphone16k_arm64 device:emu64a16k
```

Observed device properties:

- API level: `36`
- Android release: `16`
- Physical size: `1080x2400`
- MemTotal: `2047232 kB` (about 1999 MiB)
- MemAvailable at probe time: `374624 kB`

`app/build/outputs/androidTest-results/connected/debug/TEST-Medium_Phone(AVD) - 16-_app-.xml`
reported 4 tests, 0 failures, 0 errors, 0 skipped:

- `MainActivityIntentContractTest.markdownViewIntentResolvesToExportedMainActivity`
- `MainActivityIntentContractTest.sharedTextIntentResolvesToExportedMainActivity`
- `MainActivityIntentContractTest.launcherIntentResolvesToExportedMainActivity`
- `MainActivityReaderScenarioTest.sharedMarkdownReaderSupportsRenderSearchAndFontTierOnConstrainedRuntime`

This is valid connected instrumentation evidence for the currently attached
modern API 36 emulator. It does not satisfy the Android API 27 validation item.

## Device Preflight Evidence

`tools/device_validation_preflight.sh` reported:

- PASS: Found 1 attached Android device.
- DEVICE: `serial=emulator-5554 api=36 model="Google sdk_gphone16k_arm64" size=1080x2400 memMb=1999`.
- BLOCKED: No Android API 27 system image is installed under
  `/Users/wangweiyang/Library/Android/sdk/system-images`.
- PASS: An attached low-memory device/emulator is ready for small-screen or
  low-memory validation.
- PASS: An attached API 34+ device/emulator is ready for modern-device validation.
- Summary: Android device validation preflight found 2 blockers, both tied to
  missing API 27 runtime coverage.

Installed system image families observed by the preflight:

- `android-36/google_apis/arm64-v8a`
- `android-36/google_apis_playstore/arm64-v8a`
- `android-36/google_apis_playstore_ps16k/arm64-v8a`

## Performance Report Evidence

`stage1AndroidPerformanceReport` ran `auditPerformanceReport` successfully.
The task printed:

```text
Android performance profile limits:
  WatchCompact softLimitBytes=262144
  LegacyEfficient softLimitBytes=1048576
  ModernStandard softLimitBytes=5242880
  LargeScreen softLimitBytes=5242880
Android fixture size matrix:
  basic.md bytes=124 lines=7
  rich-preview.md bytes=5050 lines=246
  long-1mb.md bytes=328 lines=10
  large-5mb.md bytes=296 lines=8
  huge-table.md bytes=333 lines=9
  huge-code-block.md bytes=176 lines=11
  remote-image.md bytes=148 lines=5
  local-image.md bytes=142 lines=5
PASS: Android performance report audit completed.
```

The source-level performance audit confirmed the Android Stage 1 profile limits
and fixture matrix. Runtime performance coverage in this batch is limited to the
connected API 36 emulator instrumentation scenario above.

## Generated Evidence Artifacts

- Debug APK: `android/app/build/outputs/apk/debug/app-debug.apk` (`9.3M`)
- Release unsigned APK:
  `android/app/build/outputs/apk/release/app-release-unsigned.apk` (`1.1M`)
- App lint report: `android/app/build/reports/lint-results-debug.html`
- Core lint report: `android/core/build/reports/lint-results-debug.html`
- Reader lint report:
  `android/feature/reader/build/reports/lint-results-debug.html`
- Library lint report:
  `android/feature/library/build/reports/lint-results-debug.html`
- Settings lint report:
  `android/feature/settings/build/reports/lint-results-debug.html`
- Connected instrumentation XML:
  `android/app/build/outputs/androidTest-results/connected/debug/TEST-Medium_Phone(AVD) - 16-_app-.xml`
- Gradle problems report:
  `android/build/reports/problems/problems-report.html`

## Remaining Blocker

Keep Android API 27 validation open.

Current blocker:

- No Android API 27 system image is installed under
  `/Users/wangweiyang/Library/Android/sdk/system-images`.
- The only attached runtime is `emulator-5554`, API 36 / Android 16.

## Supervisor Checklist Recommendation

The supervising session can use this report as fresh Android-lane evidence for
marking these L12 Android checklist items complete:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android low-memory/small-screen profile validation, if the attached
  API 36 `Medium_Phone` AVD with about 1999 MiB RAM and the constrained reader
  instrumentation scenario is accepted for this checklist item.
- Run Android modern device validation, using the API 36 connected
  instrumentation run.
- Capture Android performance report.

Do not use this report to mark Android API 27 validation complete.
