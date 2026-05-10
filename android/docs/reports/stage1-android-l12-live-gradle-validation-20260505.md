# Stage 1 Android L12 Live Gradle Validation - 2026-05-05

## Scope

This bounded Android live-lane batch advanced the earliest still-open Android-owned
L12 validation cluster without editing `ios/**`, shared `Docs/**` checklists, or
`.cron/**`.

No production Android source changed in this batch. The batch records current
validation evidence and blockers for the Gradle, dependency-resolution, audit, and
device checks that the local environment can reach.

## Environment Findings

| Check | Result | Evidence |
| --- | --- | --- |
| Default `java -version` | BLOCKED | macOS reports `Unable to locate a Java Runtime.` |
| Android Studio JBR | PRESENT | `/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/java -version` reports OpenJDK `21.0.6`. |
| System Gradle runtime | PRESENT | `gradle -v` reports Gradle `9.3.0`, launcher JVM Homebrew OpenJDK `25.0.1`. |
| Android SDK | PRESENT | `local.properties` points to `/Users/wangweiyang/Library/Android/sdk`; API 31, 32, 33, 34, 35, and 36 platform jars are present. |
| Wrapper files | PRESENT | `gradlew`, `gradlew.bat`, `gradle/wrapper/gradle-wrapper.jar`, and `gradle/wrapper/gradle-wrapper.properties` are present. |
| DNS for dependency hosts | BLOCKED | Python `socket.getaddrinfo` fails for `services.gradle.org`, `dl.google.com`, `maven.google.com`, and `repo.maven.apache.org` with `nodename nor servname provided, or not known`. |
| Attached devices | BLOCKED | `adb devices -l` starts successfully but lists no attached devices or running emulators. |

## Validation Commands

All commands were run from `/Users/wangweiyang/GitHub/fastmd/android`.

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew projects` | BLOCKED | Wrapper attempted to download `https://services.gradle.org/distributions/gradle-9.3.0-bin.zip` and failed with `java.net.UnknownHostException: services.gradle.org`. |
| `gradle projects` | PASS | System Gradle resolved root project `fastmd-android` with modules `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `gradle lint` | BLOCKED | Reached `:core:checkDebugAarMetadata`, then failed resolving AndroidX/Kotlin/Compose dependencies because `dl.google.com` does not resolve. |
| `gradle build` | BLOCKED | Reached `:app:checkDebugAarMetadata`, then failed resolving AndroidX/Kotlin/Compose dependencies because `dl.google.com` does not resolve. |
| `gradle :core:testDebugUnitTest` | BLOCKED | Reached `:core:compileDebugKotlin`, then failed resolving `androidx.datastore:datastore-preferences:1.1.1` because Google Maven cannot resolve. |
| `gradle :feature:reader:testDebugUnitTest` | BLOCKED | Reached `:core:compileDebugKotlin`, then failed on the same Google Maven dependency-resolution blocker. |
| `gradle :app:assembleDebug` | BLOCKED | Reached `:app:checkDebugAarMetadata`, then failed resolving Kotlin stdlib, Activity Compose, Lifecycle, DataStore, and Compose BOM from Google Maven. |
| `gradle :app:connectedDebugAndroidTest` | BLOCKED | Reached `:app:checkDebugAarMetadata`, then failed on the same Google Maven dependency-resolution blocker before device execution. |
| `/Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices -l` | BLOCKED | ADB is available but no device or emulator is attached. |
| `gradle stage1AndroidRendererAssetGates stage1AndroidPerformanceReport` | PASS | Ran renderer asset audit, renderer audit self-tests, and performance report audit through Gradle successfully. |
| `bash tools/audit_stage1_manifest.sh` | PASS | Confirmed no broad storage, notification, default `INTERNET`, backup-enabled posture, unexpected exported component, or WebView implementation; release hardening remains present. |
| `bash tools/audit_renderer_assets.sh` | PASS | Confirmed no Android WebView/android.webkit implementation, no React Native/Flutter/Cordova runtime dependency, and no vendored JS/CSS/font renderer asset tree. |
| `bash tools/audit_rich_fixture_render.sh` | PASS | Confirmed native rich fixture coverage, privacy-preserving remote image placeholders, Mermaid/math source-card fallback, and no web runtime. |
| `git diff --check -- android` | PASS | No whitespace errors were reported for Android files. |

## Blockers Preserved

- Wrapper-backed validation remains blocked because `services.gradle.org` cannot be
  resolved to download Gradle `9.3.0`.
- Compile-backed validation with system Gradle remains blocked because Google Maven
  cannot be resolved for AndroidX, Kotlin, and Compose dependencies.
- The Android SDK location is no longer the active blocker in this workspace; API 35
  is present and `local.properties` points at the SDK.
- Connected/device validation remains open because no Android device or emulator is
  attached, and the APK cannot be assembled while dependency resolution is blocked.
- API 27, low-memory/small-screen, and modern-device validation remain open until a
  debug APK can be built and suitable emulator or hardware targets are available.

## Supervisor Checklist Recommendation

This report is evidence for:

- L12: Capture Android security audit report.
- L12: Capture rich fixture render report.
- L13: Record validation reports under `android/docs/reports/`.

Keep these L12 checklist items open from this batch:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.
- Capture Android performance report, unless the supervising session accepts the
  existing source-level `stage1AndroidPerformanceReport` output as sufficient while
  release-like measured timing remains blocked.

The Android-local audit gates passed, but they are source-level validation evidence
only and do not replace the blocked compile, assemble, lint, unit-test, or device
gates above.
