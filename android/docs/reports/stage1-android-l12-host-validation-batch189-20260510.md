# Stage 1 Android L12 Host Validation Batch 189 - 2026-05-10

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
platform validation items that can run on the local host:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Capture Android performance report.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android product source changes were required. The only intentional repository
write in this batch is this Android-local evidence report.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-host-validation-batch189-20260510.md`

Gradle also refreshed generated Android-local build outputs under ignored
`build/` directories while running validation.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-10 CST.

- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Android SDK path from `local.properties`:
  `/Users/wangweiyang/Library/Android/sdk`.
- Explicit JDK used for the final host validation pass:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
- Explicit Java version:
  `openjdk version "17.0.17" 2025-10-21`.
- Android Studio bundled JBR also exists at:
  `/Applications/Android Studio.app/Contents/jbr/Contents/Home`.
- The default shell still does not expose Java through macOS discovery:
  `java -version` reports `Unable to locate a Java Runtime`.

The final passing Gradle commands used this scoped environment:

```bash
JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
PATH=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin:$PATH
```

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED without scoped env | macOS reported `Unable to locate a Java Runtime`; Gradle cannot start from the default shell Java discovery. |
| `JAVA_HOME=/Applications/Android Studio.app/Contents/jbr/Contents/Home ./gradlew projects --no-daemon` | PASS | Project discovery completed with `BUILD SUCCESSFUL in 4s` and listed `:app`, `:core`, `:feature:reader`, `:feature:library`, and `:feature:settings`. |
| `JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home java -version` | PASS | Reported OpenJDK `17.0.17` from Homebrew. |
| `JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home ./gradlew lint build :core:testDebugUnitTest :feature:reader:testDebugUnitTest :app:assembleDebug --no-daemon` | PASS | `BUILD SUCCESSFUL in 3m 40s`; `474 actionable tasks: 61 executed, 413 up-to-date`. This covered lint, full build, app/core/reader host unit tests, debug/release assembly, and Stage 1 renderer asset/request-blocking audit gates. |
| `JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home ./gradlew stage1AndroidPerformanceReport --no-daemon` | PASS | `BUILD SUCCESSFUL in 20s`; `auditPerformanceReport` printed Android profile limits, fixture matrix, and `PASS: Android performance report audit completed.` |
| `/Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices -l` | BLOCKED for connected/device validation | `adb` is installed, but output contained only `List of devices attached` with no device rows. |
| `JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home ./gradlew projects --no-daemon --console=plain` after `./gradlew --stop` | NON-GATING ANOMALY | Retried only for a JDK 17 project-discovery refresh after the real host gates passed; it failed with `Gradle build daemon has been stopped: stop command received`. No completion claim depends on this retry. |

Gradle printed its standard non-failing deprecation warning in passing commands:

```text
Deprecated Gradle features were used in this build, making it incompatible with Gradle 10.
```

## Host Unit Test Evidence

JUnit XML under `build/test-results/testDebugUnitTest` reports zero failures,
zero errors, and zero skipped tests for the host suites refreshed by this batch:

| Suite | Tests | Failures | Errors | Skipped |
| --- | ---: | ---: | ---: | ---: |
| `FastMdReaderSessionViewModelTest` | 15 | 0 | 0 | 0 |
| `CoreContractsTest` | 15 | 0 | 0 | 0 |
| `MarkdownDocumentTest` | 1 | 0 | 0 | 0 |
| `MarkdownSaveIntegrityTest` | 6 | 0 | 0 | 0 |
| `StructuredMarkdownParserTest` | 12 | 0 | 0 | 0 |
| `BlockSourceEditTest` | 2 | 0 | 0 | 0 |
| `RichRendererAssetPolicyTest` | 24 | 0 | 0 | 0 |
| `ReaderSearchEngineTest` | 4 | 0 | 0 | 0 |
| `ReaderSearchHighlightPlannerTest` | 3 | 0 | 0 | 0 |

Total observed host unit-test coverage in this batch: 82 tests, 0 failures,
0 errors, 0 skipped.

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
device-backed API 27, low-memory/small-screen, or modern-device runtime
validation.

## Generated Evidence Artifacts

- Debug APK:
  `android/app/build/outputs/apk/debug/app-debug.apk` (`9.3M`)
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

## Remaining Device Validation Blocker

Keep these Android L12 checklist items open until a device-backed report covers
them:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

Current local blocker:

- `/Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices -l`
  reports no attached Android device or running emulator.

## Supervisor Checklist Recommendation

The supervising session can use this report as fresh Android-lane evidence for
marking these L12 checklist items complete:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Capture Android performance report.

Do not use this report to newly claim completion for connected-device, API 27
runtime, low-memory/small-screen runtime, or modern-device runtime validation.
