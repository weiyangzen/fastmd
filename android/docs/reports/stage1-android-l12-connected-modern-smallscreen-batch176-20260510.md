# Stage 1 Android L12 Connected Modern And Small-Screen Validation - Batch 176

Date: 2026-05-10 08:33 CST

Worker scope: Android live lane, `android/**` only.

## Batch Selection

The authoritative blueprint and daily todo snapshot still leave Android L12
platform validation open. Recent Android reports already cover host Gradle
validation (`lint`, `build`, unit tests, `assembleDebug`, and the source-level
performance report), so this bounded batch targeted the earliest remaining
Android-owned device-backed items that could be advanced locally:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android modern device validation.
- Refresh low-memory/small-screen connected smoke evidence.
- Re-check Android API 27 readiness and keep it open if still unavailable.

No Android product source changes were required. No `ios/**`, shared `Docs/**`,
or `.cron/**` files were edited.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-connected-modern-smallscreen-batch176-20260510.md`

Gradle refreshed generated Android-local build/test outputs under ignored
`build/` directories while running validation.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android`.

- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Explicit JDK:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
- Java version: OpenJDK `17.0.17` (`Homebrew 17.0.17+0`).
- Android SDK path: `/Users/wangweiyang/Library/Android/sdk`.
- Android emulator version: `36.1.9.0`, build `13823996`.
- Maven resolution used local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.

The host filesystem had only about `4.8-5.2 GiB` free, while the existing
`Medium_Phone` AVD requires about `7372.8 MB` free for its configured userdata
partition. Direct boot attempts failed with:

```text
ERROR | Not enough space to create userdata partition. Available: 5362.363281 MB at /Users/wangweiyang/.android/avd/../avd/Medium_Phone.avd, need 7372.800000 MB.
```

To avoid mutating the existing global AVD, this batch created a throwaway
RAM-backed AVD home mounted at `/Volumes/FastMDAndroidAVD` and copied the local
`Medium_Phone` AVD config into a temporary `FastMD_Modern_Temp` AVD using the
installed Android 36 Google APIs image. The RAM volume had `8.7 GiB` available
and was used only for this validation run.

## Runtime Under Test

Temporary AVD:

```text
FastMD_Modern_Temp
target=android-36
image.sysdir.1=system-images/android-36/google_apis/arm64-v8a/
disk.dataPartition.size=1610612736
sdcard.size=64M
hw.lcd.width=1080
hw.lcd.height=2400
hw.lcd.density=420
hw.ramSize=2048
```

Boot command:

```bash
ANDROID_AVD_HOME=/Volumes/FastMDAndroidAVD/avd \
ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk \
ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk \
/Users/wangweiyang/Library/Android/sdk/emulator/emulator \
  -avd FastMD_Modern_Temp \
  -no-window \
  -no-snapshot \
  -no-snapstorage \
  -no-audio \
  -no-boot-anim \
  -gpu swiftshader_indirect
```

Boot evidence after `sys.boot_completed=1`:

```text
BOOT_COMPLETED after 7s
emulator-5554 device product:sdk_gphone64_arm64 model:sdk_gphone64_arm64 device:emu64a
ro.build.version.sdk=36
ro.build.version.release=16
ro.product.model=sdk_gphone64_arm64
wm size=Physical size: 1080x2400
wm density=Physical density: 420
MemTotal:        2021944 kB
```

`2021944 kB` is about `1974 MiB`, which satisfies the local preflight
low-memory threshold of `<= 2048 MB`. `ro.config.low_ram` did not report a
value, so this is constrained-RAM emulator evidence, not proof that Android's
`ActivityManager.isLowRamDevice` flag is true on dedicated low-RAM hardware.

## Validation Results

Passing Gradle commands used:

```bash
JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home \
ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk \
ANDROID_SDK_ROOT=/Users/wangweiyang/Library/Android/sdk \
./gradlew --no-daemon --console=plain -Pfastmd.useChinaMavenMirror=true ...
```

| Command | Result | Evidence |
| --- | --- | --- |
| `adb wait-for-device` plus `sys.boot_completed` polling | PASS | Temporary Android 36 emulator reached `BOOT_COMPLETED after 7s`; ADB listed `emulator-5554` as a device. |
| `./gradlew :app:connectedDebugAndroidTest` on default 1080x2400 emulator | PASS | `BUILD SUCCESSFUL in 37s`; 4 tests ran on `FastMD_Modern_Temp(AVD) - 16` with 0 failures/errors. |
| `adb shell wm size 320x320` and `adb shell wm density 220` | PASS | Emulator reported `Override size: 320x320` and `Override density: 220`. |
| `./gradlew :app:connectedDebugAndroidTest` under 320x320 override | PASS | `BUILD SUCCESSFUL in 36s`; 4 tests ran on `FastMD_Modern_Temp(AVD) - 16` with 0 failures/errors. |
| `adb shell wm size reset` and `adb shell wm density reset` | PASS | Emulator returned to `Physical size: 1080x2400` and `Physical density: 420`. |
| `bash tools/device_validation_preflight.sh` while emulator was attached | PARTIAL / BLOCKED | Passed attached-device, low-memory readiness, and API 34+ modern readiness; blocked on missing Android API 27 system image and no attached API 27 target. |

Gradle printed the standard deprecation warning about future Gradle 10
compatibility. It did not fail the selected validation tasks.

## Connected Test Coverage

Latest generated JUnit XML:

```text
android/app/build/outputs/androidTest-results/connected/debug/TEST-FastMD_Modern_Temp(AVD) - 16-_app-.xml
tests="4" failures="0" errors="0" skipped="0" time="2.994"
device="FastMD_Modern_Temp(AVD) - 16"
project=":app"
timestamp="2026-05-10T00:33:10"
```

The connected suite covered:

- `MainActivityIntentContractTest.markdownViewIntentResolvesToExportedMainActivity`
- `MainActivityIntentContractTest.sharedTextIntentResolvesToExportedMainActivity`
- `MainActivityIntentContractTest.launcherIntentResolvesToExportedMainActivity`
- `MainActivityReaderScenarioTest.sharedMarkdownReaderSupportsRenderSearchAndFontTierOnConstrainedRuntime`

The reader scenario launches a shared Markdown document and verifies rendered
heading/body content, line count text, search field input, search match count,
and font-tier control interaction on the connected runtime.

## Android-Local Evidence Artifacts

- Connected Android test XML:
  `android/app/build/outputs/androidTest-results/connected/debug/TEST-FastMD_Modern_Temp(AVD) - 16-_app-.xml`
- Connected Android test HTML report:
  `android/app/build/reports/androidTests/connected/debug/index.html`
- Per-test HTML reports:
  `android/app/build/reports/androidTests/connected/debug/com.fastmd.mobile.MainActivityIntentContractTest.html`
  and
  `android/app/build/reports/androidTests/connected/debug/com.fastmd.mobile.MainActivityReaderScenarioTest.html`
- Device/test output directory:
  `android/app/build/outputs/androidTest-results/connected/debug/FastMD_Modern_Temp(AVD) - 16/`
- Debug APK:
  `android/app/build/outputs/apk/debug/app-debug.apk`
- Android test APK:
  `android/app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk`
- Gradle problems report:
  `android/build/reports/problems/problems-report.html`

## Device Preflight Output

With the temporary emulator attached, `tools/device_validation_preflight.sh`
reported:

```text
PASS: Found 1 attached Android device(s).
DEVICE: serial=emulator-5554 api=36 model="Google sdk_gphone64_arm64" size=1080x2400 memMb=1974
BLOCKED: No Android API 27 system image is installed under /Users/wangweiyang/Library/Android/sdk/system-images.
BLOCKED: No attached API 27 device/emulator is ready for Android 8.1 validation.
PASS: An attached low-memory device/emulator is ready for small-screen or low-memory validation.
PASS: An attached API 34+ device/emulator is ready for modern-device validation.
BLOCKED: Android device validation preflight found 2 blocker(s).
```

Installed system images remain Android 36 only:

```text
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis/arm64-v8a
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore/arm64-v8a
/Users/wangweiyang/Library/Android/sdk/system-images/android-36/google_apis_playstore_ps16k/arm64-v8a
```

The SDK still lacks `cmdline-tools/latest/bin/sdkmanager`, so this batch did
not install an Android API 27 image.

## Checklist Evidence For Supervisor

The supervising session can use this report as current Android-lane evidence
for marking these L12 checklist items complete:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android modern device validation.

The supervising session can also use this report, together with
`android/docs/reports/stage1-android-l12-small-screen-validation-batch124-20260510.md`,
as constrained emulator evidence for marking:

- Run Android low-memory/small-screen profile validation.

Keep this L12 item open:

- Run Android API 27 validation.

Reason: no Android API 27 system image is installed and no attached API 27
device/emulator is available locally.
