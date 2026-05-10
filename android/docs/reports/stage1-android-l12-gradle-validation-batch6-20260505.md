# Stage 1 Android L12 Gradle Validation Batch 6 - 2026-05-05

## Scope

This bounded Android live-lane batch re-ran the earliest still-open Android-owned
L12 validation gates that can be reached from the current local environment.

No shared `Docs/**` checklist, `ios/**`, or `.cron/**` files were changed. No
production Android source changed. This report records the exact pass/blocker
state so the supervising session can reconcile checklist truth without concurrent
edits to the authoritative blueprint.

## Environment

All commands were run from:

```text
/Users/wangweiyang/GitHub/fastmd/android
```

Environment findings:

| Check | Result | Evidence |
| --- | --- | --- |
| Default `java -version` | BLOCKED | macOS reports `Unable to locate a Java Runtime.` |
| Android Studio JBR | PRESENT | `/Applications/Android Studio.app/Contents/jbr/Contents/Home` exists and was used as `JAVA_HOME`. |
| System Gradle | PRESENT | `gradle projects` runs with Gradle `9.3.0`. |
| Android SDK | PRESENT | `local.properties` contains `sdk.dir=/Users/wangweiyang/Library/Android/sdk`. |
| Android devices | BLOCKED | `adb devices` starts successfully but lists no attached device or running emulator. |
| Google Maven DNS | BLOCKED | `curl -I https://dl.google.com/dl/android/maven2/androidx/compose/compose-bom/2024.06.00/compose-bom-2024.06.00.pom` fails with `Could not resolve host: dl.google.com`. |
| Gradle wrapper DNS | BLOCKED | `./gradlew projects` attempts to download `https://services.gradle.org/distributions/gradle-9.3.0-bin.zip` and fails with `java.net.UnknownHostException: services.gradle.org`. |

## Validation Commands

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew projects` | BLOCKED | Wrapper download failed before project evaluation with `java.net.UnknownHostException: services.gradle.org`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle projects` | PASS | System Gradle resolved root project `fastmd-android` with `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle lint` | BLOCKED | Reached `:core:checkDebugAarMetadata`, then failed resolving `androidx.datastore:datastore-preferences:1.1.1`, `org.jetbrains.kotlin:kotlin-stdlib:1.9.24`, and `androidx.compose:compose-bom:2024.06.00` because `dl.google.com` does not resolve. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle build` | BLOCKED | Reached `:app:checkDebugAarMetadata`, then failed resolving Kotlin, AndroidX Activity, Lifecycle, DataStore, and Compose artifacts because `dl.google.com` does not resolve. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle :core:testDebugUnitTest` | BLOCKED | Reached `:core:compileDebugKotlin`, then failed resolving AndroidX/Kotlin/Compose dependencies from Google Maven. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle :feature:reader:testDebugUnitTest` | BLOCKED | Reached `:core:compileDebugKotlin`, then failed on the same Google Maven DNS dependency-resolution blocker before reader tests could compile. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle :app:assembleDebug` | BLOCKED | Reached `:app:checkDebugAarMetadata`, then failed resolving Kotlin stdlib, Activity Compose, Lifecycle, DataStore, Compose BOM, and Compose UI tooling because `dl.google.com` does not resolve. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle :app:connectedDebugAndroidTest` | BLOCKED | Reached `:app:checkDebugAarMetadata`, then failed on the same Google Maven DNS blocker before connected-device execution. `adb devices` also listed no attached target. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle stage1AndroidRendererAssetGates stage1AndroidPerformanceReport` | PASS | Renderer asset audit, renderer audit regression cases, and Android source-level performance report audit passed through Gradle. |
| `bash tools/audit_stage1_manifest.sh` | PASS | Confirmed no Android permissions, no broad storage/notification/default `INTERNET`, `allowBackup=false`, cleartext disabled, only `MainActivity` exported, no WebView implementation, and release hardening posture. |
| `bash tools/audit_rich_fixture_render.sh` | PASS | Confirmed rich fixture category coverage, native Kotlin/Compose renderer paths, remote image placeholder posture, Mermaid/math source-card fallback, and no web app runtime. |

## Passed Source-Level Audit Evidence

The Android-local source audits that do not require external dependency downloads
passed in this batch:

- Renderer asset gates: no WebView/android.webkit implementation, no React
  Native/Flutter/Cordova runtime dependency, no vendored JS/CSS/font renderer
  tree, and regression cases fail closed for future unsafe renderer assets.
- Performance report: Android runtime profile limits are present; local fixture
  matrix is present; IO, parsing, search, reader virtualization, remote media
  defaults, and diagnostics redaction posture pass the source audit.
- Security manifest audit: Stage 1 has no install/runtime permissions or default
  network permission, explicitly disables backup and cleartext traffic, exports
  only the document-entry activity, and keeps release builds non-debuggable with
  R8/resource shrinking enabled.
- Rich fixture render audit: parser and reader source paths cover the Stage 1
  rich Markdown surface with native fallback cards for heavy/special rich blocks.

## Blockers Preserved

- Wrapper-backed validation remains blocked because `services.gradle.org` cannot
  be resolved for the Gradle `9.3.0` distribution.
- Compile-backed validation with system Gradle remains blocked because
  `dl.google.com` cannot be resolved for AndroidX, Kotlin, and Compose
  dependency metadata.
- The Android SDK path is not the active blocker in this workspace; `sdk.dir` is
  configured under `android/local.properties`.
- `:app:connectedDebugAndroidTest`, API 27 validation, low-memory/small-screen
  validation, and modern-device validation remain blocked until dependencies can
  resolve, a debug APK can be assembled, and a suitable emulator or hardware
  target is attached.

## Supervisor Checklist Recommendation

The supervising session can use this report as fresh evidence for:

- L13: Record validation reports under `android/docs/reports/`.

The following Android L12 checklist items should remain open from this batch:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

The source-level Android performance, security, and rich fixture audits passed,
but this batch does not upgrade those into release/device validation claims while
Gradle dependency resolution and connected-device execution are blocked.
