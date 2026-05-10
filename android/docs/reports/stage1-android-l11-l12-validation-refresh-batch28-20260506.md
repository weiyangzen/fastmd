# Stage 1 Android L11/L12 Validation Refresh Batch 28 - 2026-05-06

## Scope

This bounded Android live-lane batch refreshed the earliest still-open
Android-owned checklist surface without touching iOS or the shared authoritative
Docs checklist.

The batch focused on:

- L11 conditional local renderer packaging/offline, request-blocking, and
  manifest/hash verification gates.
- L12 first compile-backed Android validation gates that were previously blocked
  by dependency resolution.
- Minimum wrapper and device availability evidence.

No Android source implementation files were changed in this batch. The only
repository change is this Android-local validation report.

## Changed Android Files

- `android/docs/reports/stage1-android-l11-l12-validation-refresh-batch28-20260506.md`

## Environment

- Working directory: `/Users/wangweiyang/GitHub/fastmd/android`
- Report timestamp: `2026-05-06 06:23:56 CST`
- Shell default Java: blocked. `java -version` reports `Unable to locate a Java Runtime.`
- Explicit validation JDK: `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`
- Explicit validation Java version: OpenJDK `17.0.17`
- Android Studio bundled Java was also present, but it is JDK 21 and was not used
  for this batch because Stage 1 validation expects JDK 17.
- Android SDK location: `local.properties` contains
  `sdk.dir=/Users/wangweiyang/Library/Android/sdk`
- API 27 system image check: `/Users/wangweiyang/Library/Android/sdk/system-images/android-27`
  is not present.
- Device availability: `adb devices` returned an empty attached-device list.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED | The shell default Java runtime is not configured: `Unable to locate a Java Runtime.` |
| `/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home/bin/java -version` | PASS | Reported OpenJDK `17.0.17` Homebrew runtime. |
| `adb devices` | BLOCKED | `adb` is available, but no emulator or physical Android device is attached. |
| `ls -d /Users/wangweiyang/Library/Android/sdk/system-images/android-27` | BLOCKED | The API 27 system image directory is absent locally. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew projects --no-daemon` | PASS | Root project `fastmd-android` resolved modules `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 13s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew stage1AndroidRendererAssetGates --no-daemon` | PASS | Ran `:auditRendererAssets`, `:testRendererAssetAudit`, and `:stage1AndroidRendererAssetGates`; `BUILD SUCCESSFUL in 19s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew lint --no-daemon` | BLOCKED | Gradle reached `:core:extractDebugAnnotations`, then timed out fetching `com.android.tools.lint:lint-gradle:31.13.2` from Google Maven at `https://dl.google.com/dl/android/maven2/...`; `BUILD FAILED in 3m 19s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew :core:testDebugUnitTest --no-daemon` | BLOCKED | Gradle reached `:core:testDebugUnitTest`, then timed out fetching `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0` from Google Maven; `BUILD FAILED in 3m 21s`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew :feature:reader:testDebugUnitTest --no-daemon` | BLOCKED | Gradle reached `:feature:reader:compileDebugKotlin`, then timed out fetching `androidx.compose.compiler:compiler:1.5.14` from Google Maven; `BUILD FAILED in 3m 18s`. |

## Renderer Gate Evidence

The Gradle-backed renderer asset gate passed and confirms the current Android
implementation remains native Kotlin/Jetpack Compose with native fallback rich
blocks:

- No Android `WebView` or `android.webkit` implementation is present.
- No React Native, Flutter, Cordova, or equivalent web runtime dependency is
  present.
- No vendored JS/CSS/font renderer asset tree is currently present.
- Native fallback passes when no renderer assets are vendored.
- App-local JS/CSS/font renderer assets pass only when placed under
  `app/src/main/assets/fastmd-renderers` with a valid SHA-256 manifest.
- The audit fails closed for missing manifests, misplaced assets, remote
  subresources, `content://` references, protocol-relative remote URLs,
  percent-encoded remote URLs, uppercase dangerous URLs, external navigation
  APIs, stale hashes, unlisted assets, escaping manifest paths, self-hashing
  manifests, malformed manifests, WebView implementation markers, and React
  Native runtime markers.

This preserves Android-local evidence for all three conditional L11 renderer
gate items while the app continues to use native Mermaid/math source-card
fallbacks instead of a local JS/WebView surface.

## Blockers Preserved

- Shell default Java remains unconfigured. Wrapper commands require explicit
  `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home`
  in this environment.
- L12 `./gradlew lint` remains open because Google Maven timed out resolving
  `com.android.tools.lint:lint-gradle:31.13.2`.
- L12 `./gradlew :core:testDebugUnitTest` remains open because Google Maven
  timed out resolving AndroidX runtime artifacts.
- L12 `./gradlew :feature:reader:testDebugUnitTest` remains open because Google
  Maven timed out resolving the Compose compiler artifact.
- Broader compile-backed gates should remain open behind the same dependency
  resolution blocker until retried successfully: `./gradlew build` and
  `./gradlew :app:assembleDebug`.
- Device-backed gates remain open because no Android emulator or physical
  device is attached: `./gradlew :app:connectedDebugAndroidTest`, Android API 27
  validation, low-memory/small-screen validation, and modern-device validation.
- Android API 27 validation is also blocked locally by the absent API 27 system
  image directory.

## Supervisor Checklist Recommendation

The supervising session can use this Android-local evidence for:

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
  - Evidence: passing `./gradlew stage1AndroidRendererAssetGates --no-daemon`.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer
  surfaces are used, Android portion.
  - Evidence: no Android WebView surface exists; the renderer gate fails if a
    WebView implementation marker appears before the request-blocking gate is
    explicitly satisfied.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets
  are vendored.
  - Evidence: passing renderer gate positive and negative SHA-256 manifest cases.
- L13: Record validation reports under `android/docs/reports/`.
  - Evidence: this report.

Do not mark these Android L12 gates complete from this batch:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.
