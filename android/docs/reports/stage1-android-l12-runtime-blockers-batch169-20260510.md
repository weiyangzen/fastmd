# Stage 1 Android L12 Runtime Blockers Batch 169 - 2026-05-10

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
platform validation surface in `Docs/Stage1_Mobile_Blueprint.md` and
`Docs/todos_20260506.md`.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android product source changes were required. The only intentional repository
write in this batch is this Android-local evidence report.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-runtime-blockers-batch169-20260510.md`

Gradle also refreshed Android-local generated build metadata and lint/build
outputs under ignored `build/` directories while running validation.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-10 around 07:19 CST.

- Gradle entry point: checked-in wrapper `./gradlew`.
- Android SDK path: `/Users/wangweiyang/Library/Android/sdk`.
- Maven mirror opt-in used for Gradle commands:
  `-Pfastmd.useChinaMavenMirror=true`.
- Default shell Java remains blocked by macOS Java registration.
- Explicit JDK used for passing Gradle commands:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
- Explicit Java version: OpenJDK `17.0.17`.
- Installed Android SDK platforms: API 31, 32, 33, 34, 35, and 36.
- Installed Android system images: Android 36 only.
- Local SDK manager blocker:
  `/Users/wangweiyang/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager`
  is missing.

Passing Gradle commands used this scoped environment:

```bash
JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home \
PATH=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin:$PATH \
ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk \
ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk
```

The default shell Java command still fails before Gradle can start:

```text
The operation couldn't be completed. Unable to locate a Java Runtime.
Please visit http://www.java.com for information on installing Java.
```

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `date '+%Y-%m-%d %H:%M:%S %Z %z'` | PASS | Printed `2026-05-10 07:19:44 CST +0800`. |
| `java -version` | BLOCKED | macOS reported `Unable to locate a Java Runtime`. |
| `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported OpenJDK `17.0.17`. |
| `./gradlew projects --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true` with explicit JDK 17 and SDK env | PASS | `BUILD SUCCESSFUL in 14s`; module graph includes `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `./gradlew lint --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true` with explicit JDK 17 and SDK env | PASS | `BUILD SUCCESSFUL in 1m 29s`; `201 actionable tasks: 30 executed, 171 up-to-date`. |
| `/Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices -l` | BLOCKED for runtime validation | Printed only `List of devices attached`; no device rows. |
| `/Users/wangweiyang/Library/Android/sdk/emulator/emulator -list-avds` | PARTIAL | Printed one AVD: `Medium_Phone`. |
| `find /Users/wangweiyang/Library/Android/sdk/platforms -maxdepth 1 -type d -name 'android-*'` | PARTIAL | Found API 31 through API 36 platforms; no API 27 platform is installed. |
| `find /Users/wangweiyang/Library/Android/sdk/system-images -maxdepth 3 -type d -name 'android-*'` | PARTIAL | Found only `/Users/wangweiyang/Library/Android/sdk/system-images/android-36`. |
| `ls -l /Users/wangweiyang/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager` | BLOCKED | `No such file or directory`; local SDK manager is absent at the expected path. |
| `bash tools/device_validation_preflight.sh` with Android SDK env | BLOCKED | Reported 5 blockers: no attached device/emulator, no API 27 system image, no attached API 27 runtime, no low-memory/small-screen runtime, and no attached API 34+ runtime. |
| `./gradlew :app:connectedDebugAndroidTest --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true` with explicit JDK 17 and SDK env | BLOCKED / FAIL | Gradle prepared the debug app and androidTest APKs, then `:app:connectedDebugAndroidTest` failed with `DeviceException: No connected devices!`; `BUILD FAILED in 1m 16s`; `152 actionable tasks: 12 executed, 140 up-to-date`. |

Gradle printed its standard non-failing deprecation warning during the passing
host-side commands:

```text
Deprecated Gradle features were used in this build, making it incompatible with Gradle 10.
```

## Lint Coverage

The successful root `./gradlew lint` run covered the Android Stage 1 module
graph:

- `:app:lint`
- `:core:lint`
- `:feature:library:lint`
- `:feature:reader:lint`
- `:feature:settings:lint`

Representative generated Android-local lint artifacts present after this batch:

- `android/app/build/reports/lint-results-debug.html`
- `android/core/build/reports/lint-results-debug.html`
- `android/feature/library/build/reports/lint-results-debug.html`
- `android/feature/reader/build/reports/lint-results-debug.html`
- `android/feature/settings/build/reports/lint-results-debug.html`
- `android/build/reports/problems/problems-report.html`

## Connected Test Attempt

The connected instrumentation command reached APK preparation before device
execution failed. Existing Android-local artifacts are present:

- `android/app/build/outputs/apk/debug/app-debug.apk` (`9.3M`)
- `android/app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk`
  (`945K`)

The failure is an environment/runtime blocker, not an app compilation blocker:

```text
Execution failed for task ':app:connectedDebugAndroidTest'.
> com.android.builder.testing.api.DeviceException: No connected devices!
```

## Runtime Validation Blockers

Keep these Android L12 checklist items open until a device-backed report covers
them:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

Current blockers:

- No Android device or running emulator is attached.
- `Medium_Phone` is the only listed AVD.
- No Android API 27 platform is installed under
  `/Users/wangweiyang/Library/Android/sdk/platforms`.
- No Android API 27 system image is installed under
  `/Users/wangweiyang/Library/Android/sdk/system-images`.
- The expected SDK command-line tools `sdkmanager` path is absent, so this batch
  could not install missing API 27 tooling.
- No attached API 27 runtime is ready for Android 8.1 validation.
- No attached low-memory/small-screen runtime is ready.
- No attached API 34+ runtime is ready for modern-device validation.

## Supervisor Checklist Recommendation

The supervising session can use this report as fresh Android-lane evidence for
marking this L12 Android checklist item complete if it has not already been
reconciled:

- Run Android `./gradlew lint`.

Use the explicit-JDK `projects` output in this report as minimum Android Gradle
sanity evidence.

Do not use this report to newly claim completion for build, unit-test, assemble,
connected-device, API 27 runtime, low-memory/small-screen runtime, modern-device
runtime, or Android performance report items. Those either require separate
host-gate evidence from prior reports or remain blocked by the runtime/device
state recorded above.
