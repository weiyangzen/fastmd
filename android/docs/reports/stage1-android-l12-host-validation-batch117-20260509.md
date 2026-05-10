# Stage 1 Android L12 Host Validation Batch 117 - 2026-05-09

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
platform validation items from `Docs/todos_20260506.md`:

- Run Android `./gradlew lint`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Capture Android performance report.
- Refresh minimum Android Gradle project sanity evidence with `./gradlew projects`.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android product source changes were made. The only repository write in this
batch is this Android-local evidence report.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-host-validation-batch117-20260509.md`

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-09.

- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Explicit JDK:
  `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`.
- Explicit Java version:
  `openjdk version "17.0.17" 2025-10-21`.
- Android SDK path:
  `/Users/wangweiyang/Library/Android/sdk`.
- Maven resolution used local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home java -version` | PASS | Reported Homebrew OpenJDK `17.0.17`. |
| `JAVA_HOME=... ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true projects :core:testDebugUnitTest :feature:reader:testDebugUnitTest :app:assembleDebug stage1AndroidPerformanceReport lint --stacktrace` | PASS | Project graph, core unit tests, reader unit tests, debug APK assembly, source-level performance report, and lint completed; Gradle reported `BUILD SUCCESSFUL in 30s` with `241 actionable tasks: 12 executed, 229 up-to-date`. |
| `ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk /Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices -l` | BLOCKED for device work | Printed `List of devices attached` with no attached device rows. |
| `ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk /Users/wangweiyang/Library/Android/sdk/emulator/emulator -list-avds` | PASS | Listed one AVD: `Medium_Phone`. |
| `find /Users/wangweiyang/Library/Android/sdk/system-images -maxdepth 4 -type d \| sort` | BLOCKED for API 27 validation | Installed system images are Android 36 only; no Android API 27 system image is installed. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... bash tools/device_validation_preflight.sh` | BLOCKED | Preflight found 5 blockers: no attached Android device or booted emulator; no API 27 system image; no attached API 27 target; no low-memory/small-screen target; no API 34+ target. |

## Gradle Host-Gate Details

`./gradlew projects` listed the expected Android project graph:

- `:app`
- `:core`
- `:feature:library`
- `:feature:reader`
- `:feature:settings`

The combined host-side Gradle command completed these L12-relevant tasks:

- `:core:testDebugUnitTest`
- `:feature:reader:testDebugUnitTest`
- `:app:assembleDebug`
- `stage1AndroidPerformanceReport`
- `lint`

Gradle printed its standard deprecation warning:

- Deprecated Gradle features were used in this build, making it incompatible
  with Gradle 10.

This warning did not fail the validation command.

## Performance Report Output

`stage1AndroidPerformanceReport` completed and printed the source-level Android
performance posture:

| Profile | Soft Limit Bytes |
| --- | ---: |
| WatchCompact | 262144 |
| LegacyEfficient | 1048576 |
| ModernStandard | 5242880 |
| LargeScreen | 5242880 |

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

The performance report remains source-level Android evidence. It does not
replace API 27 device/emulator timing, low-memory/small-screen runtime
validation, or modern-device runtime validation.

## Android-Local Evidence Artifacts

Relevant Android-local artifacts after this batch:

- `android/app/build/reports/lint-results-debug.html`
- `android/app/build/reports/lint-results-debug.xml`
- `android/core/build/reports/lint-results-debug.html`
- `android/core/build/reports/lint-results-debug.xml`
- `android/feature/reader/build/reports/lint-results-debug.html`
- `android/feature/reader/build/reports/lint-results-debug.xml`
- `android/feature/library/build/reports/lint-results-debug.html`
- `android/feature/library/build/reports/lint-results-debug.xml`
- `android/feature/settings/build/reports/lint-results-debug.html`
- `android/feature/settings/build/reports/lint-results-debug.xml`
- `android/core/build/test-results/testDebugUnitTest/`
- `android/feature/reader/build/test-results/testDebugUnitTest/`
- `android/app/build/outputs/apk/debug/app-debug.apk`
- `android/build/reports/problems/problems-report.html`

## Remaining Runtime Blockers

Runtime/device validation remains blocked in the current local environment:

- `adb devices -l` lists no attached Android device or booted emulator.
- The SDK has Android 36 system images only under
  `/Users/wangweiyang/Library/Android/sdk/system-images`.
- No Android API 27 system image is installed, so Android 8.1/API 27 validation
  cannot run locally.
- No attached API 27 device/emulator is ready for Android 8.1 validation.
- No attached low-memory or small-screen device/emulator was detected.
- No attached API 34+ device/emulator is ready for modern-device validation.

## Supervisor Checklist Recommendation

The supervising session can use this report as fresh Android-lane evidence for
marking these Android L12 checklist items complete:

- Run Android `./gradlew lint`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Capture Android performance report.

Use this report as minimum Android validation sanity evidence for:

- `./gradlew projects`.

Keep these L12 runtime/device items open until a matching device or booted
emulator is available:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

This batch did not run `./gradlew build`; the current report is scoped to the
host-side validation cluster listed above.
