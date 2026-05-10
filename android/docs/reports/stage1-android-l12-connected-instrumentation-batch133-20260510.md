# Stage 1 Android L12 Connected Instrumentation Batch 133 - 2026-05-10

## Scope

Android live-lane bounded batch for the earliest remaining Android-owned L12
runtime validation item that could be advanced from the local environment:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android product source changes were made. The only intentional repository
write in this batch is this Android-local evidence report.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-connected-instrumentation-batch133-20260510.md`

Gradle also refreshed generated Android-local build/test artifacts under
`android/app/build/` and `android/build/`.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-10.

- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Android SDK path from `android/local.properties`:
  `/Users/wangweiyang/Library/Android/sdk`.
- Explicit JDK used for passing Gradle commands:
  `/Applications/Android Studio.app/Contents/jbr/Contents/Home`.
- Explicit Java version:
  OpenJDK `21.0.6`, Android Studio bundled JBR.
- Default shell Java state:
  `java -version` is blocked by macOS with `Unable to locate a Java Runtime`.

The checked-in Gradle wrapper works when `JAVA_HOME` and `PATH` are scoped to
Android Studio's bundled JBR:

```text
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
PATH="/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin:$PATH"
```

## Device / Emulator Preflight

Before booting the emulator:

```text
/Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices -l
List of devices attached
```

Available AVDs:

```text
Medium_Phone
```

The available `Medium_Phone` AVD is not an API 27 image:

- `target = android-36`
- `image.sysdir.1 = system-images/android-36/google_apis_playstore_ps16k/arm64-v8a/`
- `hw.cpu.arch = arm64`
- `abi.type = arm64-v8a`
- `hw.ramSize = 2048`
- `hw.lcd.width = 1080`
- `hw.lcd.height = 2400`
- `hw.lcd.density = 420`

Installed SDK platforms:

- `android-31`
- `android-32`
- `android-33`
- `android-34`
- `android-35`
- `android-36`

No API 27 system image is installed in this local SDK, so this batch could not
claim Android 8.1/API 27 runtime validation.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME=... PATH=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon projects` | PASS | Listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; Gradle reported `BUILD SUCCESSFUL in 3s`. |
| `/Users/wangweiyang/Library/Android/sdk/emulator/emulator -avd Medium_Phone -no-snapshot-save -no-window -no-audio -no-boot-anim` | PASS | Emulator booted from the existing `Medium_Phone` AVD; `adb wait-for-device shell getprop sys.boot_completed` returned `1`. |
| `/Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices -l` after boot | PASS | Listed `emulator-5554 device product:sdk_gphone16k_arm64 model:sdk_gphone16k_arm64 device:emu64a16k`. |
| `adb shell getprop` device probe | PASS | Reported SDK `36`, Android release `16`, model `sdk_gphone16k_arm64`, ABI `arm64-v8a`, size `1080x2400`, density `420`. |
| `JAVA_HOME=... PATH=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon :app:connectedDebugAndroidTest` | PASS | Gradle started and finished 4 tests on `Medium_Phone(AVD) - 16`; Gradle reported `BUILD SUCCESSFUL in 35s`; `152 actionable tasks: 7 executed, 145 up-to-date`. |

Gradle printed its standard deprecation warning:

```text
Deprecated Gradle features were used in this build, making it incompatible with Gradle 10.
```

This warning did not fail the connected Android test run.

## Connected Test Coverage

The connected run executed 4 instrumentation tests:

- `com.fastmd.mobile.MainActivityIntentContractTest.markdownViewIntentResolvesToExportedMainActivity`
- `com.fastmd.mobile.MainActivityIntentContractTest.sharedTextIntentResolvesToExportedMainActivity`
- `com.fastmd.mobile.MainActivityIntentContractTest.launcherIntentResolvesToExportedMainActivity`
- `com.fastmd.mobile.MainActivityReaderScenarioTest.sharedMarkdownReaderSupportsRenderSearchAndFontTierOnConstrainedRuntime`

The generated XML result reported:

```text
tests="4" failures="0" errors="0" skipped="0"
```

The raw instrumentation log ended with:

```text
OK (4 tests)
```

The reader scenario validated a shared Markdown entry path on-device and
asserted:

- rendered title text for `Stage 1 Runtime Reader`
- loaded line-count metadata
- rendered paragraph text containing `runtime-search-token`
- search input through the Compose semantics tag `reader-search-field`
- search result count text `1 of 1 matches`
- font tier control interaction for `Reader`

The intent contract tests validated launcher, Markdown `ACTION_VIEW`, and
shared text `ACTION_SEND` resolution to exported `MainActivity`.

## Android-Local Evidence Artifacts

Connected Android test report:

- `android/app/build/reports/androidTests/connected/debug/index.html`
- `android/app/build/reports/androidTests/connected/debug/com.fastmd.mobile.MainActivityIntentContractTest.html`
- `android/app/build/reports/androidTests/connected/debug/com.fastmd.mobile.MainActivityReaderScenarioTest.html`

Connected Android test raw results:

- `android/app/build/outputs/androidTest-results/connected/debug/TEST-Medium_Phone(AVD) - 16-_app-.xml`
- `android/app/build/outputs/androidTest-results/connected/debug/Medium_Phone(AVD) - 16/test-result.textproto`
- `android/app/build/outputs/androidTest-results/connected/debug/Medium_Phone(AVD) - 16/testlog/test-results.log`
- `android/app/build/outputs/androidTest-results/connected/debug/Medium_Phone(AVD) - 16/device-info.pb`
- `android/app/build/outputs/androidTest-results/connected/debug/Medium_Phone(AVD) - 16/cpuinfo`
- `android/app/build/outputs/androidTest-results/connected/debug/Medium_Phone(AVD) - 16/meminfo`

Connected run APK artifacts:

- `android/app/build/outputs/apk/debug/app-debug.apk`
- `android/app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk`

Gradle problem report refreshed:

- `android/build/reports/problems/problems-report.html`

## Remaining Runtime Scope

This batch did not run Android API 27 validation. The local environment has
installed SDK platforms from API 31 through API 36, but no API 27 system image.

This batch did not run a strict low-memory/small-screen profile validation. The
available AVD is `1080x2400`, density `420`, with `2048 MB` RAM and no
`ro.config.low_ram` value reported.

This batch provides connected modern-emulator smoke evidence on API 36, but it
does not by itself satisfy a stricter release claim for Android 14/15 modern
device validation if the supervising checklist requires that exact device/API
class.

This batch did not capture a new Android performance report.

## Supervisor Checklist Recommendation

The supervising session can use this report as fresh Android-lane evidence for
marking this Android L12 checklist item complete if not already reconciled:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.

Use this report as supporting evidence, but not sole completion evidence, for:

- Run Android modern device validation.

Keep these L12 runtime/performance items open unless covered by separate
matching Android-local reports:

- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation, if strict Android 14/15 or physical
  device coverage is required.
- Capture Android performance report.
