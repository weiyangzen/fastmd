# Stage 1 Android L12 Validation Refresh Batch 121 - 2026-05-10

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
platform validation surface from the authoritative blueprint:

- Run Android `./gradlew lint`.
- Refresh minimum Gradle project sanity evidence with `./gradlew projects`.
- Refresh Android performance report capture evidence with
  `stage1AndroidPerformanceReport`.
- Re-check local device/API 27 availability for runtime validation blockers.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android product source changes were made. The only repository write in this
batch is this Android-local evidence report.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-validation-refresh-batch121-20260510.md`

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-10.

- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Explicit JDK:
  `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`.
- Android SDK path:
  `/Users/wangweiyang/Library/Android/sdk`.
- Maven resolution used local mirror opt-in:
  `-Pfastmd.useChinaMavenMirror=true`.

The default shell Java remains unavailable:

```text
java -version
The operation couldn't be completed. Unable to locate a Java Runtime.
```

The checked-in Gradle wrapper works when `JAVA_HOME` is set to the explicit
Homebrew OpenJDK 17 path above.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true projects` | PASS | Project graph listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; Gradle reported `BUILD SUCCESSFUL in 13s`. |
| `bash tools/audit_performance_report.sh` | PASS | Confirmed Android performance posture and fixture/profile matrix; printed four profile soft limits and required fixture sizes; reported `PASS: Android performance report audit completed.` |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true stage1AndroidPerformanceReport` | PASS | Ran `:auditPerformanceReport` and `:stage1AndroidPerformanceReport`; Gradle reported `BUILD SUCCESSFUL in 17s`. |
| `JAVA_HOME=... ANDROID_HOME=... ANDROID_SDK_ROOT=... ./gradlew --no-daemon -Pfastmd.useChinaMavenMirror=true lint` | PASS | Lint ran for `app`, `core`, `feature:library`, `feature:reader`, and `feature:settings`; Gradle reported `BUILD SUCCESSFUL in 19s` with `201 actionable tasks: 10 executed, 191 up-to-date`. |
| `ANDROID_HOME=... ANDROID_SDK_ROOT=... adb devices -l` | BLOCKED for connected runtime validation | Printed `List of devices attached` with no attached device rows. |
| `ANDROID_HOME=... ANDROID_SDK_ROOT=... emulator -list-avds` | PASS | Listed one AVD: `Medium_Phone`. |
| `find /Users/wangweiyang/Library/Android/sdk/system-images -maxdepth 4 -type d` | BLOCKED for API 27 validation | Installed system images are Android 36 only; no `android-27` system image is installed. |

## Performance Report Evidence

The Android-local performance audit printed these profile limits:

```text
WatchCompact softLimitBytes=262144
LegacyEfficient softLimitBytes=1048576
ModernStandard softLimitBytes=5242880
LargeScreen softLimitBytes=5242880
```

It also verified the fixture matrix used by the Android performance posture
checks:

```text
basic.md bytes=124 lines=7
rich-preview.md bytes=5050 lines=246
long-1mb.md bytes=328 lines=10
large-5mb.md bytes=296 lines=8
huge-table.md bytes=333 lines=9
huge-code-block.md bytes=176 lines=11
remote-image.md bytes=148 lines=5
local-image.md bytes=142 lines=5
```

The audit checks the Android source-level performance contract:

- document load/save IO uses `Dispatchers.IO`;
- recovery draft IO uses `Dispatchers.IO`;
- Markdown parsing and search summarization run on `Dispatchers.Default`;
- search uses a cancellable job and generation/source-revision guard;
- reader rendering uses `LazyColumn` with stable Markdown block ids;
- local image decode is asynchronous and dispatched to `Dispatchers.IO`;
- wide blocks use local horizontal scrolling;
- Compose reader surfaces do not parse or search Markdown directly;
- expensive animation surfaces are absent before profile gating;
- remote media is disabled by default for all Android performance profiles;
- diagnostics expose redacted parse/render/search/save timing fields.

## Android-Local Artifacts

Lint reports after this batch:

- `android/app/build/reports/lint-results-debug.html`
- `android/app/build/reports/lint-results-debug.txt`
- `android/app/build/reports/lint-results-debug.xml`
- `android/core/build/reports/lint-results-debug.html`
- `android/core/build/reports/lint-results-debug.txt`
- `android/core/build/reports/lint-results-debug.xml`
- `android/feature/library/build/reports/lint-results-debug.html`
- `android/feature/library/build/reports/lint-results-debug.txt`
- `android/feature/library/build/reports/lint-results-debug.xml`
- `android/feature/reader/build/reports/lint-results-debug.html`
- `android/feature/reader/build/reports/lint-results-debug.txt`
- `android/feature/reader/build/reports/lint-results-debug.xml`
- `android/feature/settings/build/reports/lint-results-debug.html`
- `android/feature/settings/build/reports/lint-results-debug.txt`
- `android/feature/settings/build/reports/lint-results-debug.xml`

Gradle also refreshed:

- `android/build/reports/problems/problems-report.html`

## Remaining Runtime Blockers

Connected/device validation remains blocked in the current local state:

- `adb devices -l` lists no attached Android device or booted emulator.
- `emulator -list-avds` lists `Medium_Phone`, but no emulator was booted during
  this bounded batch.
- Installed SDK system images are Android 36 only; no API 27 system image is
  available under `/Users/wangweiyang/Library/Android/sdk/system-images`.

Keep these L12 runtime/device items open until a matching device or emulator is
available:

- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation, if the supervisor
  requires a small-screen/watch-class runtime rather than source-level profile
  evidence.
- Run Android modern device validation, if the supervisor requires a fresh
  runtime session after this batch rather than the existing 2026-05-09 connected
  emulator evidence.

## Supervisor Checklist Recommendation

The supervising session can use this report as fresh Android-lane evidence for
marking these Android L12 checklist items complete if not already reconciled:

- Run Android `./gradlew lint`.
- Capture Android performance report.

This report also refreshes minimum Android Gradle sanity evidence for:

- `./gradlew projects`.

Earlier Android-local reports remain the stronger evidence for the broader host
build/unit/assemble and connected smoke checklist items:

- `android/docs/reports/stage1-android-l12-build-validation-batch119-20260509.md`
- `android/docs/reports/stage1-android-l12-connected-modern-validation-batch120-20260509.md`
