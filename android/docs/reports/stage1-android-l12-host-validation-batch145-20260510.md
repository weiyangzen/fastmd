# Stage 1 Android L12 Host Validation Batch 145 - 2026-05-10

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
host validation items in `Docs/Stage1_Mobile_Blueprint.md` and
`Docs/todos_20260506.md`:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.

This batch stayed inside `android/**`. It did not edit `ios/**`, shared
`Docs/**`, or `.cron/**`.

No Android product source changes were required. The only intentional repository
write in this batch is this Android-local evidence report.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-host-validation-batch145-20260510.md`

Gradle also refreshed generated Android-local build metadata and reports under
ignored `build/` directories while running validation tasks.

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` on
2026-05-10.

- Gradle entry point: checked-in wrapper `./gradlew`, Gradle `9.3.0`.
- Android SDK path from `local.properties`:
  `/Users/wangweiyang/Library/Android/sdk`.
- Installed compile SDK platform confirmed:
  `/Users/wangweiyang/Library/Android/sdk/platforms/android-35/android.jar`.
- Default shell Java remains blocked.
- Explicit JDK used for successful Gradle validation:
  `/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`.
- Explicit Java version:
  `openjdk version "17.0.17" 2025-10-21`.

The default shell still does not expose Java:

```text
./gradlew projects
The operation couldn't be completed. Unable to locate a Java Runtime.
Please visit http://www.java.com for information on installing Java.
```

The checked-in Gradle wrapper works when `JAVA_HOME` and `PATH` are scoped to
the Homebrew OpenJDK 17 path above.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `./gradlew projects` | BLOCKED in default shell | macOS reported `Unable to locate a Java Runtime` before Gradle could start. |
| `JAVA_HOME=... java -version` | PASS | Reported Homebrew OpenJDK `17.0.17`. |
| `JAVA_HOME=... PATH=... ./gradlew projects --console=plain --no-daemon` | PASS | Project graph listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; Gradle reported `BUILD SUCCESSFUL in 13s`. |
| `JAVA_HOME=... PATH=... ./gradlew lint --console=plain --no-daemon` | PASS | Gradle reported `BUILD SUCCESSFUL in 21s`; `201 actionable tasks: 10 executed, 191 up-to-date`. |
| `JAVA_HOME=... PATH=... ./gradlew :core:testDebugUnitTest --console=plain --no-daemon` | PASS | Gradle reported `BUILD SUCCESSFUL in 16s`; `17 actionable tasks: 1 executed, 16 up-to-date`. |
| `JAVA_HOME=... PATH=... ./gradlew :feature:reader:testDebugUnitTest --console=plain --no-daemon` | PASS | Gradle reported `BUILD SUCCESSFUL in 17s`; `29 actionable tasks: 2 executed, 27 up-to-date`. |
| `JAVA_HOME=... PATH=... ./gradlew :app:assembleDebug --console=plain --no-daemon` | PASS | Gradle reported `BUILD SUCCESSFUL in 17s`; `122 actionable tasks: 5 executed, 117 up-to-date`. |
| `JAVA_HOME=... PATH=... ./gradlew build --console=plain --no-daemon` | PASS | Full Android build completed; Gradle reported `BUILD SUCCESSFUL in 2m 31s`; `474 actionable tasks: 17 executed, 457 up-to-date`. |

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

The successful root `./gradlew lint` run covered:

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

The successful root `./gradlew build` run covered debug and release assembly,
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
- `PASS: WebView renderer with policy routing and interception satisfies the gate.`

## Android-Local Evidence Artifacts

Representative lint reports present after this batch:

- `android/app/build/reports/lint-results-debug.html`
- `android/core/build/reports/lint-results-debug.html`
- `android/feature/library/build/reports/lint-results-debug.html`
- `android/feature/reader/build/reports/lint-results-debug.html`
- `android/feature/settings/build/reports/lint-results-debug.html`

Representative unit-test reports present after this batch:

- `android/core/build/reports/tests/testDebugUnitTest/index.html`
- `android/feature/reader/build/reports/tests/testDebugUnitTest/index.html`

Representative APK artifacts present after this batch:

- `android/app/build/outputs/apk/debug/app-debug.apk`
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
