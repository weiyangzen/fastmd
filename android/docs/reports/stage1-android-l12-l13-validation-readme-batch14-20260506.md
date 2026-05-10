# Stage 1 Android L12/L13 Validation and README Evidence Batch 14 - 2026-05-06

## Scope

Android live-lane bounded batch for the earliest currently open Android-owned validation/documentation
surface:

- L12: Run Android `./gradlew lint`.
- L13: Update `android/README.md` with final build/test commands after Android skeleton lands.
- L13: Record validation reports under `android/docs/reports/`.

This batch did not edit `Docs/Stage1_Mobile_Blueprint.md`, `Docs/todos_20260505.md`, `ios/**`,
or `.cron/**`.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-l13-validation-readme-batch14-20260506.md`

## README Evidence

`android/README.md` already contains the final Android build/test command set for the Stage 1
skeleton:

- `./gradlew projects`
- `./gradlew lint`
- `./gradlew build`
- `./gradlew :core:testDebugUnitTest`
- `./gradlew :feature:reader:testDebugUnitTest`
- `./gradlew :app:assembleDebug`
- `./gradlew :app:connectedDebugAndroidTest`

It also documents:

- JDK 17 requirement.
- Android SDK/API 35 requirement and `local.properties`/`ANDROID_HOME` setup.
- Gradle wrapper location and pinned Gradle `9.3.0`.
- System Gradle fallback commands when wrapper bootstrap is blocked.
- Device-backed validation requirements for API 27, low-memory/small-screen, modern-device, and
  connected Android test gates.
- Android-owned source-level audit commands for renderer assets, security, performance, diagnostics,
  accessibility, font tiers, save integrity, parser source ranges, and rich fixture rendering.

No README edit was needed in this batch because the current file already satisfies the Android-owned
L13 command documentation requirement.

## Environment

- Working directory: `android/`
- Default shell `java -version`: blocked with `Unable to locate a Java Runtime`.
- Explicit validation JVM: `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`.
- Gradle wrapper distribution: cached locally and usable for project evaluation.
- Android SDK path: `local.properties` points at the local Android SDK.
- Device state: `adb devices` ran, but no emulator or physical Android device was attached.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `./gradlew projects --no-daemon` | BLOCKED with default shell env | Fails before Gradle because the shell cannot locate a Java runtime. |
| `java -version` | BLOCKED with default shell env | `Unable to locate a Java Runtime.` |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew projects --no-daemon` | PASS | Wrapper evaluated the Android project and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew lint --no-daemon` | BLOCKED | Reached `:core:extractDebugAnnotations`, then failed resolving `com.android.tools.lint:lint-gradle:31.13.2` from Google Maven because `dl.google.com:443` timed out. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew stage1AndroidRendererAssetGates stage1AndroidPerformanceReport stage1AndroidSecurityAuditReport stage1AndroidRichFixtureRenderReport --no-daemon` | PASS | Script-backed Gradle gates passed for renderer asset packaging/offline checks, performance report, security audit, and rich fixture render report. |
| `bash tools/audit_font_scale_tiers.sh` | PASS | Four Android font tiers remain discrete and scale through system font scale. |
| `bash tools/audit_accessibility_semantics.sh` | PASS | Android accessibility semantics source audit completed. |
| `bash tools/audit_diagnostics_redaction.sh` | PASS | Android diagnostics redaction source audit completed. |
| `adb devices` | BLOCKED for device validation | Command is available, but device list is empty. |

## Blocker Details

The wrapper and project graph are now usable when JDK 17 is supplied explicitly:

```text
Root project 'fastmd-android'
+--- Project ':app'
+--- Project ':core'
\--- Project ':feature'
     +--- Project ':feature:library'
     +--- Project ':feature:reader'
     \--- Project ':feature:settings'
```

The `lint` gate remains open because Android lint's own Gradle artifact could not be fetched:

```text
Execution failed for task ':core:extractDebugAnnotations'.
Could not resolve com.android.tools.lint:lint-gradle:31.13.2.
Could not GET 'https://dl.google.com/dl/android/maven2/com/android/tools/lint/lint-gradle/31.13.2/lint-gradle-31.13.2.pom'.
Connect to dl.google.com:443 failed: Connect timed out
```

Device-backed gates remain open because `adb devices` returned no attached target:

```text
List of devices attached
```

## Supervisor Checklist Candidates

The supervisor can consider these Android-owned items complete, with this report plus the current
`android/README.md` as evidence:

- L13: Update `android/README.md` with final build/test commands after Android skeleton lands.
  - Evidence: `android/README.md` lists wrapper commands, system Gradle fallbacks, source-level audit
    commands, JDK/SDK prerequisites, and device-backed validation requirements.
- L13: Record validation reports under `android/docs/reports/`.
  - Evidence: this report.

Keep these Android-owned items open:

- L12: Run Android `./gradlew lint`.
  - Blocker: Google Maven timeout resolving `com.android.tools.lint:lint-gradle:31.13.2`.
- L12: Run Android `./gradlew build`.
- L12: Run Android `./gradlew :core:testDebugUnitTest`.
- L12: Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- L12: Run Android `./gradlew :app:assembleDebug`.
- L12: Run Android `./gradlew :app:connectedDebugAndroidTest`.
- L12: Run Android API 27 validation.
- L12: Run Android low-memory/small-screen profile validation.
- L12: Run Android modern device validation.

Compile-backed gates remain open until Google Maven is reachable or the required Android lint and
compile artifacts are available in the local Gradle cache. Device-backed gates remain open until
API 27 and modern Android targets are attached or running.
