# Stage 1 Android L12 Device Runtime Blocker Batch 193 - 2026-05-10

## Scope

Android live-lane bounded validation batch for the earliest still-open
Android-owned L12 runtime checklist items:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

This batch stayed inside `android/**`. It did not edit `ios/**`,
`Docs/Stage1_Mobile_Blueprint.md`, `Docs/todos_20260506.md`, or `.cron/**`.

No Android product source changes were required. The only intentional repository
write is this Android-local evidence report.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-device-runtime-blocker-batch193-20260510.md`

Gradle also refreshed ignored Android-local generated outputs under module
`build/` directories while preparing the connected test APK.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-10 12:16 CST.

- Checked-in Gradle wrapper: `./gradlew`, Gradle `9.3.0`.
- Android SDK from `local.properties`: `/Users/wangweiyang/Library/Android/sdk`.
- Passing host Gradle commands used Maven mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.
- Android Studio bundled JBR used for Gradle:
  `/Applications/Android Studio.app/Contents/jbr/Contents/Home`.
- Shell `PATH` does not include Android SDK command tools:
  `emulator`, `avdmanager`, and `sdkmanager` were not found by bare command name.
- SDK emulator binary exists at:
  `/Users/wangweiyang/Library/Android/sdk/emulator/emulator`.
- SDK command-line tools are incomplete or not installed at the usual `latest`
  path: `cmdline-tools/latest/bin/avdmanager` and
  `cmdline-tools/latest/bin/sdkmanager` were missing.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true projects` | PASS | `BUILD SUCCESSFUL in 4s`; confirmed modules `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `adb devices -l` | BLOCKED | Returned only `List of devices attached` with no devices listed. |
| `bash tools/device_validation_preflight.sh` | BLOCKED | Reported no attached Android device or booted emulator, no installed API 27 system image, no API 27 runtime ready, no detected low-memory/small-screen runtime, and no API 34+ runtime ready. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true :app:connectedDebugAndroidTest` | BLOCKED | Built the app and androidTest APKs, then failed `:app:connectedDebugAndroidTest` with `com.android.builder.testing.api.DeviceException: No connected devices!`. |
| `emulator -list-avds` | BLOCKED | Bare command failed with `emulator: command not found`; Android SDK emulator is not on shell `PATH`. |
| `/Users/wangweiyang/Library/Android/sdk/emulator/emulator -list-avds` | PASS | Listed one AVD: `Medium_Phone`. This batch did not boot it because no runtime validation profile or API level was confirmed from the AVD metadata, and API 27 is not installed. |
| `avdmanager list avd` | BLOCKED | Bare command failed with `avdmanager: command not found`. |
| `/Users/wangweiyang/Library/Android/sdk/cmdline-tools/latest/bin/avdmanager list avd` | BLOCKED | Failed because the binary does not exist at the expected SDK `latest` path. |
| `sdkmanager --list_installed` | BLOCKED | Bare command failed with `sdkmanager: command not found`. |
| `/Users/wangweiyang/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager --list_installed` | BLOCKED | Failed because the binary does not exist at the expected SDK `latest` path. |
| `find "$HOME/Library/Android/sdk/system-images" -maxdepth 4 -type d` | BLOCKED for API 27 | Only API 36 system-image directories were present. No `android-27` system image was installed. |

Gradle printed its standard non-failing deprecation warning:

```text
Deprecated Gradle features were used in this build, making it incompatible with Gradle 10.
```

## Device Runtime Blockers

Connected and device-class validation remain open for this batch.

Current blockers:

- `adb devices -l` reports no attached device or booted emulator.
- `:app:connectedDebugAndroidTest` fails with
  `com.android.builder.testing.api.DeviceException: No connected devices!`.
- `tools/device_validation_preflight.sh` reports no attached Android device or
  booted emulator.
- No Android API 27 system image is installed under
  `/Users/wangweiyang/Library/Android/sdk/system-images`.
- Installed system-image directories are API 36 only:
  `android-36/google_apis/arm64-v8a`,
  `android-36/google_apis_playstore/arm64-v8a`, and
  `android-36/google_apis_playstore_ps16k/arm64-v8a`.
- Android SDK command-line tools are not available on `PATH`, and the expected
  `cmdline-tools/latest/bin/avdmanager` and `cmdline-tools/latest/bin/sdkmanager`
  binaries are missing.

## Supervisor Checklist Recommendation

Use this report as fresh Android-lane evidence for keeping these L12 Android
checklist items open until a real runtime is attached or booted:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

This batch does not newly complete any blueprint checklist item. It confirms the
current runtime blocker after the host Gradle gates were already validated by
earlier Android-local reports.
