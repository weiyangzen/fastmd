# Stage 1 Android L12 Host Gradle Validation Batch 167 - 2026-05-10

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
platform validation items from `Docs/Stage1_Mobile_Blueprint.md` and
`Docs/todos_20260506.md`.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android product source changes were required. The only intentional repository
write in this batch is this Android-local evidence report.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-host-gradle-validation-batch167-20260510.md`

Gradle also refreshed Android-local generated build metadata and reports under
ignored `build/` directories while running validation.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-10 CST.

- Gradle entry point: checked-in wrapper `./gradlew`.
- Android SDK path: `/Users/wangweiyang/Library/Android/sdk`.
- Default shell Java: blocked by macOS Java registration.
- Explicit JDK used for passing Gradle validation:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
- Explicit Java version:
  `openjdk version "17.0.17" 2025-10-21`.
- Maven mirror opt-in used for Gradle commands:
  `-Pfastmd.useChinaMavenMirror=true`.

The default shell Java command still fails before Gradle can start:

```text
The operation couldn't be completed. Unable to locate a Java Runtime.
Please visit http://www.java.com for information on installing Java.
```

The checked-in Gradle wrapper works when `JAVA_HOME` and `PATH` are scoped to
the available Homebrew OpenJDK 17 installation.

## Validation Results

Passing Gradle commands below used this environment prefix:

```bash
JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home \
PATH=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin:$PATH \
ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk \
ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk
```

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED | macOS reported `Unable to locate a Java Runtime`. |
| `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported OpenJDK `17.0.17`. |
| `./gradlew projects --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true` | PASS | `BUILD SUCCESSFUL in 13s`; module graph includes `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `./gradlew lint build :core:testDebugUnitTest :feature:reader:testDebugUnitTest :app:assembleDebug --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true` | PASS | `BUILD SUCCESSFUL in 2m 17s`; `474 actionable tasks: 14 executed, 460 up-to-date`. |
| `/Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices -l` | BLOCKED for device validation | Printed only `List of devices attached`; no device rows. |
| `/Users/wangweiyang/Library/Android/sdk/emulator/emulator -list-avds` | PARTIAL | Printed `Medium_Phone`; no emulator was booted in this batch. |
| `ANDROID_HOME=... ANDROID_SDK_ROOT=... bash tools/device_validation_preflight.sh` | BLOCKED | Found 5 blockers: no attached device/emulator, no API 27 system image, no attached API 27 target, no low-memory target, and no attached API 34+ target. |

Gradle printed its standard non-failing deprecation warning:

```text
Deprecated Gradle features were used in this build, making it incompatible with Gradle 10.
```

## Host Gate Coverage

The successful host Gradle run covers these Android L12 checklist items:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.

The root `build` task also ran the Android Stage 1 renderer asset/request
blocking audit gates wired into `check`; those gates passed without WebView,
web-runtime, remote-subresource, dynamic-code, or renderer request-policy
violations.

## Generated Evidence Artifacts

Representative Android-local artifacts present after this batch:

- `android/app/build/outputs/apk/debug/app-debug.apk`
- `android/app/build/reports/lint-results-debug.html`
- `android/core/build/reports/lint-results-debug.html`
- `android/feature/library/build/reports/lint-results-debug.html`
- `android/feature/reader/build/reports/lint-results-debug.html`
- `android/feature/settings/build/reports/lint-results-debug.html`
- `android/app/build/reports/tests/testDebugUnitTest/index.html`
- `android/core/build/reports/tests/testDebugUnitTest/index.html`
- `android/feature/reader/build/reports/tests/testDebugUnitTest/index.html`
- `android/build/reports/problems/problems-report.html`

Available debug unit-test XML under `build/test-results/testDebugUnitTest`
summarizes to:

```text
tests=82 skipped=0 failures=0 errors=0
```

## Remaining Device Validation Blockers

Keep these Android L12 checklist items open until separate device-backed
evidence exists:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

Current blockers:

- No Android device or running emulator is attached.
- Only one AVD is listed: `Medium_Phone`; it was not booted in this batch.
- No Android API 27 system image is installed under
  `/Users/wangweiyang/Library/Android/sdk/system-images`.
- The preflight did not detect any attached low-memory target.
- The preflight did not detect any attached API 34+ target.

## Supervisor Checklist Recommendation

The supervising session can use this report as fresh Android-lane evidence for
marking these L12 Android checklist items complete if not already reconciled:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.

Do not use this report to newly claim completion for connected-device, API 27
runtime, low-memory/small-screen runtime, modern-device runtime, or Android
performance report items.
