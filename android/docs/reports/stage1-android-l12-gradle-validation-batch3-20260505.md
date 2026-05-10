# Stage 1 Android L12 Gradle Validation Batch 3 - 2026-05-05

## Scope

This bounded Android live-lane batch advanced the earliest actionable Android-owned L12 validation gates without editing shared `Docs/**` checklists or any iOS files.

No Android app source code was changed in this batch. The change is this Android-local validation evidence report.

## Environment

- Working directory: `/Users/wangweiyang/GitHub/fastmd/android`
- SDK location: `/Users/wangweiyang/Library/Android/sdk` from `local.properties`
- Installed Android compile platform found locally: `platforms/android-35`
- Android Gradle wrapper: present at `android/gradlew`, pinned to Gradle `9.3.0`
- Default shell `java`: blocked with `Unable to locate a Java Runtime`
- Validation JDK used for Gradle fallbacks: `/Applications/Android Studio.app/Contents/jbr/Contents/Home`
- Android Studio JBR version: OpenJDK `21.0.6`
- Attached Android devices/emulators: none
- API 27 system image: not present under the local SDK `system-images` tree

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew projects` | BLOCKED | Wrapper attempted to download `https://services.gradle.org/distributions/gradle-9.3.0-bin.zip` and failed with `java.net.UnknownHostException: services.gradle.org`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle projects` | PASS | System Gradle resolved root project `fastmd-android` with modules `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle lint` | BLOCKED | Reached `:core:checkDebugAarMetadata`, then failed resolving `androidx.datastore:datastore-preferences:1.1.1`, `org.jetbrains.kotlin:kotlin-stdlib:1.9.24`, and `androidx.compose:compose-bom:2024.06.00` from `https://dl.google.com/dl/android/maven2/`; DNS reported `dl.google.com` unavailable. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle build` | BLOCKED | Reached `:app:checkDebugAarMetadata`, then failed on the same `dl.google.com` dependency-resolution blocker for Kotlin, Compose, AndroidX Activity, Lifecycle, and DataStore artifacts. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle :core:testDebugUnitTest` | BLOCKED | Reached `:core:compileDebugKotlin`, then failed on the same `dl.google.com` dependency-resolution blocker. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle :feature:reader:testDebugUnitTest` | BLOCKED | Reached `:core:compileDebugKotlin`, then failed on the same `dl.google.com` dependency-resolution blocker before reader tests could compile. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle :app:assembleDebug` | BLOCKED | Reached `:app:checkDebugAarMetadata`, then failed on the same `dl.google.com` dependency-resolution blocker. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle :app:connectedDebugAndroidTest` | BLOCKED | Reached `:app:checkDebugAarMetadata`, then failed on the same `dl.google.com` dependency-resolution blocker before device execution. |
| `"$HOME/Library/Android/sdk/platform-tools/adb" devices` | BLOCKED | `adb` is installed, but no attached devices or running emulators were listed. |
| `find "$HOME/Library/Android/sdk/system-images" -maxdepth 4 -type d` | BLOCKED | Local SDK contains Android 36 system images only; no Android API 27 system image was found. |
| `bash tools/audit_stage1_manifest.sh` | PASS | No `uses-permission` declarations, no broad storage/media/notification/default `INTERNET`, `allowBackup=false`, cleartext disabled, only document-entry `MainActivity` exported, no WebView implementation, and release minify/resource shrinking posture is present. |
| `bash tools/audit_renderer_assets.sh` | PASS | No Android WebView/android.webkit implementation, no React Native/Flutter/Cordova runtime dependency, and no vendored JS/CSS/font renderer asset tree are present. |
| `bash tools/audit_rich_fixture_render.sh` | PASS | Rich fixture coverage, parser/render model block kinds, inline styles, native Compose renderer paths, safe Mermaid/math fallback, remote image privacy, and no web app runtime were confirmed. |
| `bash tools/audit_font_scale_tiers.sh` | PASS | All four Android font tiers compose with sampled font scales `0.85`, `1.00`, `1.30`, and `2.00`. |

## Blockers Preserved

- Wrapper-based validation remains blocked by DNS failure for `services.gradle.org`.
- System Gradle can resolve the project graph, but compile-backed Android gates remain blocked by DNS failure for `dl.google.com`.
- `lint`, `build`, unit tests, assemble, and connected Android test gates should remain open until dependencies resolve and the corresponding `./gradlew` commands pass.
- API 27 validation should remain open until an API 27 device/emulator/system image is available.
- Low-memory/small-screen and modern-device validation should remain open until suitable Android devices or emulators are attached.
- Android performance measurement should remain open until a build can be produced and measured on device/emulator or equivalent release-like target.

## Supervisor Checklist Recommendation

The supervising session can use this report as fresh Android-local evidence for:

- L13: Record validation reports under `android/docs/reports/`.
- L12: Capture Android security audit report, using `bash tools/audit_stage1_manifest.sh` and `bash tools/audit_renderer_assets.sh` evidence.
- L12: Capture rich fixture render report, using `bash tools/audit_rich_fixture_render.sh` evidence.

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
- Capture Android performance report.
