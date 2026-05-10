# Stage 1 Android L13 README Validation Batch 49

Date: 2026-05-06
Lane: FastMD Stage 1 Mobile Android live lane
Scope: Android-only. No `ios/**`, shared `Docs/**` checklist files, or `.cron/**` files were edited.

## Batch Selection

The earliest still-open Android-owned blueprint items after the already-evidenced
conditional renderer gates are in L12/L13:

- L12 Android platform validation evidence.
- L13 update `android/README.md` with final build/test commands after the Android skeleton lands.
- L13 record validation reports under `android/docs/reports/`.

This batch tightened the Android README command surface so the canonical commands
use the checked-in wrapper with explicit JDK 17 and Android SDK environment
variables, and moved Gradle-backed source report tasks into a dedicated wrapper
command block.

## Implementation Evidence

- `README.md`
  - Documents canonical wrapper validation with `JAVA_HOME` pinned to the local
    OpenJDK 17 install and `ANDROID_HOME` pinned to the local Android SDK.
  - Keeps system Gradle as a fallback only for wrapper distribution download
    problems.
  - Separates direct source-level audit scripts from wrapper-backed aggregate
    report tasks:
    - `stage1AndroidRendererAssetGates`
    - `stage1AndroidPerformanceReport`
    - `stage1AndroidSecurityAuditReport`
    - `stage1AndroidRichFixtureRenderReport`

## Environment

- Working directory: `/Users/wangweiyang/GitHub/fastmd/android`
- JDK 17 used: `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`
- Android SDK: `/Users/wangweiyang/Library/Android/sdk`
- `local.properties`: `sdk.dir=/Users/wangweiyang/Library/Android/sdk`
- Installed Android platforms observed: API 31, 32, 33, 34, 35, and 36.
- Attached devices/emulators: none.

## Validation Results

| Command | Result | Notes |
| --- | --- | --- |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk ./gradlew projects --no-daemon` | PASS | Resolved root project `fastmd-android` and modules `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 12s`. |
| `bash tools/audit_renderer_assets.sh` | PASS | Confirmed no Android `WebView`/`android.webkit` implementation, no React Native/Flutter/Cordova/equivalent web runtime dependency, and no vendored JS/CSS/font renderer asset tree. |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Confirmed native fallback passes and synthetic future renderer asset/WebView/runtime regressions fail closed, including missing/stale/malformed manifests, bad paths, remote/navigation/network-capable APIs, WebView markers, and React Native markers. |
| `bash tools/audit_stage1_manifest.sh` | PASS | Confirmed no permission declarations, no broad storage/media/notification/default `INTERNET`, `allowBackup=false`, cleartext disabled, only document-entry `MainActivity` exported, no WebView implementation, and release hardening posture present. |
| `adb devices` | BLOCKED for device validation | Output listed only `List of devices attached`; no attached device or running emulator was available. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk ./gradlew stage1AndroidRendererAssetGates stage1AndroidPerformanceReport stage1AndroidSecurityAuditReport stage1AndroidRichFixtureRenderReport --no-daemon` | PASS | Executed renderer, performance, security, and rich fixture report tasks; `BUILD SUCCESSFUL in 39s`. |

## Supervisor Checklist Candidates

The supervisor can mark these Android-owned items complete:

- L13: Update `android/README.md` with final build/test commands after Android skeleton lands.
  - Evidence: `README.md` and this report.
- L13: Record validation reports under `android/docs/reports/`.
  - Evidence: this report.

This batch also refreshes evidence for these already-implemented Android L12 capture
items, without claiming device-backed gates:

- L12: Capture Android performance report.
  - Evidence: `./gradlew stage1AndroidPerformanceReport` passed.
- L12: Capture Android security audit report.
  - Evidence: `./gradlew stage1AndroidSecurityAuditReport` passed.
- L12: Capture rich fixture render report.
  - Evidence: `./gradlew stage1AndroidRichFixtureRenderReport` passed.

Keep these Android validation items open:

- `./gradlew lint`, `./gradlew build`, `./gradlew :core:testDebugUnitTest`,
  `./gradlew :feature:reader:testDebugUnitTest`, and `./gradlew :app:assembleDebug`
  were not run in this documentation-focused batch.
- `./gradlew :app:connectedDebugAndroidTest`, API 27 validation,
  low-memory/small-screen validation, and modern-device validation remain open
  because no Android device or emulator was attached.
