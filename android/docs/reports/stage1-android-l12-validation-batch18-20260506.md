# Stage 1 Android L12 Validation Batch 18 - 2026-05-06

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
validation surface. This batch did not edit `Docs/**`, `ios/**`, or `.cron/**`.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-validation-batch18-20260506.md`

## Environment

- Working directory: `/Users/wangweiyang/GitHub/fastmd/android`
- Explicit JDK 17 used for Gradle:
  `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`
- Android Gradle wrapper: `./gradlew`
- Default shell Java remains unavailable unless `JAVA_HOME` is supplied.
- `adb` is available, but no Android device or emulator is attached.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED | Default shell environment reports `Unable to locate a Java Runtime.` |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew projects --no-daemon` | PASS | Wrapper evaluated root project `fastmd-android` and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew lint --no-daemon` | BLOCKED | Gradle reached `:core:extractDebugAnnotations`, then timed out resolving `com.android.tools.lint:lint-gradle:31.13.2` from `https://dl.google.com/dl/android/maven2/...`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew :core:testDebugUnitTest --no-daemon` | BLOCKED | Gradle reached `:core:testDebugUnitTest`, then timed out downloading AndroidX runtime jars `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0` from `https://dl.google.com/dl/android/maven2/...`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew stage1AndroidRendererAssetGates stage1AndroidPerformanceReport stage1AndroidSecurityAuditReport stage1AndroidRichFixtureRenderReport --no-daemon` | PASS | Gradle-backed Android source audits passed for renderer asset gates, performance report, security audit report, and rich fixture render report. |
| `adb devices` | BLOCKED for device validation | Command ran, but the device list was empty. |

## Source Audit Evidence

`stage1AndroidRendererAssetGates` passed and confirmed:

- no Android `WebView` or `android.webkit` implementation is present;
- no React Native, Flutter, Cordova, or equivalent web runtime dependency is present;
- no vendored JS/CSS/font renderer asset tree is present;
- synthetic regression cases fail for missing/stale/escaping renderer hash manifests,
  misplaced asset roots, remote subresources, dangerous URL schemes, WebView marker
  code, and web-runtime dependencies.

`stage1AndroidPerformanceReport` passed and printed the Stage 1 Android runtime
profile limits plus the fixture size matrix.

`stage1AndroidSecurityAuditReport` passed and confirmed:

- no manifest `uses-permission` declarations;
- no broad storage, media, notification, or default `INTERNET` permission;
- `allowBackup=false`;
- cleartext network traffic disabled;
- only `MainActivity` exported;
- release build type uses non-debuggable output, minify, resource shrinking, and
  app ProGuard rules.

`stage1AndroidRichFixtureRenderReport` passed and confirmed the rich Markdown
fixture remains covered by native Kotlin/Compose parser and reader paths, including
Mermaid/math native fallback cards and remote-image placeholders without a web app
runtime.

## Blockers Preserved

- L12 `./gradlew lint` remains open because Google Maven timed out resolving
  Android lint artifacts.
- L12 `./gradlew :core:testDebugUnitTest` remains open because Google Maven timed
  out resolving AndroidX runtime artifacts.
- L12 `./gradlew build`, `./gradlew :feature:reader:testDebugUnitTest`,
  `./gradlew :app:assembleDebug`, and `./gradlew :app:connectedDebugAndroidTest`
  remain open behind the same Google Maven and device-availability blockers until
  retried successfully.
- Android API 27, low-memory/small-screen, and modern-device validation remain
  open because `adb devices` listed no attached target.

## Supervisor Checklist Recommendation

The supervising session can use this report as Android-lane evidence for:

- L12: Capture Android performance report.
- L12: Capture Android security audit report.
- L12: Capture rich fixture render report.
- L13: Record validation reports under `android/docs/reports/`.

Do not mark Android lint, build, core unit test, reader unit test, assemble,
connected-device, API 27, low-memory/small-screen, or modern-device validation
complete from this batch.
