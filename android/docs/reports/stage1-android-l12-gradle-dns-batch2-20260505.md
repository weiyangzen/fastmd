# Stage 1 Android L12 Gradle DNS Validation Batch 2 - 2026-05-05

## Scope

This bounded Android batch advanced the open L12 platform validation cluster without editing iOS or the authoritative Stage 1 checklist files.

No Android implementation source was changed. The batch re-ran the smallest real Android validation available locally, then attempted the first SDK-backed Gradle gates and recorded the current blockers.

## Environment Findings

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android`.

| Check | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME` | BLOCKED | Empty in the shell environment. |
| `ANDROID_HOME` | BLOCKED | Empty in the shell environment. |
| `ANDROID_SDK_ROOT` | BLOCKED | Empty in the shell environment. |
| `java -version` | BLOCKED | System Java reports: `Unable to locate a Java Runtime.` |
| `local.properties` | PRESENT | Contains `sdk.dir=/Users/wangweiyang/Library/Android/sdk`. |
| System `gradle` | PASS | Can launch with its bundled/Homebrew JVM and resolve the Android project graph. |
| Checked-in `./gradlew` | BLOCKED | Cannot start because the normal shell has no Java runtime on `PATH` or `JAVA_HOME`. |

## Validation Commands

| Command | Result | Notes |
| --- | --- | --- |
| `./gradlew projects --no-daemon` | BLOCKED | Wrapper cannot start: `Unable to locate a Java Runtime.` |
| `./gradlew lint --no-daemon` | BLOCKED | Same wrapper Java runtime blocker. |
| `gradle projects` | PASS | Resolved root project `fastmd-android` and modules `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `gradle lint` | BLOCKED | Android SDK path is now present, but dependency resolution fails because `dl.google.com` DNS lookup fails while resolving AndroidX/Kotlin artifacts. |
| `gradle :core:testDebugUnitTest` | BLOCKED | Reaches `:core:compileDebugKotlin`, then fails resolving `androidx.datastore:datastore-preferences:1.1.1` and other dependencies from `dl.google.com`. |
| `gradle :feature:reader:testDebugUnitTest` | BLOCKED | Same dependency-resolution blocker through `:core:compileDebugKotlin`. |
| `gradle :app:assembleDebug` | BLOCKED | Reaches `:app:checkDebugAarMetadata`, then fails resolving Kotlin, Compose, Activity, Lifecycle, and DataStore artifacts from `dl.google.com`. |
| `gradle build` | BLOCKED | Same `dl.google.com` DNS/dependency-resolution blocker at `:app:checkDebugAarMetadata`. |

Representative Gradle blocker:

```text
Could not GET 'https://dl.google.com/dl/android/maven2/androidx/datastore/datastore-preferences/1.1.1/datastore-preferences-1.1.1.pom'.
dl.google.com: nodename nor servname provided, or not known
```

## Android-Local Audit Commands

| Command | Result | Notes |
| --- | --- | --- |
| `bash tools/audit_stage1_manifest.sh` | PASS | No permissions; no broad storage, notification, or default `INTERNET`; `allowBackup=false`; cleartext disabled; only document-entry `MainActivity` exported; no WebView implementation; release hardening posture present. |
| `bash tools/audit_renderer_assets.sh` | PASS | No Android `WebView`/`android.webkit`, no React Native/Flutter/Cordova runtime dependency, and no vendored JS/CSS/font renderer asset tree. |
| `bash tools/audit_rich_fixture_render.sh` | PASS | Rich fixture coverage and native Compose render paths are present; Mermaid/math remain native readable fallback cards; code/table/media surfaces are locally horizontally constrained. |

## Blockers Preserved

- Wrapper-based L12 commands remain open until a Java runtime is available to the normal shell through `JAVA_HOME` or `PATH`.
- System Gradle SDK-backed gates are no longer blocked by missing `sdk.dir`; the current blocker is network/DNS resolution for `dl.google.com` Android Maven artifacts.
- Device and emulator gates remain open. This batch did not run `:app:connectedDebugAndroidTest`, API 27 validation, low-memory/small-screen validation, or modern-device validation because assemble/build cannot pass dependency resolution first.

## Supervisor Checklist Recommendation

The supervising session can use this report as fresh Android-lane evidence for:

- L13: Record validation reports under `android/docs/reports/`.
- L12: Capture rich fixture render report, if the supervisor accepts the Android-local rich fixture audit as the required Stage 1 render coverage report.
- L12: Capture Android security audit report, if not already reconciled from earlier Android-local manifest and renderer audits.

Keep these L12 Gradle and device validation gates open:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.
