# Stage 1 Android L12 Host Validation Batch 192 - 2026-05-10

## Scope

Android live-lane bounded validation batch for the earliest still-open
Android-owned L12 checklist items in `Docs/Stage1_Mobile_Blueprint.md` and
`Docs/todos_20260506.md`.

This batch stayed inside `android/**`. It did not edit `ios/**`,
`Docs/Stage1_Mobile_Blueprint.md`, `Docs/todos_20260506.md`, or `.cron/**`.

No Android product source changes were required. The only intentional repository
write is this Android-local evidence report.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-host-validation-batch192-20260510.md`

Gradle also refreshed generated Android-local build outputs under ignored
`android/**/build/` directories while running validation.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-10 CST.

- Checked-in Gradle wrapper: `./gradlew`, Gradle `9.3.0`.
- Android SDK from `local.properties`: `/Users/wangweiyang/Library/Android/sdk`.
- Passing host Gradle commands used Maven mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.
- Android Studio bundled JBR used for the main host validation gates:
  `/Applications/Android Studio.app/Contents/jbr/Contents/Home`.
- Homebrew JDK 17 is also available:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.

The default shell still does not expose Java through macOS discovery:

```text
./gradlew projects
The operation couldn't be completed. Unable to locate a Java Runtime.
Please visit http://www.java.com for information on installing Java.
```

This is an environment wiring issue only. Re-running with scoped `JAVA_HOME`
passed.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `./gradlew projects` with no scoped Java env | BLOCKED | macOS reported no discoverable Java runtime. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew --no-daemon --stacktrace --info -Pfastmd.useChinaMavenMirror=true projects` | PASS | `BUILD SUCCESSFUL in 4s`; confirmed modules `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `JAVA_HOME="/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home" PATH="/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin:$PATH" ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true projects` | PASS | `BUILD SUCCESSFUL in 14s`; confirms JDK 17 can run the wrapper when exported explicitly. |
| `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported OpenJDK `17.0.17`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true lint` | PASS | `BUILD SUCCESSFUL in 27s`; app/core/feature lint reports written. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true :core:testDebugUnitTest` | PASS | `BUILD SUCCESSFUL in 16s`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true :feature:reader:testDebugUnitTest` | PASS | `BUILD SUCCESSFUL in 15s`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true :app:assembleDebug` | PASS | `BUILD SUCCESSFUL in 12s`; debug APK produced. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true build` | PASS | `BUILD SUCCESSFUL in 2m 32s`; covered debug/release build, lint, host tests, and renderer/security audit gates. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true stage1AndroidPerformanceReport` | PASS | `BUILD SUCCESSFUL in 5s`; `auditPerformanceReport` printed Stage 1 profile limits and fixture size matrix. |
| `adb devices -l` | BLOCKED for connected validation | Returned only `List of devices attached` with no devices listed. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true :app:connectedDebugAndroidTest` | BLOCKED | Built the debug androidTest APK, then failed `:app:connectedDebugAndroidTest` with `DeviceException: No connected devices!`. |
| `bash tools/device_validation_preflight.sh` | BLOCKED | No attached Android device or booted emulator; no API 27 system image installed; only API 36 system images are installed. |

Gradle printed its standard non-failing deprecation warning in passing commands:

```text
Deprecated Gradle features were used in this build, making it incompatible with Gradle 10.
```

## Host Unit Test Evidence

The explicit host unit-test gates passed:

- `:core:testDebugUnitTest`
- `:feature:reader:testDebugUnitTest`

The full `build` gate also passed app/core/feature debug and release host test
tasks that have sources.

Generated report indexes include:

- `android/core/build/reports/tests/testDebugUnitTest/index.html`
- `android/feature/reader/build/reports/tests/testDebugUnitTest/index.html`
- `android/app/build/reports/tests/testDebugUnitTest/index.html`
- `android/app/build/reports/tests/testReleaseUnitTest/index.html`

## Lint And Build Artifacts

Generated artifacts observed after this batch:

- Debug APK: `android/app/build/outputs/apk/debug/app-debug.apk`
- Release unsigned APK:
  `android/app/build/outputs/apk/release/app-release-unsigned.apk`
- App lint report: `android/app/build/reports/lint-results-debug.html`
- Core lint report: `android/core/build/reports/lint-results-debug.html`
- Reader lint report:
  `android/feature/reader/build/reports/lint-results-debug.html`
- Library lint report:
  `android/feature/library/build/reports/lint-results-debug.html`
- Settings lint report:
  `android/feature/settings/build/reports/lint-results-debug.html`
- Gradle problems report:
  `android/build/reports/problems/problems-report.html`

## Performance Report Evidence

`stage1AndroidPerformanceReport` ran `auditPerformanceReport` successfully.
The task printed:

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

This is source-level Android performance report evidence. Runtime device
performance validation remains blocked in this batch because no Android runtime
is attached.

## Device Validation Blockers

Connected and device-class validation remain open for this batch.

Current blockers:

- `adb devices -l` reports no attached device or booted emulator.
- `:app:connectedDebugAndroidTest` fails with
  `com.android.builder.testing.api.DeviceException: No connected devices!`.
- `tools/device_validation_preflight.sh` reports no attached device/emulator.
- No Android API 27 system image is installed under
  `/Users/wangweiyang/Library/Android/sdk/system-images`.
- Installed system images observed by preflight are API 36 only:
  `android-36/google_apis/arm64-v8a`,
  `android-36/google_apis_playstore/arm64-v8a`, and
  `android-36/google_apis_playstore_ps16k/arm64-v8a`.

Do not use this report to mark connected instrumentation, API 27, low-memory,
small-screen, or modern-device runtime validation complete.

## Supervisor Checklist Recommendation

The supervising session can use this report as fresh Android-lane evidence for
marking these L12 Android checklist items complete:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Capture Android performance report.

Keep these L12 Android checklist items open from this batch:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.
