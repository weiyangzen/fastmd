# Stage 1 Android L11/L12 Validation Refresh Batch 38 - 2026-05-06

Worker: FastMD Stage 1 Mobile Android live lane

Scope:

- Android-owned validation evidence only.
- No `ios/**`, shared `Docs/**`, or `.cron/**` edits.
- No Android implementation source changes in this batch.

## Batch Selection

The earliest unreconciled Android-owned checklist cluster in the authoritative
blueprint is L11 renderer gate coverage, followed by L12 Android platform
validation. Earlier Android implementation clusters already have Android-local
source and report evidence, so this batch refreshed:

- Conditional L11 renderer asset packaging/offline/hash/request-blocking gate
  evidence through the Gradle wrapper.
- The first open L12 wrapper-backed validation gates that can run without a
  device: project graph, `lint`, and `:core:testDebugUnitTest`.
- Device availability and local SDK profile blockers for connected/API profile
  gates.

## Environment

- Repository: `/Users/wangweiyang/GitHub/fastmd`
- Android project: `/Users/wangweiyang/GitHub/fastmd/android`
- Timestamp: `2026-05-06 07:51:24 CST`
- Default shell Java: blocked with `Unable to locate a Java Runtime`
- Wrapper `JAVA_HOME`: `/Applications/Android Studio.app/Contents/jbr/Contents/Home`
- Wrapper JBR version: OpenJDK `21.0.6`
- Installed Android SDK platforms observed: `android-31`, `android-32`,
  `android-33`, `android-34`, `android-35`, `android-36`
- `adb devices`: no attached device or running emulator

## Commands And Results

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew projects --no-daemon` | PASS | Wrapper evaluated root project `fastmd-android` and discovered `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 3s`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew lint --no-daemon` | BLOCKED | Gradle reached `:core:extractDebugAnnotations`, then failed resolving `com.android.tools.lint:lint-gradle:31.13.2` from Google Maven because `https://dl.google.com/dl/android/maven2/.../lint-gradle-31.13.2.pom` timed out. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :core:testDebugUnitTest --no-daemon` | BLOCKED | Gradle reached `:core:testDebugUnitTest`, then failed resolving runtime jars `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0` from Google Maven because both downloads timed out. |
| `bash tools/audit_renderer_assets.sh` | PASS | Confirmed no Android `WebView` or `android.webkit` implementation, no React Native/Flutter/Cordova/equivalent web runtime dependency, and no vendored JS/CSS/font renderer asset tree; native rich-block fallback remains active. |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Confirmed native fallback passes with no renderer assets; synthetic app-local JS/CSS/font assets pass only with valid SHA-256 manifest and metadata lock; missing/misplaced/non-main/stale/unlisted/malformed/escaping asset cases fail; remote/content/protocol-relative/encoded/double-encoded/dangerous references fail; external navigation, meta refresh, forms, network-capable browser APIs, WebView markers, and React Native markers fail. |
| `bash tools/audit_stage1_manifest.sh` | PASS | Confirmed no permissions; no broad storage, notification, or default `INTERNET`; `allowBackup=false`; cleartext disabled; only document-entry `MainActivity` exported; no WebView implementation; release build type uses R8/resource shrinking/non-debuggable output and app ProGuard rules. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew stage1AndroidRendererAssetGates --no-daemon` | PASS | Ran `:auditRendererAssets`, `:testRendererAssetAudit`, and `:stage1AndroidRendererAssetGates`; `BUILD SUCCESSFUL in 18s`. |
| `git diff --check -- android` | PASS | No whitespace errors reported for Android-owned changes. |

## Exact Blockers To Preserve

Default shell Java remains unavailable:

```text
The operation couldn't be completed. Unable to locate a Java Runtime.
Please visit http://www.java.com for information on installing Java.
```

Wrapper validation is currently possible only with `JAVA_HOME` explicitly set to
Android Studio's bundled JBR. That JBR is Java 21, not the blueprint-preferred
JDK 17.

`./gradlew lint` remains blocked by Google Maven timeout:

```text
Execution failed for task ':core:extractDebugAnnotations'.
> Could not resolve com.android.tools.lint:lint-gradle:31.13.2.
  > Could not GET 'https://dl.google.com/dl/android/maven2/com/android/tools/lint/lint-gradle/31.13.2/lint-gradle-31.13.2.pom'.
    > Connect to dl.google.com:443 ... failed: Connect timed out
```

`:core:testDebugUnitTest` remains blocked by Google Maven timeout:

```text
Execution failed for task ':core:testDebugUnitTest'.
> Could not resolve all files for configuration ':core:debugUnitTestRuntimeClasspath'.
  > Could not download collection-ktx-1.4.0.jar (androidx.collection:collection-ktx:1.4.0)
    > Connect to dl.google.com:443 ... failed: Connect timed out
  > Could not download concurrent-futures-1.1.0.jar (androidx.concurrent:concurrent-futures:1.1.0)
    > Connect to dl.google.com:443 ... failed: Connect timed out
```

Connected and profile-specific validation remains blocked because no Android
device or emulator is attached, and no API 27 SDK platform/system image is
installed in the local SDK set observed by this batch.

## L12 Status From This Batch

- Android `./gradlew lint`: keep open. Attempted and blocked by Google Maven
  timeout resolving `com.android.tools.lint:lint-gradle:31.13.2`.
- Android `./gradlew :core:testDebugUnitTest`: keep open. Attempted and
  blocked by Google Maven timeout resolving AndroidX runtime jars.
- Android `./gradlew build`: keep open. Not run after the first compile-backed
  gates demonstrated the same external dependency-resolution blocker.
- Android `./gradlew :feature:reader:testDebugUnitTest`: keep open. Not run
  because the core unit-test runtime dependency path is blocked.
- Android `./gradlew :app:assembleDebug`: keep open. Not run because compile
  and test dependency resolution remains unstable.
- Android `./gradlew :app:connectedDebugAndroidTest`: keep open. No attached
  device or running emulator.
- Android API 27 validation: keep open. No API 27 device, emulator, platform,
  or system image was found locally.
- Android low-memory/small-screen profile validation: keep open. No target
  device or emulator was available.
- Android modern device validation: keep open. No target device or emulator was
  available.

## Supervisor Checklist Recommendations

The supervising session can use this batch as fresh Android-lane evidence for:

- L11: Add local renderer packaging/offline tests if JS renderer assets are
  used.
  - Evidence: `android/tools/test_renderer_asset_audit.sh` and wrapper task
    `stage1AndroidRendererAssetGates` passed. Synthetic app-local JS/CSS/font
    assets pass only with valid local packaging, SHA-256 manifest, and metadata
    lock.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer
  surfaces are used.
  - Android evidence: no Android WebView surface exists; the renderer audit
    fails synthetic WebView implementation until a request-blocking gate exists;
    `android/core/src/test/java/com/fastmd/mobile/core/render/RichRendererAssetPolicyTest.kt`
    covers blocked network, navigation, `javascript:`, `data:`, `content:`,
    iframe, unknown-scheme, percent-encoded, and non-renderer-file decisions.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font
  assets are vendored.
  - Evidence: `android/tools/test_renderer_asset_audit.sh` verifies valid
    synthetic renderer manifests and fails missing, stale, malformed, escaping,
    unlisted, misplaced, and non-main-source-set asset cases; wrapper task
    `stage1AndroidRendererAssetGates` passed.
- L13: Record validation reports under `android/docs/reports/`.
  - Evidence: this report.

Do not mark Android L12 lint/build/unit/assemble/connected-device/API 27/
low-memory/modern-device validation complete from this batch.
