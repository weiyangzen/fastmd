# FastMD Android

移动端 Stage 1 的产品与工程蓝图放在 [../Docs/Stage1_Mobile_Blueprint.md](../Docs/Stage1_Mobile_Blueprint.md)。

本目录只承载 Android 实现。Stage 1 Android 的最低版本为 Android 8.1 / API 27：

```kotlin
minSdk = 27
targetSdk = 35
compileSdk = 35
```

## Reference Baseline

- 参考仓库路径：`../alphane-android`
- 实际远端：`https://github.com/alphane-ai/alphane-mobile-android.git`
- 当前参考提交：`f0dfc56 update`
- 参考技术栈：AGP `8.13.2`、Kotlin `1.9.24`、JDK `17`
- FastMD 调整：Android 最低支持从参考仓库的旧基线统一定为 `minSdk 27`，覆盖 Android 8.1 主流全安卓手表和旧设备。

## Environment Prerequisites

Run Android commands from this directory:

```bash
cd android
```

Required local setup:

- JDK 17 available on `JAVA_HOME` or `PATH`.
- Android SDK with API 35 installed.
- Either `ANDROID_HOME` points at the SDK, or `local.properties` contains:

```properties
sdk.dir=/absolute/path/to/android/sdk
```

The Android Gradle wrapper is checked in under this directory and pins Gradle `9.3.0`.
First wrapper use downloads `https://services.gradle.org/distributions/gradle-9.3.0-bin.zip` into the local Gradle cache.

If Google Maven is unreachable from the local network but a regional mirror is
allowed, Gradle can opt in to Android-local mirror repositories for validation:

```bash
./gradlew -Pfastmd.useChinaMavenMirror=true projects
```

The mirror flag is intentionally opt-in. Default builds continue to use the
standard `google()`, `mavenCentral()`, and Gradle Plugin Portal repositories.

## Local Gates

Canonical Stage 1 Android validation uses the checked-in wrapper with JDK 17 and
the local Android SDK:

```bash
export JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home
export ANDROID_HOME=/Users/wangweiyang/Library/Android/sdk
./gradlew projects
./gradlew lint
./gradlew build
./gradlew :core:testDebugUnitTest
./gradlew :feature:reader:testDebugUnitTest
./gradlew :app:assembleDebug
./gradlew :app:connectedDebugAndroidTest
```

If the wrapper distribution cannot be downloaded in a local environment, use the
same task list with system Gradle only as a fallback:

```bash
gradle projects
gradle lint
gradle build
gradle :core:testDebugUnitTest
gradle :feature:reader:testDebugUnitTest
gradle :app:assembleDebug
gradle :app:connectedDebugAndroidTest
```

Device-backed validation requires an attached Android device or a running emulator:

- API 27 validation should use an Android 8.1 / API 27 target.
- Low-memory/small-screen validation should use the compact performance profile on a small-screen target.
- Modern-device validation should use a Snapdragon 865/888-class or comparable target.
- `:app:connectedDebugAndroidTest` must remain open when `adb devices` lists no target.

## Android-Owned Audits

These source-level gates do not require an emulator:

```bash
bash tools/audit_renderer_assets.sh
bash tools/audit_renderer_request_blocking.sh
bash tools/test_renderer_asset_audit.sh
bash tools/test_renderer_request_blocking_audit.sh
bash tools/audit_stage1_manifest.sh
bash tools/audit_font_scale_tiers.sh
bash tools/audit_parser_source_ranges.sh
bash tools/audit_save_integrity.sh
bash tools/audit_accessibility_semantics.sh
bash tools/audit_diagnostics_redaction.sh
bash tools/audit_performance_report.sh
bash tools/audit_rich_fixture_render.sh
```

The wrapper-backed aggregate report tasks are:

```bash
./gradlew stage1AndroidRendererAssetGates
./gradlew stage1AndroidPerformanceReport
./gradlew stage1AndroidSecurityAuditReport
./gradlew stage1AndroidRichFixtureRenderReport
```

`test_renderer_asset_audit.sh` is the Android-local regression test for the conditional
renderer asset gates. It verifies that the native fallback path passes without
vendored JS/CSS/font assets, and that any future local renderer asset tree must stay
under `app/src/main/assets/fastmd-renderers/`, include a valid SHA-256 manifest, avoid
remote subresources, and fail if a WebView implementation appears without the
separate request-blocking gate.

`audit_renderer_request_blocking.sh` is the Android-local request-blocking contract
gate. It verifies that the renderer request policy and unit tests cover bundled
asset allowlisting, remote request blocking, external navigation blocking,
`javascript:` and `data:` URL blocking, content URI blocking, percent-encoded
dangerous URLs, and iframe denial. If a future Android WebView renderer is added,
the gate also requires request interception, navigation interception, and policy
routing in main source code before the aggregate renderer gate can pass.
`test_renderer_request_blocking_audit.sh` regression-tests that contract against
synthetic native-fallback, missing-contract, unrouted-WebView, partially routed
WebView, and fully routed WebView project trees.

`stage1AndroidRendererAssetGates` exposes the same renderer asset checks through
Gradle and wires the regression audit into Android module `check` tasks. The task is
configuration-only and script-backed, so it can run even when no renderer assets are
currently vendored.

`audit_performance_report.sh` is the Android-local source-level performance report
gate. It verifies that document IO and local image decode run off the main thread,
Markdown parse and search summarization run on `Dispatchers.Default`, reader blocks
are virtualized with stable ids, remote media stays disabled by default across all
runtime profiles, and diagnostics expose redacted parse/render/search/save timings.
`stage1AndroidPerformanceReport` exposes the same report through Gradle when the
local Gradle runtime can evaluate the project.

`stage1AndroidSecurityAuditReport` captures the Android-local security audit
surface through Gradle. It runs the manifest posture audit and renderer asset
audit together, covering permission exclusions, backup/cleartext posture,
exported component scope, WebView absence, web-runtime exclusions, and local
renderer asset hash/offline requirements.

`stage1AndroidRichFixtureRenderReport` captures the Android-local rich fixture
rendering audit through Gradle. It verifies the native parser/render model,
Compose reader paths, wide-surface containment, remote-image placeholder
posture, Mermaid/math fallback cards, and absence of WebView/web-runtime
rendering for `test-fixtures/markdown/rich-preview.md`.

## Validation Evidence

Platform validation evidence is recorded under `docs/reports/`.

Each Android live-lane batch should record:

- The exact JDK and Gradle entry point used.
- Each Gradle gate attempted, with pass, fail, or blocker status.
- Device/emulator availability from `adb devices`.
- API 27 system image or target availability when API 27 validation is attempted.
- Source-level audit command output for security, renderer assets, rich fixture rendering, and performance reports when those capture gates are advanced.
