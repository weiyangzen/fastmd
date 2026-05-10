# Stage 1 Android L12 Host Validation JBR Batch 132 - 2026-05-10

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
validation cluster from `Docs/Stage1_Mobile_Blueprint.md` and
`Docs/todos_20260506.md`:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android product source changes were made. The only intentional repository
write in this batch is this Android-local evidence report.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-host-validation-jbr-batch132-20260510.md`

Gradle also refreshed generated Android-local build artifacts and reports under
`android/build/`, `android/app/build/`, `android/core/build/`, and
`android/feature/*/build/`.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-10.

- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Android SDK path from `android/local.properties`:
  `/Users/wangweiyang/Library/Android/sdk`.
- Installed Android SDK platform used by the project:
  `android-35`.
- Default shell Java state:
  `java -version` is blocked by macOS with `Unable to locate a Java Runtime`.
- Explicit JDK used for passing Gradle commands:
  `/Applications/Android Studio.app/Contents/jbr/Contents/Home`.

The checked-in Gradle wrapper works when `JAVA_HOME` and `PATH` are scoped to
Android Studio's bundled JBR:

```text
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
PATH="/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin:$PATH"
```

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED for default shell | macOS reported `Unable to locate a Java Runtime`. |
| `JAVA_HOME=... PATH=... ./gradlew projects --no-daemon` | PASS | Project graph listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; Gradle reported `BUILD SUCCESSFUL in 8s`. |
| `JAVA_HOME=... PATH=... ./gradlew lint --no-daemon` | PASS | Gradle reported `BUILD SUCCESSFUL in 35s`; `201 actionable tasks: 115 executed, 86 up-to-date`. |
| `JAVA_HOME=... PATH=... ./gradlew :core:testDebugUnitTest --no-daemon` | PASS | Gradle reported `BUILD SUCCESSFUL in 9s`; `17 actionable tasks: 6 executed, 11 up-to-date`. |
| `JAVA_HOME=... PATH=... ./gradlew :feature:reader:testDebugUnitTest --no-daemon` | PASS | Gradle reported `BUILD SUCCESSFUL in 6s`; `29 actionable tasks: 7 executed, 22 up-to-date`. |
| `JAVA_HOME=... PATH=... ./gradlew build --no-daemon` | PASS | Full Android build completed; Gradle reported `BUILD SUCCESSFUL in 3m 2s`; `474 actionable tasks: 245 executed, 229 up-to-date`. |
| `JAVA_HOME=... PATH=... ./gradlew :app:assembleDebug --no-daemon` | PASS | Gradle reported `BUILD SUCCESSFUL in 4s`; `122 actionable tasks: 5 executed, 117 up-to-date`. |

Gradle printed its standard deprecation warning:

```text
Deprecated Gradle features were used in this build, making it incompatible with Gradle 10.
```

This warning did not fail any validation command in this batch.

## Gradle Project Graph

`./gradlew projects` listed the expected Android project graph:

- `:app`
- `:core`
- `:feature:library`
- `:feature:reader`
- `:feature:settings`

## Host Gate Coverage

The passing root `./gradlew lint` run covered:

- `:app:lint`
- `:core:lint`
- `:feature:library:lint`
- `:feature:reader:lint`
- `:feature:settings:lint`

The explicit unit-test commands covered:

- `:core:testDebugUnitTest`
- `:feature:reader:testDebugUnitTest`

The explicit debug assembly command covered:

- `:app:assembleDebug`

The passing root `./gradlew build` run covered debug and release assembly,
debug and release unit-test tasks, lint tasks, and Stage 1 renderer/security
gates, including:

- `auditRendererAssets`
- `auditRendererRequestBlocking`
- `testRendererAssetAudit`
- `testRendererRequestBlockingAudit`
- `stage1AndroidRendererAssetGates`

Representative renderer/security gate output from this batch:

- `PASS: No Android WebView or android.webkit implementation is present.`
- `PASS: No React Native, Flutter, Cordova, or equivalent web runtime dependency is present.`
- `PASS: No vendored JS/CSS/font renderer asset tree is present; Android rich blocks use native fallback paths.`
- `PASS: Renderer request policy is a first-class Android core contract.`
- `PASS: native fallback request policy and tests satisfy the gate.`

`./gradlew build` also emitted this non-failing native-library packaging note:

```text
Unable to strip the following libraries, packaging them as they are: libdatastore_shared_counter.so.
```

## Android-Local Evidence Artifacts

Representative lint reports present after this batch:

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

Representative unit-test reports present after this batch:

- `android/core/build/reports/tests/testDebugUnitTest/index.html`
- `android/core/build/test-results/testDebugUnitTest/`
- `android/feature/reader/build/reports/tests/testDebugUnitTest/index.html`
- `android/feature/reader/build/test-results/testDebugUnitTest/`

Representative APK artifacts present after this batch:

- `android/app/build/outputs/apk/debug/app-debug.apk`
- `android/app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk`
- `android/app/build/outputs/apk/release/app-release-unsigned.apk`

Gradle also refreshed:

- `android/build/reports/problems/problems-report.html`

## Remaining Runtime Scope

This host-validation batch did not run a new connected/device validation,
Android API 27 runtime validation, low-memory/small-screen runtime validation,
modern-device runtime validation, or a new Android performance capture. Keep
those L12 runtime/device/performance items open unless covered by separate
Android-local reports from a matching attached device, emulator, or performance
capture batch.

## Supervisor Checklist Recommendation

The supervising session can use this report as fresh Android-lane evidence for
marking these Android L12 checklist items complete if not already reconciled:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.

Use this report as minimum Android validation sanity evidence for:

- `./gradlew projects`.

Do not use this report to newly claim completion for connected-device, API 27
runtime, low-memory/small-screen runtime, modern-device runtime, or Android
performance report items.
