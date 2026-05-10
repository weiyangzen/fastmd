# Stage 1 Android L12 Live Validation Batch - 2026-05-05

## Scope

This bounded Android live-lane batch advanced the earliest still-open Android-owned L12 validation gates without editing shared `Docs/**` checklists or any iOS files.

## Environment

- Working directory: `android/`
- Android SDK location: `/Users/wangweiyang/Library/Android/sdk` from `local.properties`
- Installed Android platform used for configuration discovery: `android-35` is present
- JDK used for validation: `/Applications/Android Studio.app/Contents/jbr/Contents/Home`
- Device state: `adb devices` returned no attached devices or emulators
- API 27 system image discovery: no `android-27` system image was found under the local SDK `system-images` tree

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew projects` | BLOCKED | Wrapper attempted to download `https://services.gradle.org/distributions/gradle-9.3.0-bin.zip` and failed with `java.net.UnknownHostException: services.gradle.org`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle projects` | PASS | System Gradle resolved root project `fastmd-android` and modules `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle lint` | BLOCKED | Android project configuration started, then `:core:checkDebugAarMetadata` failed because dependencies such as `androidx.datastore:datastore-preferences:1.1.1`, `org.jetbrains.kotlin:kotlin-stdlib:1.9.24`, and `androidx.compose:compose-bom:2024.06.00` could not be resolved from `https://dl.google.com/dl/android/maven2/`; DNS reported `dl.google.com` unavailable. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle build` | BLOCKED | Aggregate build reached `:app:checkDebugAarMetadata`, then failed on the same `dl.google.com` dependency-resolution blocker for Kotlin, Compose, AndroidX Activity, Lifecycle, and DataStore artifacts. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle :core:testDebugUnitTest` | BLOCKED | Core unit-test gate reached `:core:compileDebugKotlin`, then failed on the same `dl.google.com` dependency-resolution blocker. |
| `bash tools/audit_stage1_manifest.sh` | PASS | Manifest audit found no `uses-permission` declarations, no broad storage/media/notification/default `INTERNET` permission, `allowBackup=false`, cleartext disabled, only `MainActivity` exported, no WebView implementation, and release minify/resource shrinking enabled. |
| `bash tools/audit_renderer_assets.sh` | PASS | No Android WebView/android.webkit implementation, no React Native/Flutter/Cordova runtime dependency, and no vendored JS/CSS/font renderer asset tree were found; Android rich blocks remain native fallback paths. |
| `bash tools/audit_rich_fixture_render.sh` | PASS | Rich fixture audit confirmed fixture coverage, parser/render model block kinds, inline styles, native Compose renderer paths, safe Mermaid/math source-card fallback, remote image placeholder behavior, and no web app runtime. |
| `bash tools/audit_font_scale_tiers.sh` | PASS | Four Android font tiers compose with sampled font scales `0.85`, `1.00`, `1.30`, and `2.00`. |
| `"$HOME/Library/Android/sdk/platform-tools/adb" devices` | BLOCKED | `adb` is installed, but no attached Android device or running emulator was listed. |

## Checklist Recommendation

The supervising session can mark the following Android L12/L13 evidence items complete from this batch:

- `Record validation reports under android/docs/reports/` with this report as evidence.

The supervising session can also use this batch as current Android evidence for these L12 report captures, while keeping compile/device gates open:

- `Capture Android security audit report` using `bash tools/audit_stage1_manifest.sh` and `bash tools/audit_renderer_assets.sh`.
- `Capture rich fixture render report` using `bash tools/audit_rich_fixture_render.sh`.

Keep these Android L12 gates open:

- `Run Android ./gradlew lint` because the wrapper is blocked by `services.gradle.org` DNS and the system Gradle fallback is blocked by `dl.google.com` DNS dependency resolution.
- `Run Android ./gradlew build` for the same dependency-resolution blocker.
- `Run Android ./gradlew :core:testDebugUnitTest` for the same dependency-resolution blocker.
- `Run Android ./gradlew :feature:reader:testDebugUnitTest` because dependency-backed Gradle tasks are blocked before compilation.
- `Run Android ./gradlew :app:assembleDebug` because dependency-backed Gradle tasks are blocked before assembly.
- `Run Android ./gradlew :app:connectedDebugAndroidTest` because dependency-backed Gradle tasks are blocked and no device/emulator is attached.
- `Run Android API 27 validation` because no API 27 device/emulator/system image is available in this environment.
- `Run Android low-memory/small-screen profile validation` because no suitable device/emulator is attached.
- `Run Android modern device validation` because no suitable device/emulator is attached.

## Notes

This batch did not change Android app source code. It only added platform-local validation evidence under `android/docs/reports/**`.
