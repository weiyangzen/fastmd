# Stage 1 Android L12 Host Validation Batch 181 - 2026-05-10

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
platform validation items in `Docs/Stage1_Mobile_Blueprint.md` and
`Docs/todos_20260506.md`.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android product source changes were required. The only intentional repository
write in this batch is this Android-local evidence report.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-host-validation-batch181-20260510.md`

Gradle also refreshed Android-local generated build metadata, lint reports, test
reports, APK outputs, and the Gradle problems report under generated `build/`
directories while running validation.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-10 CST.

- Timestamp captured by `date`: `2026-05-10 08:56:56 CST +0800`.
- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Default shell `java -version`: blocked by macOS Java registration with
  `Unable to locate a Java Runtime`.
- Explicit JDK used for passing Gradle commands:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
- Explicit Java version: OpenJDK `17.0.17` (`Homebrew 17.0.17+0`).
- Android SDK path: `/Users/wangweiyang/Library/Android/sdk`.
- Maven mirror opt-in used for Gradle commands:
  `-Pfastmd.useChinaMavenMirror=true`.
- Free space on the shared SDK/worktree volume: `4.2 GiB`.

Passing Gradle commands used this scoped environment:

```bash
JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home \
PATH=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin:$PATH \
ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk \
ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk
```

Installed Android platforms observed:

```text
/Users/wangweiyang/Library/Android/sdk/platforms/android-31
/Users/wangweiyang/Library/Android/sdk/platforms/android-32
/Users/wangweiyang/Library/Android/sdk/platforms/android-33
/Users/wangweiyang/Library/Android/sdk/platforms/android-34
/Users/wangweiyang/Library/Android/sdk/platforms/android-35
/Users/wangweiyang/Library/Android/sdk/platforms/android-36
```

Installed Android system images observed:

```text
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis/arm64-v8a
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore/arm64-v8a
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore_ps16k/arm64-v8a
```

No Android API 27 platform or system image is installed locally.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED | macOS reported `Unable to locate a Java Runtime`. |
| `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported OpenJDK `17.0.17`. |
| `./gradlew projects --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true` with explicit JDK 17 and SDK env | PASS | `BUILD SUCCESSFUL in 13s`; confirmed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `./gradlew lint build :core:testDebugUnitTest :feature:reader:testDebugUnitTest :app:assembleDebug stage1AndroidPerformanceReport --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true` with explicit JDK 17 and SDK env | PASS | `BUILD SUCCESSFUL in 2m 18s`; `475 actionable tasks: 15 executed, 460 up-to-date`. |
| `/Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices -l` | BLOCKED for device validation | Printed only `List of devices attached`; no device rows. |
| `bash tools/device_validation_preflight.sh` with explicit JDK 17 and SDK env | BLOCKED | Found 5 blockers: no attached Android device/emulator, no API 27 system image, no attached API 27 target, no low-memory target currently attached, and no API 34+ target currently attached. |
| `./gradlew :app:connectedDebugAndroidTest --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true` with explicit JDK 17 and SDK env | BLOCKED | Built instrumentation inputs, then failed at `:app:connectedDebugAndroidTest` with `DeviceException: No connected devices!`. |
| `command -v sdkmanager` and expected SDK `cmdline-tools/latest/bin/sdkmanager` check | BLOCKED | No `sdkmanager` executable found. |
| `command -v avdmanager` and expected SDK `cmdline-tools/latest/bin/avdmanager` check | BLOCKED | No `avdmanager` executable found. |

Gradle printed the standard non-failing deprecation warning during Gradle
commands:

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
- Capture Android performance report.

The root `build` task also ran the Stage 1 renderer asset and request-blocking
audit gates wired into `check`; those gates passed without WebView,
web-runtime, remote-subresource, dynamic-code, or renderer request-policy
violations.

Generated debug unit-test XML under `build/test-results/testDebugUnitTest`
summarizes to:

```text
tests=82 skipped=0 failures=0 errors=0
```

Debug unit-test XML was present for:

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
- `android/app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk`
  (`948K`)
- `android/app/build/outputs/apk/release/app-release-unsigned.apk` (`1.1M`)
- `android/app/build/reports/lint-results-debug.html`
- `android/core/build/reports/lint-results-debug.html`
- `android/feature/reader/build/reports/lint-results-debug.html`
- `android/app/build/reports/tests/testDebugUnitTest/index.html`
- `android/core/build/reports/tests/testDebugUnitTest/index.html`
- `android/feature/reader/build/reports/tests/testDebugUnitTest/index.html`
- `android/build/reports/problems/problems-report.html`

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

## Device Preflight Output

`tools/device_validation_preflight.sh` reported:

```text
== Android Device Validation Preflight ==
INFO: Android project: /Users/wangweiyang/GitHub/fastmd/android
INFO: Android SDK: /Users/wangweiyang/Library/Android/sdk
INFO: JAVA_HOME: /usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home

== ADB Devices ==
List of devices attached

BLOCKED: No attached Android device or booted emulator is available for connectedDebugAndroidTest.

== System Images ==
/Users/wangweiyang/Library/Android/sdk/system-images
/Users/wangweiyang/Library/Android/sdk/system-images/android-36
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis/arm64-v8a
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis/arm64-v8a/data
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore/arm64-v8a
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore/arm64-v8a/data
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore_ps16k
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore_ps16k/arm64-v8a
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore_ps16k/arm64-v8a/data
BLOCKED: No Android API 27 system image is installed under /Users/wangweiyang/Library/Android/sdk/system-images.

== AVDs ==
Medium_Phone

== Checklist Readiness ==
BLOCKED: No attached API 27 device/emulator is ready for Android 8.1 validation.
BLOCKED: No attached low-memory device/emulator was detected for low-memory/small-screen validation.
BLOCKED: No attached API 34+ device/emulator is ready for modern-device validation.

== Summary ==
BLOCKED: Android device validation preflight found 5 blocker(s).
```

`./gradlew :app:connectedDebugAndroidTest` failed with:

```text
Execution failed for task ':app:connectedDebugAndroidTest'.
> com.android.builder.testing.api.DeviceException: No connected devices!
```

## Runtime Validation Status

Runtime-backed Android L12 items remain open until separate device-backed
evidence exists:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

This batch intentionally does not claim those runtime items because no Android
device or booted emulator was attached, no API 27 system image is installed, and
local SDK command-line tooling for creating/installing AVD targets is missing.

## Supervisor Checklist Recommendation

The supervising session can use this report as Android-lane evidence for marking
these L12 Android checklist items complete if they have not already been
reconciled:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Capture Android performance report.

Do not use this report to newly claim completion for connected-device, API 27
runtime, low-memory/small-screen runtime, or modern-device runtime validation.
