# Stage 1 Android L12 Validation Retry Batch 21 - 2026-05-06

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned
platform validation items:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Capture Android performance report.
- Capture Android security audit report.
- Capture rich fixture render report.
- Preserve current device/API blockers for connected, API 27, small-screen, and
  modern-device validation.

No `ios/**`, shared `Docs/**`, or `.cron/**` files were edited.

## Environment

All commands were run from `/Users/wangweiyang/GitHub/fastmd/android`.

Gradle commands used:

```text
JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home
```

Environment probes:

| Probe | Result | Evidence |
| --- | --- | --- |
| `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | OpenJDK `17.0.17` Homebrew runtime is installed. |
| `/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/java -version` | INFO | Android Studio bundled JBR is OpenJDK `21.0.6`, so this batch used Homebrew OpenJDK 17 for Gradle validation. |
| `ls -l gradlew gradle/wrapper/gradle-wrapper.properties local.properties` | PASS | Android Gradle wrapper, wrapper properties, and `local.properties` are present. |
| `cat local.properties` | PASS | `sdk.dir=/Users/wangweiyang/Library/Android/sdk`. |
| `ls -ld /Users/wangweiyang/Library/Android/sdk/platforms/android-35` | PASS | Android API 35 platform is installed. |
| `ls -ld /Users/wangweiyang/Library/Android/sdk/platforms/android-27` | BLOCKED | No API 27 platform directory was found. |
| `find /Users/wangweiyang/Library/Android/sdk/system-images -maxdepth 4 -type d -name '*27*'` | BLOCKED | No API 27 system image directory was found. |
| `adb devices` | BLOCKED | `adb` is installed, but no attached devices or running emulators are listed. |

## Gradle Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `./gradlew projects --no-daemon` | PASS | Wrapper-backed Gradle evaluated root project `fastmd-android` and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `./gradlew :core:testDebugUnitTest --no-daemon` | BLOCKED | Gradle reached `:core:testDebugUnitTest`, then failed resolving Google Maven AndroidX runtime jars: `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0`; both `https://dl.google.com/...` requests timed out. |
| `./gradlew lint --no-daemon` | BLOCKED | Gradle reached `:core:extractDebugAnnotations`, then failed resolving `com.android.tools.lint:lint-gradle:31.13.2` from `https://dl.google.com/...` with a connection timeout. |
| `./gradlew build --no-daemon` | BLOCKED | Gradle reached `:feature:library:compileDebugKotlin`, then failed resolving `androidx.compose.compiler:compiler:1.5.14` from `https://dl.google.com/...` with a connection timeout. |

## Android Report Gate Results

| Command | Result | Evidence |
| --- | --- | --- |
| `bash tools/audit_performance_report.sh` | PASS | Printed Android performance profile limits and fixture size matrix, then completed with `PASS: Android performance report audit completed.` |
| `bash tools/audit_stage1_manifest.sh` | PASS | No permissions, no broad storage/media/notification/default `INTERNET`, `allowBackup=false`, cleartext disabled, only document-entry `MainActivity` exported, no WebView implementation, release hardening present. |
| `bash tools/audit_renderer_assets.sh` | PASS | No Android WebView/android.webkit implementation, no React Native/Flutter/Cordova runtime, and no vendored JS/CSS/font renderer asset tree are present. |
| `bash tools/audit_rich_fixture_render.sh` | PASS | Rich fixture covers the Stage 1 block/inline matrix; parser/render model and Compose reader paths remain native Kotlin/Compose; wide surfaces are locally scroll-contained; Mermaid/math remain native readable source cards. |
| `./gradlew stage1AndroidPerformanceReport stage1AndroidSecurityAuditReport stage1AndroidRichFixtureRenderReport stage1AndroidRendererAssetGates --no-daemon` | PASS | Gradle-backed report wiring ran `:auditPerformanceReport`, `:auditSecurityReport`, `:auditRichFixtureRenderReport`, `:auditRendererAssets`, and `:testRendererAssetAudit`; build finished successfully in 20s. |

## Blockers Preserved

- L12 Android `./gradlew lint` remains open because Google Maven timed out
  resolving `com.android.tools.lint:lint-gradle:31.13.2`.
- L12 Android `./gradlew build` remains open because Google Maven timed out
  resolving `androidx.compose.compiler:compiler:1.5.14`.
- L12 Android `./gradlew :core:testDebugUnitTest` remains open because Google
  Maven timed out resolving `androidx.collection:collection-ktx:1.4.0` and
  `androidx.concurrent:concurrent-futures:1.1.0`.
- L12 Android `./gradlew :feature:reader:testDebugUnitTest`,
  `./gradlew :app:assembleDebug`, and `./gradlew :app:connectedDebugAndroidTest`
  remain open behind the same Google Maven dependency-resolution blocker and, for
  connected tests, no attached device/emulator.
- L12 Android API 27 validation remains open because no API 27 platform or system
  image was found in `/Users/wangweiyang/Library/Android/sdk`.
- L12 Android low-memory/small-screen and modern-device validation remain open
  because `adb devices` lists no attached target.

## Supervisor Checklist Recommendation

The supervising session can use this report as Android-lane evidence for:

- L12: Capture Android performance report.
- L12: Capture Android security audit report.
- L12: Capture rich fixture render report.
- L13: Record validation reports under `android/docs/reports/`.

Do not mark Android lint, build, unit-test, assemble, connected-device, API 27,
low-memory/small-screen, or modern-device validation complete from this batch.
