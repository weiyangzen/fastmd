# Stage 1 Android L12/L13 Live Validation Batch 7 - 2026-05-05

## Scope

This bounded Android live-lane batch advanced Android-owned L12 platform validation evidence and L13 Android README command documentation.

No shared `Docs/**`, `ios/**`, or `.cron/**` files were edited.

## Android Changes

- Updated `android/README.md` with device-backed validation requirements and validation evidence expectations.
- Added this Android-local report under `android/docs/reports/`.

No Android app source code changed in this batch.

## Environment

- Working directory: `/Users/wangweiyang/GitHub/fastmd/android`
- JDK: `/Applications/Android Studio.app/Contents/jbr/Contents/Home`
- Android SDK: `/Users/wangweiyang/Library/Android/sdk`
- Wrapper Gradle distribution: `https://services.gradle.org/distributions/gradle-9.3.0-bin.zip`
- System Gradle fallback: available and able to evaluate the project graph
- Attached devices/emulators: none listed by `adb devices`
- Installed system images discovered: Android 36 `google_apis`, `google_apis_playstore`, and `google_apis_playstore_ps16k`
- API 27 system image: not present under the local SDK `system-images` tree

## Validation Commands

All commands were run from `/Users/wangweiyang/GitHub/fastmd/android`.

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew projects` | BLOCKED | Wrapper attempted to download Gradle 9.3.0 from `services.gradle.org` and failed with `java.net.UnknownHostException: services.gradle.org`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle projects` | PASS | System Gradle resolved root project `fastmd-android` with modules `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle :core:testDebugUnitTest --stacktrace` | BLOCKED | Reached `:core:compileDebugKotlin`, then failed resolving `androidx.datastore:datastore-preferences:1.1.1` from `dl.google.com` with `java.net.UnknownHostException: dl.google.com`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle lint build :feature:reader:testDebugUnitTest :app:assembleDebug :app:connectedDebugAndroidTest` | BLOCKED | Aggregate validation stopped at `:core:checkDebugAarMetadata` on the same `dl.google.com` dependency-resolution blocker for DataStore, Kotlin stdlib, Compose BOM, and related AndroidX artifacts. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle stage1AndroidRendererAssetGates stage1AndroidPerformanceReport` | PASS | Gradle script-backed gates passed renderer asset audits, renderer asset regression self-tests, and Android performance report audit. |
| `bash tools/audit_stage1_manifest.sh` | PASS | Confirmed no permissions, no broad storage/media/notification/default `INTERNET`, `allowBackup=false`, cleartext disabled, only `MainActivity` exported, no WebView implementation, and release hardening posture. |
| `bash tools/audit_renderer_assets.sh` | PASS | Confirmed no Android WebView/android.webkit implementation, no React Native/Flutter/Cordova runtime dependency, and no vendored JS/CSS/font renderer asset tree. |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Confirmed native fallback pass and fail-closed coverage for future local renderer assets, remote subresources, stale/missing manifests, escaping manifest paths, and WebView without request-blocking tests. |
| `bash tools/audit_rich_fixture_render.sh` | PASS | Confirmed rich fixture category coverage, parser/render model block kinds, inline styles, native Compose renderer paths, Mermaid/math source-card fallback, remote image placeholder behavior, and no web app runtime. |
| `bash tools/audit_performance_report.sh` | PASS | Confirmed Android performance profiles, fixture matrix reporting, background IO/parse/search expectations, LazyColumn virtualization checks, remote media policy, and redacted timing diagnostics. |
| `"$HOME/Library/Android/sdk/platform-tools/adb" devices` | BLOCKED | `adb` is installed, but no attached Android device or running emulator was listed. |
| `find "$HOME/Library/Android/sdk/system-images" -maxdepth 4 -type d \| rg 'android-27\|api-27\|google_apis\|default' \| sort` | BLOCKED | Only Android 36 system images were found; no API 27 system image was present for Android 8.1 validation. |

## Checklist Recommendation

The supervising session can use this report as Android evidence for:

- L12: Capture Android performance report.
- L12: Capture Android security audit report.
- L12: Capture rich fixture render report.
- L13: Update `android/README.md` with final build/test commands after Android skeleton lands.
- L13: Record validation reports under `android/docs/reports/`.

Keep these Android L12 gates open:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

## Preserved Blockers

- Wrapper-backed validation is blocked by DNS failure for `services.gradle.org`.
- Dependency-backed system Gradle validation is blocked by DNS failure for `dl.google.com`.
- Connected/device validation is blocked because no Android target is attached or running.
- API 27 validation is blocked because no API 27 system image or device is available in the local SDK/device set.
