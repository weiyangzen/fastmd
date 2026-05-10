# Stage 1 Android L12 Lint Validation - Batch 45 - 2026-05-06

## Scope

This bounded Android live-lane batch targeted the earliest unconditional
Android-owned open validation item:

- L12: Run Android `./gradlew lint`.

No shared `Docs/**`, `ios/**`, or `.cron/**` files were edited. The Android app
remains native Kotlin / Jetpack Compose. No React Native, Flutter, Cordova,
remote WebView shell, or other web app runtime was introduced.

The preceding L11 renderer asset gates are conditional on Android using local
JS/CSS/font renderer assets or WebView renderer surfaces. The current Android
tree still has no `app/src/main/assets/fastmd-renderers` asset tree and no
Android `WebView` implementation in the native main code, so this batch moved to
the first unconditional Android L12 gate.

## Environment

- Working directory: `android/`
- Wrapper entry point: `./gradlew`
- Wrapper Gradle version observed through `./gradlew projects`: `9.3.0`
- Explicit `JAVA_HOME`: `/Applications/Android Studio.app/Contents/jbr/Contents/Home`
- Explicit Java runtime: OpenJDK `21.0.6` JetBrains Runtime
- Device probe: `adb devices` listed no attached Android devices or running emulators

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" java -version` | PASS | OpenJDK `21.0.6` JetBrains Runtime was available through explicit `JAVA_HOME`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew projects` | PASS | Gradle evaluated the project and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `adb devices` | BLOCKED FOR DEVICE GATES | No attached Android device or running emulator was listed. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew lint` | BLOCKED | `:core:extractDebugAnnotations` failed while resolving Android lint from Google Maven. |

## Lint Blocker Detail

`./gradlew lint` reached `:core:extractDebugAnnotations` and failed resolving the
Android lint Gradle artifact:

```text
Execution failed for task ':core:extractDebugAnnotations'.
> Could not resolve all files for configuration ':core:detachedConfiguration1'.
   > Could not resolve com.android.tools.lint:lint-gradle:31.13.2.
     Required by:
         project ':core'
      > Could not resolve com.android.tools.lint:lint-gradle:31.13.2.
         > Could not get resource 'https://dl.google.com/dl/android/maven2/com/android/tools/lint/lint-gradle/31.13.2/lint-gradle-31.13.2.pom'.
            > Could not GET 'https://dl.google.com/dl/android/maven2/com/android/tools/lint/lint-gradle/31.13.2/lint-gradle-31.13.2.pom'.
               > Connect to dl.google.com:443 [dl.google.com/142.250.197.142, dl.google.com/2404:6800:4005:822:0:0:0:200e] failed: Connect timed out
```

Because the command did not complete, the Android `./gradlew lint` L12 gate must
remain open.

## Additional Observation

During the same lint invocation, the Kotlin daemon initially failed and Gradle
fell back to non-daemon compilation:

```text
Caused by: java.lang.IllegalArgumentException: 25.0.1
Using fallback strategy: Compile without Kotlin daemon
```

That was not the final blocker for this run; the final task failure was the
Google Maven timeout while resolving `com.android.tools.lint:lint-gradle:31.13.2`.

## Supervisor Reconciliation Notes

- Minimum required Android validation for this batch was satisfied with
  `./gradlew projects`.
- L12: Run Android `./gradlew lint` remains open because Google Maven timed out
  resolving `com.android.tools.lint:lint-gradle:31.13.2`.
- Device-backed Android gates remain open because no device or emulator was
  attached.
- L13: Record validation reports under `android/docs/reports/` can be advanced
  with this report if the supervising session has not already reconciled that
  item.
