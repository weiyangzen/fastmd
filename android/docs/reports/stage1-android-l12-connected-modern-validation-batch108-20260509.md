# Stage 1 Android L12 Connected Modern Validation Batch 108 - 2026-05-09

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
runtime validation item in `Docs/Stage1_Mobile_Blueprint.md` and
`Docs/todos_20260506.md`.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

## Changed Android Files

- `android/app/src/androidTest/java/com/fastmd/mobile/MainActivityIntentContractTest.kt`
- `android/docs/reports/stage1-android-l12-connected-modern-validation-batch108-20260509.md`

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-09 at about 22:00 CST.

- Gradle validation used explicit JDK 17:
  `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`.
- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Maven resolution used the local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.
- Android SDK path:
  `/Users/wangweiyang/Library/Android/sdk`.
- Booted AVD:
  `Medium_Phone`.
- Boot command:
  `/Users/wangweiyang/Library/Android/sdk/emulator/emulator -avd Medium_Phone -no-window -no-audio -no-boot-anim -gpu swiftshader_indirect -no-snapshot-save`.
- Boot readiness check:
  `adb wait-for-device shell getprop sys.boot_completed` returned `1`.

## Device Evidence

The connected target was:

| Property | Value |
| --- | --- |
| ADB serial | `emulator-5554` |
| Product | `sdk_gphone16k_arm64` |
| Model | `sdk_gphone16k_arm64` |
| API level | `36` |
| Size | `1080x2400` |
| MemTotal | `2047232 kB` |

The AVD configuration reports:

- `target = android-36`
- `hw.ramSize = 2048`
- `image.sysdir.1 = system-images/android-36/google_apis_playstore_ps16k/arm64-v8a/`

This target provides Android modern connected-test coverage. It is not Android
8.1/API 27 coverage because the SDK still has no API 27 system image installed.

## Implementation Fix

The first connected instrumentation attempt reached the device and ran tests,
but failed:

```text
com.fastmd.mobile.MainActivityIntentContractTest > launcherIntentResolvesToExportedMainActivity[Medium_Phone(AVD) - 16] FAILED
java.lang.AssertionError: Expected MainActivity to resolve Intent { act=android.intent.action.MAIN cat=[android.intent.category.LAUNCHER] pkg=com.fastmd.mobile }
```

The manifest launcher entry was valid. The test helper incorrectly used
`PackageManager.MATCH_DEFAULT_ONLY` for all intent queries, including the
launcher intent. Launcher filters use `CATEGORY_LAUNCHER`, not
`CATEGORY_DEFAULT`, so API 36 correctly filtered out the launcher result.

The Android instrumentation test now applies `MATCH_DEFAULT_ONLY` only when the
queried intent includes `Intent.CATEGORY_DEFAULT`. The document/share intent
contract tests still use default-only resolution; the launcher intent uses normal
launcher resolution.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `adb kill-server && adb start-server && adb devices -l` | PASS | ADB started successfully; initially no device was attached. |
| `emulator -list-avds` | PASS | Listed `Medium_Phone`. |
| `emulator -avd Medium_Phone -no-window -no-audio -no-boot-anim -gpu swiftshader_indirect -no-snapshot-save` | PASS | Started the Android 36 AVD in headless mode. |
| `adb wait-for-device shell getprop sys.boot_completed` | PASS | Returned `1`. |
| `adb devices -l` and device property probes | PASS | Listed `emulator-5554`, API `36`, `1080x2400`, `MemTotal: 2047232 kB`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true :app:connectedDebugAndroidTest --stacktrace` | FAIL, then fixed | First run reached `Medium_Phone(AVD) - 16` and failed the launcher intent resolution test because the test helper used `MATCH_DEFAULT_ONLY` for a launcher-only intent. |
| `ANDROID_HOME=... ANDROID_SDK_ROOT=... bash tools/device_validation_preflight.sh` | PARTIAL / BLOCKED | Found `emulator-5554`, passed attached-device readiness, low-memory threshold readiness, and API 34+ readiness; still blocked by missing API 27 system image and no attached API 27 device/emulator. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true :app:connectedDebugAndroidTest --stacktrace` | PASS | Rerun finished 3 tests on `Medium_Phone(AVD) - 16`; `BUILD SUCCESSFUL in 42s`. |

Connected test result files:

- `android/app/build/reports/androidTests/connected/debug/index.html`
- `android/app/build/reports/androidTests/connected/debug/com.fastmd.mobile.MainActivityIntentContractTest.html`
- `android/app/build/outputs/androidTest-results/connected/debug/TEST-Medium_Phone(AVD) - 16-_app-.xml`
- `android/app/build/outputs/androidTest-results/connected/debug/Medium_Phone(AVD) - 16/test-result.textproto`

The XML result recorded:

```xml
<testsuite name="com.fastmd.mobile.MainActivityIntentContractTest" tests="3" failures="0" errors="0" skipped="0">
```

The textproto result recorded `test_status: PASSED`.

## Remaining Blockers

- Android API 27 validation remains blocked because no Android API 27 system
  image is installed under `/Users/wangweiyang/Library/Android/sdk/system-images`.
- The running `Medium_Phone` target is API 36 and cannot satisfy Android 8.1/API
  27 validation.
- Broader modern-device manual/runtime coverage beyond the current connected
  instrumentation smoke should remain open if the supervisor requires rich
  fixture open/render/search/edit/save validation on a modern target.

## Supervisor Checklist Recommendation

The supervising session can use this report as evidence for marking this Android
L12 checklist item complete:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.

Use this report as partial evidence for modern-device readiness and connected
instrumentation on an API 36 emulator, but keep these L12 items open unless the
supervisor accepts the current intent-contract instrumentation smoke as the
entire runtime scope:

- Run Android modern device validation.
- Run Android low-memory/small-screen profile validation.

Keep this L12 item open:

- Run Android API 27 validation.
