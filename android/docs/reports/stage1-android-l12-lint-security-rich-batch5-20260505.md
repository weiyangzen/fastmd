# Stage 1 Android L12 Lint/Security/Rich Validation Batch 5 - 2026-05-05

## Scope

This bounded Android live-lane batch advanced the earliest open Android-owned L12 validation cluster without editing shared `Docs/**`, `ios/**`, or `.cron/**` files.

The batch attempted the wrapper-backed lint gate first, then ran the smallest available real Android validation fallback and Android-local security/rich-renderer audits.

## Environment

- Repository: `/Users/wangweiyang/GitHub/fastmd/android`
- Android SDK pointer: `android/local.properties` contains `sdk.dir=/Users/wangweiyang/Library/Android/sdk`
- JDK used for Android commands: `/Applications/Android Studio.app/Contents/jbr/Contents/Home`
- Default `/usr/bin/java` is still unavailable through macOS Java discovery.

## Validation Results

All commands were run from `/Users/wangweiyang/GitHub/fastmd/android`.

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew projects` | BLOCKED | Wrapper attempted to download `https://services.gradle.org/distributions/gradle-9.3.0-bin.zip` and failed with `java.net.UnknownHostException: services.gradle.org`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew lint` | BLOCKED | Same wrapper distribution DNS blocker before project evaluation: `java.net.UnknownHostException: services.gradle.org`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle projects` | PASS | System Gradle resolved root project `fastmd-android` with modules `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle lint` | BLOCKED | Reached `:core:checkDebugAarMetadata`, then failed resolving Android/Kotlin dependencies from `https://dl.google.com/dl/android/maven2/`; DNS reported `dl.google.com: nodename nor servname provided, or not known`. |
| `curl -I --connect-timeout 10 --max-time 20 https://services.gradle.org/distributions/gradle-9.3.0-bin.zip` | BLOCKED | DNS failed: `Could not resolve host: services.gradle.org`. |
| `curl -I --connect-timeout 10 --max-time 20 https://maven.aliyun.com/repository/google/androidx/datastore/datastore-preferences/1.1.1/datastore-preferences-1.1.1.pom` | BLOCKED | DNS failed: `Could not resolve host: maven.aliyun.com`. |
| `curl -I --connect-timeout 10 --max-time 20 https://mirrors.cloud.tencent.com/gradle/gradle-9.3.0-bin.zip` | BLOCKED | DNS failed: `Could not resolve host: mirrors.cloud.tencent.com`. |
| `bash tools/audit_stage1_manifest.sh` | PASS | No permissions; no broad storage, notification, or default `INTERNET`; `allowBackup=false`; cleartext disabled; only document-entry `MainActivity` exported; no WebView implementation; release hardening enabled. |
| `bash tools/audit_renderer_assets.sh` | PASS | No Android WebView/android.webkit implementation, no React Native/Flutter/Cordova runtime dependency, and no vendored JS/CSS/font renderer asset tree. |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Native fallback, app-local hashed renderer assets, and negative cases for missing manifest, misplaced assets, remote/protocol-relative subresources, uppercase dangerous URLs, external navigation APIs, stale hashes, unlisted assets, escaping manifest paths, and WebView-without-request-blocking-gate all behaved as expected. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle stage1AndroidRendererAssetGates` | PASS | Gradle executed `:auditRendererAssets` and `:testRendererAssetAudit`; the aggregate renderer asset gate passed. |
| `bash tools/audit_rich_fixture_render.sh` | PASS | Rich fixture coverage audit passed for native block and inline coverage, safe fallbacks, local horizontal scrolling, remote image placeholder posture, Mermaid/math source-card fallback, and no web app runtime. |
| `bash tools/audit_font_scale_tiers.sh` | PASS | Produced a 4 font tier by 4 fontScale matrix and confirmed scalable `sp` usage across Android font tiers. |

## Blockers Preserved

- `./gradlew lint` remains open. The checked-in wrapper cannot fetch Gradle `9.3.0` because `services.gradle.org` is not resolvable in this environment.
- System `gradle lint` remains open. It reaches Android dependency resolution, then fails because `dl.google.com` is not resolvable.
- Wrapper-based `./gradlew build`, `./gradlew :core:testDebugUnitTest`, `./gradlew :feature:reader:testDebugUnitTest`, `./gradlew :app:assembleDebug`, and `./gradlew :app:connectedDebugAndroidTest` should remain open until wrapper and dependency DNS resolution work.
- Device/emulator gates remain open because no debug APK can be assembled while dependency resolution is blocked.

## Supervisor Checklist Recommendation

The supervisor can use this report as fresh Android-lane evidence for:

- L12: Capture Android security audit report.
- L12: Capture rich fixture render report.
- L13: Record validation reports under `android/docs/reports/`.

The supervisor should keep these L12 checklist items open from this batch:

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

