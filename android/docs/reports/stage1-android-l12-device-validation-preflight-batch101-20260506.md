# Stage 1 Android L12 Device Validation Preflight Batch 101

Date: 2026-05-06

Worker: FastMD Stage 1 Mobile Android live lane

Ownership: Android-only. This batch wrote only under `android/docs/reports/**`
and did not edit shared `Docs/**`, `ios/**`, or `.cron/**`.

## Scope

The daily todo snapshot still lists L12 Platform Validation as the open Android
cluster. Prior Android report
`android/docs/reports/stage1-android-l12-gradle-validation-refresh-batch100-20260506.md`
already captured fresh PASS evidence for the non-device Gradle gates:

- `./gradlew lint`
- `./gradlew build`
- `./gradlew :core:testDebugUnitTest`
- `./gradlew :feature:reader:testDebugUnitTest`
- `./gradlew :app:assembleDebug`

This bounded batch attempted the next earliest Android-owned items that need a
device or emulator:

- `./gradlew :app:connectedDebugAndroidTest`
- Android API 27 validation
- Android low-memory/small-screen profile validation
- Android modern device validation
- Android performance report capture refresh

## Environment

- Android project: `/Users/wangweiyang/GitHub/fastmd/android`
- JDK used for Gradle: `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`
- Android SDK used: `/Users/wangweiyang/Library/Android/sdk`
- Gradle wrapper: `./gradlew`, Gradle `9.3.0`
- Maven profile: `-Pfastmd.useChinaMavenMirror=true`
- ADB devices before and after the attempt: none attached
- Local AVDs: `Medium_Phone`
- `Medium_Phone` target: Android 36, arm64-v8a, Google APIs Play Store 16 KB page-size image
- `Medium_Phone` RAM: 2048 MB
- Installed system images: Android 36 only; no Android 27 system image present
- AVD filesystem free space during emulator attempt: `5874` MB available at
  `/Users/wangweiyang/.android/avd/Medium_Phone.avd`

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME=... ANDROID_SDK_ROOT=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon projects --stacktrace` | PASS | Root project `fastmd-android` evaluated and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 13s`. |
| `ANDROID_SDK_ROOT=... adb devices -l` | BLOCKED for device validation | ADB printed only `List of devices attached`; no physical device or booted emulator was attached. |
| `ANDROID_SDK_ROOT=... emulator -list-avds` | PASS preflight | Listed the local AVD `Medium_Phone`. |
| `sed -n '1,220p' ~/.android/avd/Medium_Phone.avd/config.ini` | PASS preflight | Confirmed `target = android-36`, `hw.ramSize = 2048`, `hw.lcd.width = 1080`, `hw.lcd.height = 2400`, and `image.sysdir.1 = system-images/android-36/google_apis_playstore_ps16k/arm64-v8a/`. |
| `find /Users/wangweiyang/Library/Android/sdk/system-images -maxdepth 4 -type d` | BLOCKED for API 27 validation | Only Android 36 system images are installed locally; there is no `system-images/android-27` directory. |
| `ANDROID_SDK_ROOT=... emulator -avd Medium_Phone -no-window -no-audio -no-boot-anim -gpu swiftshader_indirect` | BLOCKED for modern-device validation | Emulator exited before boot: `Not enough space to create userdata partition. Available: 5285.585938 MB ... need 7372.800000 MB.` |
| `JAVA_HOME=... ANDROID_SDK_ROOT=... ./gradlew -Pfastmd.useChinaMavenMirror=true --no-daemon :app:connectedDebugAndroidTest --stacktrace` | BLOCKED by no device | Gradle built or reused the debug app and androidTest APKs, then `:app:connectedDebugAndroidTest` failed with `com.android.builder.testing.api.DeviceException: No connected devices!`; `BUILD FAILED in 21s`. |
| `bash tools/audit_performance_report.sh` | PASS supporting evidence | Source-level Android performance posture audit passed and printed runtime profile limits plus fixture size matrix. |
| `pgrep -af 'emulator.*Medium_Phone' || true` followed by `ps -p <pid>` | PASS cleanup check | No live `Medium_Phone` emulator process remained after the failed boot attempt; the transient pgrep hit had already exited. |

## Performance Audit Output

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

This performance audit is useful Android-local evidence, but it is not
release-like device timing evidence. Keep API 27, low-memory/small-screen,
modern-device, connected instrumentation, and measured performance validation
open until an attached device or bootable emulator is available.

## Blockers Preserved

- `./gradlew :app:connectedDebugAndroidTest` remains open because no device or
  booted emulator is attached.
- Android API 27 validation remains open because this host has no Android 27
  system image installed.
- Android low-memory/small-screen profile validation remains open because the
  only local AVD is a 1080 x 2400 Android 36 phone profile with 2048 MB RAM, and
  it did not boot.
- Android modern device validation remains open because `Medium_Phone` could
  not create its userdata partition with the current free disk space.
- Release-like Android performance timing remains open because no device-backed
  validation run completed.

## Supervisor Checklist Recommendation

The supervising session can use this report as fresh Android-lane evidence for
the current blockers, but should not mark these device-backed L12 items complete
from this batch:

- L12: Run Android `./gradlew :app:connectedDebugAndroidTest`.
- L12: Run Android API 27 validation.
- L12: Run Android low-memory/small-screen profile validation.
- L12: Run Android modern device validation.

If the Stage 1 checklist accepts source-level Android performance posture output
as the performance report capture, this batch refreshes evidence for:

- L12: Capture Android performance report.

Evidence path:

- `android/docs/reports/stage1-android-l12-device-validation-preflight-batch101-20260506.md`
