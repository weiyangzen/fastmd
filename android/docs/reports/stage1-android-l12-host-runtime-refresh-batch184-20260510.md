# Stage 1 Android L12 Host Runtime Refresh - Batch 184

Date: 2026-05-10 09:21 CST

Worker scope: Android live lane, `android/**` only.

## Batch Selection

The authoritative blueprint and daily todo snapshot leave Android L12 platform
validation as the earliest Android-owned open cluster. Earlier Android reports
already include implementation evidence for L2-L11 and several L12 passes, so
this bounded batch refreshed the current Android host validation state and the
current device/runtime blocker state without touching shared checklist files.

No Android product source changes were required. No `ios/**`, shared `Docs/**`,
or `.cron/**` files were edited.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-host-runtime-refresh-batch184-20260510.md`

Gradle also refreshed generated Android-local build outputs under ignored
`build/` directories while running validation.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android`.

- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Default shell Java remains blocked by macOS Java registration.
- Explicit JDK used for Gradle commands:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
- Explicit Java version: OpenJDK `17.0.17` (`Homebrew 17.0.17+0`).
- Android SDK path: `/Users/wangweiyang/Library/Android/sdk`.
- Maven resolution used local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.
- Installed SDK platforms observed: API 31, 32, 33, 34, 35, and 36.
- Installed system images observed: Android 36 only.
- Available AVD observed: `Medium_Phone`.
- Attached Android devices at validation time: none.
- SDK command-line tools blocker: no
  `/Users/wangweiyang/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager`
  or `avdmanager` binary is installed.

Passing Gradle commands used this scoped environment:

```bash
JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
PATH=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin:$PATH
ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk
ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk
```

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported OpenJDK `17.0.17`. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true projects` | PASS | `BUILD SUCCESSFUL in 13s`; module graph listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true lint build :core:testDebugUnitTest :feature:reader:testDebugUnitTest :app:assembleDebug stage1AndroidPerformanceReport` | PASS | `BUILD SUCCESSFUL in 2m 14s`; `475 actionable tasks: 15 executed, 460 up-to-date`. Covered Android lint, full build, core debug unit tests, reader debug unit tests, debug app assembly, renderer security gates wired through `check`, and source-level Android performance report capture. |
| `/Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices -l` | BLOCKED for device validation | Printed only `List of devices attached`; no device rows. |
| `bash tools/device_validation_preflight.sh` with Android SDK env | BLOCKED | Reported 5 blockers: no attached device/emulator, no API 27 system image, no attached API 27 target, no low-memory/small-screen target, and no attached API 34+ modern target. |
| `./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true :app:connectedDebugAndroidTest` | BLOCKED / FAIL | Debug app and androidTest APK preparation completed, then `:app:connectedDebugAndroidTest` failed with `DeviceException: No connected devices!`; `BUILD FAILED in 19s`; `152 actionable tasks: 6 executed, 146 up-to-date`. |
| `find /Users/wangweiyang/Library/Android/sdk/platforms -maxdepth 1 -type d -name 'android-*'` | PARTIAL | Installed platforms are API 31 through API 36; no API 27 platform is installed. |
| `find /Users/wangweiyang/Library/Android/sdk/system-images -maxdepth 4 -type d` | PARTIAL | Installed system images are Android 36 only. No Android API 27 system image is installed. |
| `/Users/wangweiyang/Library/Android/sdk/emulator/emulator -list-avds` | PARTIAL | Listed one AVD: `Medium_Phone`; no emulator was running for this batch. |
| `ls -l /Users/wangweiyang/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager /Users/wangweiyang/Library/Android/sdk/cmdline-tools/latest/bin/avdmanager` | BLOCKED | Both expected SDK command-line tools are missing at that path, so this batch could not install API 27 tooling or create an API 27 emulator. |

Gradle printed its standard non-failing deprecation warning about future Gradle
10 compatibility during wrapper-backed commands.

## Performance Report Output

`stage1AndroidPerformanceReport` printed:

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

This is source-level Android performance posture evidence. It does not replace
real device performance validation for API 27, low-memory/small-screen, or
modern-device profiles.

## Unit Test Evidence

The selected unit-test tasks were up-to-date in this run, and generated XML
under `build/test-results/testDebugUnitTest` summarizes to:

```text
tests=82 skipped=0 failures=0 errors=0
```

JUnit XML files observed:

- `app/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.session.FastMdReaderSessionViewModelTest.xml`
- `core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.contracts.CoreContractsTest.xml`
- `core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.document.MarkdownDocumentTest.xml`
- `core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.document.MarkdownSaveIntegrityTest.xml`
- `core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.markdown.StructuredMarkdownParserTest.xml`
- `core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.reader.BlockSourceEditTest.xml`
- `core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.render.RichRendererAssetPolicyTest.xml`
- `core/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.core.search.ReaderSearchEngineTest.xml`
- `feature/reader/build/test-results/testDebugUnitTest/TEST-com.fastmd.mobile.feature.reader.ReaderSearchHighlightPlannerTest.xml`

## Generated Android-Local Artifacts

- Debug APK:
  `android/app/build/outputs/apk/debug/app-debug.apk` (`9.3M`)
- Android test APK:
  `android/app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk`
  (`945K`)
- Release unsigned APK:
  `android/app/build/outputs/apk/release/app-release-unsigned.apk` (`1.1M`)
- App lint report:
  `android/app/build/reports/lint-results-debug.html`
- Core lint report:
  `android/core/build/reports/lint-results-debug.html`
- Reader lint report:
  `android/feature/reader/build/reports/lint-results-debug.html`
- Library lint report:
  `android/feature/library/build/reports/lint-results-debug.html`
- Settings lint report:
  `android/feature/settings/build/reports/lint-results-debug.html`
- App unit-test report:
  `android/app/build/reports/tests/testDebugUnitTest/index.html`
- Core unit-test report:
  `android/core/build/reports/tests/testDebugUnitTest/index.html`
- Reader unit-test report:
  `android/feature/reader/build/reports/tests/testDebugUnitTest/index.html`
- Gradle problems report:
  `android/build/reports/problems/problems-report.html`

## Current Device Validation Blockers

Keep these Android L12 checklist items open until a device-backed report covers
them:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

Current blockers:

- No Android device or booted emulator is attached.
- `Medium_Phone` is the only listed AVD and was not booted in this batch.
- No Android API 27 platform is installed under
  `/Users/wangweiyang/Library/Android/sdk/platforms`.
- No Android API 27 system image is installed under
  `/Users/wangweiyang/Library/Android/sdk/system-images`.
- The expected SDK command-line tools `sdkmanager` and `avdmanager` paths are
  absent, so this batch could not install missing API 27 tooling or create a
  matching API 27 emulator.
- No attached API 27, low-memory/small-screen, or API 34+ modern runtime was
  available during this batch.

## Checklist Evidence For Supervisor

The supervising session can use this report as current Android-lane evidence
for marking these L12 checklist items complete, if not already reconciled:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Capture Android performance report.

Do not use this report to newly mark connected/device-backed runtime validation
complete. The current runtime state is blocked for the reasons listed above.
