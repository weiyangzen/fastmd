# Stage 1 Android L12 Capture Batch 20 - 2026-05-06

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L12
platform validation items that could be advanced without touching `ios/**` or
shared `Docs/**`:

- Capture Android performance report.
- Capture Android security audit report.
- Capture rich fixture render report.
- Retry the minimum Gradle validation and Android unit-test gates far enough to
  preserve exact local blockers.

No production source files were changed in this batch. The implementation work is
the Android-local validation capture and evidence record under
`android/docs/reports/`.

## Changed Android Files

- `android/docs/reports/stage1-android-l12-capture-batch20-20260506.md`

## Environment

Commands were run from `/Users/wangweiyang/GitHub/fastmd/android` unless noted.

- Gradle entry point: `./gradlew`
- `JAVA_HOME`: `/Applications/Android Studio.app/Contents/jbr/Contents/Home`
- Gradle wrapper: Gradle `9.3.0`
- Launcher JVM: JetBrains Runtime `21.0.6`
- Android SDK path from `local.properties`: `/Users/wangweiyang/Library/Android/sdk`
- Installed Android platforms observed: `android-31`, `android-32`,
  `android-33`, `android-34`, `android-35`, `android-36`
- API 27 system image directory: not present at
  `/Users/wangweiyang/Library/Android/sdk/system-images/android-27`
- `adb devices`: no attached devices or running emulators listed

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew --version --no-daemon` | PASS | Wrapper runs Gradle `9.3.0` on the Android Studio bundled JBR. |
| `bash tools/audit_performance_report.sh` | PASS | Source-level performance audit completed. It verified IO dispatching, background parse/search, virtualized reader blocks, async local image decode, stable block ids, remote media disabled by default, diagnostics timing fields, and fixture size matrix. |
| `bash tools/audit_stage1_manifest.sh && bash tools/audit_renderer_assets.sh` | PASS | Security audit completed. No broad permissions or INTERNET permission are declared, `allowBackup=false`, cleartext traffic is disabled, only `MainActivity` is exported, release R8 posture is present, no WebView/android.webkit implementation is present, no React Native/Flutter/Cordova runtime is present, and no vendored JS/CSS/font renderer asset tree is present. |
| `bash tools/audit_rich_fixture_render.sh` | PASS | Rich fixture rendering audit completed. It verified fixture coverage for headings, inline styles, links, blockquotes, lists, tasks, tables, code, Mermaid/math fallbacks, images, video HTML fallback, footnotes, details, generic HTML fallback, CJK/mixed text, escaped markers, parser/render model block kinds, reader native Compose renderer paths, and absence of web-runtime rendering. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew projects stage1AndroidPerformanceReport stage1AndroidSecurityAuditReport stage1AndroidRichFixtureRenderReport --no-daemon` | PASS | Gradle evaluated root project `fastmd-android`, listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`, then ran all three Android L12 capture tasks successfully. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew :core:testDebugUnitTest :feature:reader:testDebugUnitTest --no-daemon` | BLOCKED | Gradle reached `:core:testDebugUnitTest`, then failed resolving `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0` from `https://dl.google.com/dl/android/maven2/...` due `Connect timed out`. The `:feature:reader` unit-test gate did not run because `:core:testDebugUnitTest` failed first. |
| `adb devices` | BLOCKED | `adb` is installed, but the device list is empty. Connected-device validation, API 27 validation, low-memory/small-screen validation, and modern-device validation remain open. |
| `ls /Users/wangweiyang/Library/Android/sdk/system-images/android-27` | BLOCKED | API 27 system image directory is absent locally. |

## Gradle Capture Details

The combined Gradle capture command completed with `BUILD SUCCESSFUL` and executed:

- `:projects`
- `:auditPerformanceReport`
- `:stage1AndroidPerformanceReport`
- `:auditSecurityReport`
- `:stage1AndroidSecurityAuditReport`
- `:auditRichFixtureRenderReport`
- `:stage1AndroidRichFixtureRenderReport`

Gradle also emitted a deprecation warning that the current build uses deprecated
features incompatible with Gradle 10. This did not block Stage 1 L12 capture.

## Preserved Blockers

- Android `./gradlew :core:testDebugUnitTest` remains open because Google Maven
  timed out resolving AndroidX runtime jars.
- Android `./gradlew :feature:reader:testDebugUnitTest` remains open because it
  was not reached after the `:core:testDebugUnitTest` dependency-resolution
  failure.
- Android `./gradlew lint`, `./gradlew build`, and `./gradlew :app:assembleDebug`
  were not rerun in this bounded batch; earlier Google Maven availability
  blockers should remain preserved until a full gate retry succeeds.
- Android `./gradlew :app:connectedDebugAndroidTest` remains open because
  `adb devices` lists no target.
- Android API 27 validation remains open because no API 27 system image or device
  is present in this local environment.
- Android low-memory/small-screen and modern-device validation remain open
  because no attached device or emulator is available.

## Supervisor Checklist Recommendation

The supervising session can use this report as Android-lane evidence to mark:

- L12: Capture Android performance report.
- L12: Capture Android security audit report.
- L12: Capture rich fixture render report.
- L13: Record validation reports under `android/docs/reports/`.

Do not mark Android lint, build, unit-test, assemble, connected-device, API 27,
low-memory/small-screen, or modern-device validation complete from this batch.
