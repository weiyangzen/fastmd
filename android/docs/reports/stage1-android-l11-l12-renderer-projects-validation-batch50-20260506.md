# Stage 1 Android L11/L12 Renderer And Projects Validation Batch 50

Date: 2026-05-06

Scope: Android live-lane bounded batch for the earliest still-open Android-owned checklist cluster:

- L11 conditional renderer packaging/offline, WebView request-blocking, and renderer asset manifest/hash verification gates.
- L12 minimum local Gradle validation via `projects`.
- L12 unit-test gate attempts where the local environment could advance far enough to expose blockers.

## Environment

- Repository root: `/Users/wangweiyang/GitHub/fastmd`
- Android root: `/Users/wangweiyang/GitHub/fastmd/android`
- Android Gradle wrapper: `./gradlew`, Gradle `9.3.0`
- Android SDK location: `local.properties` contains `sdk.dir=/Users/wangweiyang/Library/Android/sdk`
- Android SDK platforms found during this batch:
  - `platforms/android-35` present
  - `platforms/android-27` not present
  - API 27 system image not found by the local scan
- Device availability: `adb devices` printed only the header `List of devices attached`; no attached device or running emulator was available.
- Default `java -version`: blocked by macOS with `Unable to locate a Java Runtime.`
- Homebrew JDK used for successful wrapper validation: `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`
- Homebrew JDK version: `openjdk version "17.0.17" 2025-10-21`

## Implementation State Verified

The Android implementation remains native Kotlin / Jetpack Compose. No Android `WebView`, `android.webkit`, React Native, Flutter, Cordova, Capacitor, remote WebView shell, or vendored JS/CSS/font renderer asset tree is present in Android main code.

Mermaid and math continue to use native readable fallback surfaces. The conditional renderer gates are therefore satisfied on Android by:

- Passing the native fallback path when no local renderer assets exist.
- Failing closed if any future `WebView`/`android.webkit` implementation is introduced before request-blocking coverage exists.
- Failing closed if any future JS/CSS/font renderer assets are introduced outside `app/src/main/assets/fastmd-renderers/`.
- Requiring `renderer-assets.sha256` plus `renderer-assets.lock` for future vendored assets.
- Verifying SHA-256 values and upstream/version/license metadata for future vendored assets.
- Rejecting remote subresources, CDN references, `javascript:`, `data:`, `blob:`, `filesystem:`, `file:`, `content:`, protocol-relative URLs, percent-encoded and double-encoded URL forms, iframes, `srcdoc`, meta refresh, HTML form navigation, browser network APIs, dynamic import, and worker APIs in local renderer assets.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED | Default shell Java is unavailable: macOS reported `Unable to locate a Java Runtime.` |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home /usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported OpenJDK `17.0.17`. |
| `adb devices` | PASS with device blocker | Command ran, but no devices/emulators were attached. |
| `find "$HOME/Library/Android/sdk" ... android-27/android-35/system-images` | PASS with API 27 blocker | Found `platforms/android-35`; did not find `platforms/android-27` or API 27 system images. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew projects --no-daemon` | PASS | Build successful in 15s. Module graph: root `fastmd-android`, `:app`, `:core`, `:feature:library`, `:feature:reader`, `:feature:settings`. |
| `bash tools/audit_renderer_assets.sh` | PASS | Confirmed no Android WebView/android.webkit implementation, no React Native/Flutter/Cordova/equivalent web runtime dependency, and no vendored JS/CSS/font renderer asset tree. |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Regression cases passed for native fallback, valid app-local JS/CSS/font asset fixture, missing/stale/malformed manifests, metadata lock requirements, misplaced/non-main assets, URL/subresource/navigation/API blockers, WebView fail-closed marker, and React Native fail-closed marker. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew stage1AndroidRendererAssetGates --no-daemon` | PASS | Build successful in 39s. Ran `auditRendererAssets`, `testRendererAssetAudit`, and `stage1AndroidRendererAssetGates`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew projects :core:testDebugUnitTest :feature:reader:testDebugUnitTest --no-daemon` | PARTIAL/BLOCKED | `:projects` passed. `:feature:reader:compileDebugKotlin` failed resolving `androidx.compose.compiler:compiler:1.5.14` from `https://dl.google.com/...` due connect timeout. Android Studio JBR also triggered Kotlin daemon fallback logs with `IllegalArgumentException: 25.0.1`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew :core:testDebugUnitTest --no-daemon` | BLOCKED | Reached `:core:testDebugUnitTest`, then failed resolving runtime dependencies from Google Maven: `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0`, both connect timeouts to `dl.google.com:443`. |

## Blueprint Checklist Evidence For Supervisor

The supervisor can mark the Android portion of these L11 checklist items complete based on this report plus the source files named below:

- L11 `Add local renderer packaging/offline tests if JS renderer assets are used.`
  - Evidence: `android/tools/test_renderer_asset_audit.sh` passes both no-assets native fallback and a synthetic app-local JS/CSS/font asset fixture with all assets packaged offline.
  - Evidence: `android/tools/audit_renderer_assets.sh` passes current implementation because no vendored JS/CSS/font renderer asset tree exists.
  - Evidence: Gradle aggregate `stage1AndroidRendererAssetGates` passed.
- L11 `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
  - Android evidence: no local JS renderer surface or WebView exists.
  - Android evidence: `android/tools/test_renderer_asset_audit.sh` includes a WebView marker regression that fails closed until request-blocking coverage exists.
  - Android evidence: `android/core/src/test/java/com/fastmd/mobile/core/render/RichRendererAssetPolicyTest.kt` covers request policy decisions for local renderer asset URLs, external navigation, iframe requests, remote requests, dangerous schemes, content/blob/filesystem URLs, and encoded forms.
- L11 `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
  - Evidence: no JS/CSS/font assets are currently vendored.
  - Evidence: `android/tools/test_renderer_asset_audit.sh` verifies future vendored asset manifest/hash behavior with valid, missing, malformed, stale, escaping, unlisted, metadata-missing, metadata-stale, and self-hashing manifest cases.
  - Evidence: `android/core/src/test/java/com/fastmd/mobile/core/render/RichRendererAssetPolicyTest.kt` verifies `LocalRendererAssetManifest` parsing and packaged hash verification.

The supervisor can mark this L12 item complete:

- L12 `Run Android ./gradlew projects.`
  - Evidence: `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew projects --no-daemon` passed and printed the expected module graph.

The supervisor should keep these Android L12 items open from this batch:

- L12 `Run Android ./gradlew :core:testDebugUnitTest.`
  - Blocker: Google Maven dependency downloads timed out for AndroidX runtime jars.
- L12 `Run Android ./gradlew :feature:reader:testDebugUnitTest.`
  - Blocker: Google Maven dependency download timed out for Compose compiler `1.5.14`.
- L12 `Run Android ./gradlew :app:connectedDebugAndroidTest.`
  - Blocker: no attached device or running emulator.
- L12 `Run Android API 27 validation.`
  - Blocker: no API 27 SDK platform/system image found in the local Android SDK scan.
- L12 device-profile validations.
  - Blocker: no attached device or emulator.

## Files Touched

- `android/docs/reports/stage1-android-l11-l12-renderer-projects-validation-batch50-20260506.md`

