# Stage 1 Android L12 Command Validation Batch 4 - 2026-05-05

## Scope

This Android live-lane batch advanced the L12 Android command validation cluster
without editing shared `Docs/**`, `ios/**`, or `.cron/**` files.

The batch used Android Studio's bundled JDK because the default shell `java` command
has no Java runtime configured:

```bash
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
```

The local SDK pointer exists at `android/local.properties`:

```properties
sdk.dir=/Users/wangweiyang/Library/Android/sdk
```

## Validation Results

All commands were run from `/Users/wangweiyang/GitHub/fastmd/android`.

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED | The shell reports `Unable to locate a Java Runtime`; Android commands require an explicit `JAVA_HOME` in this environment. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew projects` | BLOCKED | The checked-in wrapper attempted to download `https://services.gradle.org/distributions/gradle-9.3.0-bin.zip` and failed with `java.net.UnknownHostException: services.gradle.org`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle projects` | PASS | System Gradle resolved root project `fastmd-android` with modules `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `bash tools/audit_renderer_assets.sh` | PASS | Confirmed no Android `WebView`/`android.webkit`, no React Native/Flutter/Cordova runtime dependency, and no vendored JS/CSS/font renderer asset tree. |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Regression audit passed native fallback, app-local SHA-256 manifest, and negative cases for missing manifest, misplaced assets, remote subresources, uppercase dangerous URLs, stale hashes, unlisted packaged assets, escaping manifest paths, and WebView-without-request-blocking-gate. |
| `bash tools/audit_stage1_manifest.sh` | PASS | Confirmed no declared permissions, no broad storage/notification/default `INTERNET`, `allowBackup=false`, cleartext disabled, only document-entry `MainActivity` exported, no WebView implementation, and release hardening posture. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle lint` | BLOCKED | Failed at `:core:checkDebugAarMetadata` because Gradle could not resolve dependencies from `https://dl.google.com/dl/android/maven2/`; DNS reported `dl.google.com` unavailable. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle :core:testDebugUnitTest` | BLOCKED | Reached `:core:compileDebugKotlin`, then failed resolving `androidx.datastore:datastore-preferences:1.1.1` and related Android/Kotlin dependencies from `dl.google.com`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle :feature:reader:testDebugUnitTest` | BLOCKED | Reached the same `:core:compileDebugKotlin` dependency-resolution blocker before reader unit tests could run. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle :app:assembleDebug` | BLOCKED | Failed at `:app:checkDebugAarMetadata` resolving Kotlin, Compose, Activity, Lifecycle, and DataStore dependencies from `dl.google.com`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" gradle build` | BLOCKED | Failed at `:app:checkDebugAarMetadata` with the same `dl.google.com` dependency-resolution blocker. |

## Open Gates Preserved

The supervisor should keep these Android L12 checklist items open from this batch:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

`connectedDebugAndroidTest` and device-class validation were not attempted because
the debug APK cannot be assembled while dependency resolution is blocked.

## Supervisor Checklist Recommendation

The supervising session can use this report as Android evidence for:

- L13: Record validation reports under `android/docs/reports/`.

The supervisor should not mark Android L12 Gradle, assemble, connected-device, API 27,
low-memory/small-screen, or modern-device validation complete from this batch. The
only passing Gradle result here is the system Gradle project graph fallback; the
checked-in wrapper and compile-backed Android gates remain blocked by DNS resolution
for `services.gradle.org` and `dl.google.com`.
