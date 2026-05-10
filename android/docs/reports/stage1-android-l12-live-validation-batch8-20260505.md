# Stage 1 Android L12 Live Validation Batch 8 - 2026-05-05

## Scope

This bounded Android live-lane batch advanced Android-owned L12 validation evidence without editing shared docs or iOS files.

Primary target:

- Re-check the Android Gradle entry points after `android/gradlew` and `android/local.properties` became present.
- Attempt the open Android Gradle gates that the local environment can support.
- Capture Android-local performance, security, rich-fixture, and renderer-gate reports that do not require dependency downloads or an attached device.

## Environment Observations

- Working directory: `/Users/wangweiyang/GitHub/fastmd/android`
- `local.properties`: `sdk.dir=/Users/wangweiyang/Library/Android/sdk`
- Android SDK directory exists and contains `build-tools`, `emulator`, `platform-tools`, `platforms`, `sources`, and `system-images`.
- `/usr/bin/java` lookup fails with `Unable to locate a Java Runtime.`
- System `gradle` is `/usr/local/bin/gradle` and injects `JAVA_HOME=/usr/local/opt/openjdk/libexec/openjdk.jdk/Contents/Home`.
- System Gradle reports Gradle `9.3.0`, launcher JVM Homebrew OpenJDK `25.0.1`.
- `adb devices` returned no attached devices.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED | macOS returned `Unable to locate a Java Runtime.` |
| `./gradlew --version` | BLOCKED | Without `JAVA_HOME`, wrapper failed before Gradle start with `Unable to locate a Java Runtime.` |
| `JAVA_HOME=/usr/local/opt/openjdk/libexec/openjdk.jdk/Contents/Home ./gradlew --version` | BLOCKED | Wrapper found Java but failed to download `https://services.gradle.org/distributions/gradle-9.3.0-bin.zip`: `UnknownHostException: services.gradle.org`. |
| `JAVA_HOME=/usr/local/opt/openjdk/libexec/openjdk.jdk/Contents/Home ./gradlew projects` | BLOCKED | Same wrapper distribution download blocker: `UnknownHostException: services.gradle.org`. |
| `gradle --version` | PASS | System Gradle `9.3.0`, launcher JVM Homebrew OpenJDK `25.0.1`. |
| `gradle projects` | PASS | Resolved root project `fastmd-android` with `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `curl -I --connect-timeout 10 https://dl.google.com/dl/android/maven2/androidx/datastore/datastore-preferences/1.1.1/datastore-preferences-1.1.1.pom` | BLOCKED | DNS failed: `curl: (6) Could not resolve host: dl.google.com`. |
| `gradle :core:testDebugUnitTest` | BLOCKED | Failed at `:core:compileDebugKotlin`; dependency resolution could not reach `dl.google.com` for AndroidX/Kotlin artifacts. |
| `gradle lint` | BLOCKED | Failed at `:core:checkDebugAarMetadata`; dependency resolution could not reach `dl.google.com`. |
| `gradle build` | BLOCKED | Failed at `:app:checkDebugAarMetadata`; dependency resolution could not reach `dl.google.com` for Kotlin, AndroidX, DataStore, Lifecycle, Activity Compose, and Compose BOM artifacts. |
| `gradle :feature:reader:testDebugUnitTest` | BLOCKED | Failed at `:core:compileDebugKotlin`; dependency resolution could not reach `dl.google.com`. |
| `gradle :app:assembleDebug` | BLOCKED | Failed at `:app:checkDebugAarMetadata`; dependency resolution could not reach `dl.google.com`. |
| `gradle :app:connectedDebugAndroidTest` | BLOCKED | Failed before device execution at `:app:checkDebugAarMetadata`; dependency resolution could not reach `dl.google.com`. `adb devices` also listed no attached target. |
| `bash tools/audit_stage1_manifest.sh` | PASS | No permissions; no broad storage, notification, or default `INTERNET`; `allowBackup=false`; cleartext disabled; only `MainActivity` exported; no WebView implementation; release hardening enabled. |
| `bash tools/audit_performance_report.sh` | PASS | Reported Android profile limits and fixture size matrix; performance source audit completed. |
| `bash tools/audit_rich_fixture_render.sh` | PASS | Verified rich fixture coverage, parser/render model block kinds, inline styles, safe inline HTML mappings, native renderer paths, local horizontal scroll constraints, remote image placeholder, Mermaid/math native fallback, and no web app runtime. |
| `bash tools/audit_renderer_assets.sh` | PASS | No Android `WebView`/`android.webkit`, no React Native/Flutter/Cordova runtime, and no vendored JS/CSS/font renderer asset tree. |
| `gradle stage1AndroidPerformanceReport stage1AndroidRendererAssetGates` | PASS | Gradle-backed source audits passed: performance report, renderer asset audit, and renderer asset audit regression harness. |

## Supervisor Checklist Recommendation

The supervising session can use this report as Android evidence for completing these L12/L13 Android-owned documentation and capture items:

- Capture Android performance report.
- Capture Android security audit report.
- Capture rich fixture render report.
- Record validation reports under `android/docs/reports/`.

Do not mark the dependency-backed or device-backed Android validation gates complete from this batch:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

Those gates remain blocked until this lane has a Java runtime visible to the wrapper, DNS access to `services.gradle.org` and `dl.google.com` or a warm dependency cache, and an attached/emulated Android target for connected/device validation.
