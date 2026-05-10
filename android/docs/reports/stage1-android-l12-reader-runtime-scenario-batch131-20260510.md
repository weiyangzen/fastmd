# Stage 1 Android L12 Reader Runtime Scenario Batch 131 - 2026-05-10

## Scope

Android live-lane bounded implementation and validation batch for the earliest
still-open Android-owned L12 runtime/device validation surface that could be
advanced locally:

- Strengthen connected Android reader validation beyond intent-resolution smoke.
- Exercise shared Markdown entry, native reader rendering, search, and font-tier
  controls on the available constrained AVD.
- Fix the Android-native renderer crash exposed by that connected scenario.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

## Changed Android Files

- `android/app/build.gradle.kts`
- `android/gradle/libs.versions.toml`
- `android/app/src/androidTest/java/com/fastmd/mobile/MainActivityReaderScenarioTest.kt`
- `android/app/src/main/java/com/fastmd/mobile/MainActivity.kt`
- `android/feature/reader/src/main/java/com/fastmd/mobile/feature/reader/ReaderScreen.kt`
- `android/docs/reports/stage1-android-l12-reader-runtime-scenario-batch131-20260510.md`

## Implementation Notes

- Added Compose UI test dependencies for Android instrumentation:
  - `androidx.compose.ui:ui-test-junit4`
  - `androidx.compose.ui:ui-test-manifest`
  - `androidx.test:core`
- Added `MainActivityReaderScenarioTest`, a connected instrumentation scenario
  that launches `MainActivity` through Android `ACTION_SEND` shared Markdown
  text and verifies:
  - the shared Markdown document reaches the native reader;
  - heading and paragraph content render;
  - task-list and unordered-list content render without crashing;
  - search accepts input and reports `1 of 1 matches`;
  - the `Reader` font-tier control remains available on the constrained runtime.
- Made the app content column vertically scrollable so the first-screen reader
  surface and lower controls remain reachable on very small screens.
- Added stable Compose `testTag`s to the native reader search/source/block
  editor fields. The connected scenario currently uses the search tag; the
  editor tags are left in place for future non-brittle edit instrumentation.
- Fixed a native Android reader list-renderer bug: unordered list rendering was
  reading regex group `2` from a regex with only one content group, which caused
  `IndexOutOfBoundsException: No group 2` during connected rendering of a
  mixed task/unordered list block.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-10.

- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Explicit JDK:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
- Android SDK path:
  `/Users/wangweiyang/Library/Android/sdk`.
- Maven resolution used local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.
- Booted emulator:
  `Medium_Phone`, ADB serial `emulator-5554`.

## Runtime Profile

The AVD was booted headlessly with the local Android SDK emulator and constrained
before connected validation:

```text
adb shell wm size 320x320
adb shell wm density 220
adb shell wm size
Physical size: 1080x2400
Override size: 320x320
adb shell wm density
Physical density: 420
Override density: 220
adb shell getprop ro.build.version.sdk
36
adb shell cat /proc/meminfo | sed -n '1p'
MemTotal:        2047232 kB
```

`2047232 kB` is about `1999 MB`, satisfying the Android preflight low-memory
threshold of `<= 2048 MB`. API 36 satisfies the modern-device readiness
threshold used by `tools/device_validation_preflight.sh`.

The display override was restored after validation:

```text
adb shell wm size reset
adb shell wm density reset
adb shell wm size
Physical size: 1080x2400
adb shell wm density
Physical density: 420
```

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true projects` | PASS | Project graph listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; Gradle reported `BUILD SUCCESSFUL in 13s`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true :app:compileDebugAndroidTestKotlin :app:assembleDebug :app:assembleDebugAndroidTest` | PASS | After the final scenario adjustment, Gradle reported `BUILD SUCCESSFUL in 1m`; `151 actionable tasks: 15 executed, 136 up-to-date`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... bash tools/device_validation_preflight.sh` | PARTIAL / BLOCKED | Found attached emulator `emulator-5554`, API 36, `memMb=1999`; passed attached-device, low-memory readiness, and API 34+ modern readiness; blocked on missing API 27 system image and no attached API 27 target. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true :app:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=com.fastmd.mobile.MainActivityReaderScenarioTest --stacktrace` | PASS | Ran 1 connected reader scenario on `Medium_Phone(AVD) - 16`; Gradle reported `BUILD SUCCESSFUL in 34s`. |

Gradle printed its standard deprecation warning:

- Deprecated Gradle features were used in this build, making it incompatible
  with Gradle 10.

This warning did not fail any passing validation command.

## Connected Test Evidence

The final connected XML result records:

```xml
<testsuite name="com.fastmd.mobile.MainActivityReaderScenarioTest" tests="1" failures="0" errors="0" skipped="0" time="2.928">
  <testcase name="sharedMarkdownReaderSupportsRenderSearchAndFontTierOnConstrainedRuntime" classname="com.fastmd.mobile.MainActivityReaderScenarioTest" time="1.732" />
</testsuite>
```

Android-local artifacts refreshed by the final passing connected run:

- `android/app/build/outputs/androidTest-results/connected/debug/TEST-Medium_Phone(AVD) - 16-_app-.xml`
- `android/app/build/outputs/androidTest-results/connected/debug/Medium_Phone(AVD) - 16/test-result.textproto`
- `android/app/build/outputs/androidTest-results/connected/debug/Medium_Phone(AVD) - 16/testlog/test-results.log`
- `android/app/build/outputs/androidTest-results/connected/debug/Medium_Phone(AVD) - 16/logcat-com.fastmd.mobile.MainActivityReaderScenarioTest-sharedMarkdownReaderSupportsRenderSearchAndFontTierOnConstrainedRuntime.txt`
- `android/app/build/reports/androidTests/connected/debug/index.html`
- `android/app/build/reports/androidTests/connected/debug/com.fastmd.mobile.MainActivityReaderScenarioTest.html`

## Defect Found And Fixed

The first connected reader scenario run failed before assertions completed:

```text
java.lang.IndexOutOfBoundsException: No group 2
at com.fastmd.mobile.feature.reader.ReaderScreenKt.toListItem(ReaderScreen.kt:1473)
```

Cause:

- `UnorderedListRegex` is `^\s*[-+*]\s+(.+)$`, with one captured content group.
- The renderer attempted to read `unordered.groupValues[2]`.

Fix:

- `ReaderScreen.kt` now reads `unordered.groupValues[1]` for unordered list
  item content.

The passing connected scenario confirms the mixed task-list/unordered-list
shared Markdown fixture now renders without that crash on the constrained AVD.

## Remaining Runtime Scope

Keep this L12 item open:

- Run Android API 27 validation.

Reason:

- The local SDK still has Android 36 system images only.
- No attached API 27 device/emulator is available.
- `tools/device_validation_preflight.sh` continues to block API 27 readiness for
  missing `android-27` system image and no attached API 27 target.

The connected scenario is stronger evidence than the earlier intent-resolution
smoke for these L12 items:

- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

It does not prove physical Android 8.1/API 27 behavior.

## Supervisor Checklist Recommendation

The supervising session can use this report as Android-lane evidence for
marking these L12 checklist items complete, if the acceptance threshold allows a
constrained API 36 AVD for the device-scenario claim:

- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

This report also provides additional implementation and validation evidence for:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.

Keep open:

- Run Android API 27 validation.
