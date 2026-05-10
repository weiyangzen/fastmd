# Stage 1 Android L12 Validation Refresh Batch 37 - 2026-05-06

Worker: FastMD Stage 1 Mobile Android live lane

Scope:

- Android-owned validation evidence only.
- No `ios/**`, `Docs/Stage1_Mobile_Blueprint.md`, or `Docs/todos_20260505.md` edits.
- No Android implementation source changes in this batch.

## Batch Selection

The earliest still-open Android-owned cluster is L12 platform validation. This batch attempted the first open Android Gradle gates that can run without a device:

- Android Gradle wrapper project graph sanity check.
- Android `./gradlew lint`.
- Android `./gradlew :core:testDebugUnitTest`.
- Android-local renderer audit regression checks, to preserve L11 conditional renderer evidence while L12 Gradle gates are blocked.
- Device availability check for connected/API profile gates.

## Environment

- Repository: `/Users/wangweiyang/GitHub/fastmd`
- Android project: `/Users/wangweiyang/GitHub/fastmd/android`
- Timestamp: `2026-05-06 07:48:41 CST`
- Default shell `java`: blocked with `Unable to locate a Java Runtime`
- `/usr/libexec/java_home -V`: blocked with `Unable to locate a Java Runtime`
- Gradle wrapper JDK used for this batch: `/Applications/Android Studio.app/Contents/jbr/Contents/Home`
- Android Studio JBR version: OpenJDK `21.0.6`
- Android SDK: `/Users/wangweiyang/Library/Android/sdk`
- Installed Android platforms observed: `android-31`, `android-32`, `android-33`, `android-34`, `android-35`, `android-36`
- Installed system images observed: Android 36 arm64 Google APIs / Play Store images only; no API 27 system image found.

## Commands And Results

| Command | Result | Evidence |
| --- | --- | --- |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew projects --no-daemon` | PASS | Gradle wrapper evaluated root project `fastmd-android` and discovered `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 3s`. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :core:testDebugUnitTest --no-daemon` | BLOCKED | The task reached `:core:testDebugUnitTest` but failed resolving `:core:debugUnitTestRuntimeClasspath` because `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0` timed out from `https://dl.google.com/dl/android/maven2/...`. Kotlin daemon also reported `IllegalArgumentException: 25.0.1` and fell back to non-daemon compilation before the final dependency-resolution failure. |
| `bash tools/audit_renderer_assets.sh` | PASS | Confirmed no Android `WebView` or `android.webkit` implementation, no React Native/Flutter/Cordova/equivalent web runtime dependency, and no vendored JS/CSS/font renderer asset tree; native rich-block fallback remains active. |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Confirmed native fallback passes without vendored renderer assets; synthetic app-local JS/CSS/font assets pass only with valid SHA-256 manifest and metadata lock; missing/misplaced/non-main/stale/unlisted/malformed/escaping renderer asset cases fail; remote/content/protocol-relative/encoded/double-encoded/uppercase dangerous references fail; external navigation, meta refresh, forms, network-capable browser APIs, WebView markers, and React Native markers fail. |
| `/Users/wangweiyang/Library/Android/sdk/platform-tools/adb devices` | BLOCKED | `adb` ran successfully but listed no attached device or running emulator. |
| `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew lint --no-daemon` | BLOCKED | The task graph entered `:core:extractDebugAnnotations` but failed resolving `com.android.tools.lint:lint-gradle:31.13.2` because `https://dl.google.com/dl/android/maven2/.../lint-gradle-31.13.2.pom` timed out. |

## Exact Blockers To Preserve

### Missing Default Java Runtime

Default shell Java remains unavailable:

```text
The operation couldn’t be completed. Unable to locate a Java Runtime.
Please visit http://www.java.com for information on installing Java.
```

Wrapper validation is possible only when `JAVA_HOME` is set explicitly to Android Studio's bundled JBR in this local environment. That JBR is Java 21, not the blueprint-preferred JDK 17.

### Google Maven Timeout For `:core:testDebugUnitTest`

Representative failure:

```text
Execution failed for task ':core:testDebugUnitTest'.
> Could not resolve all files for configuration ':core:debugUnitTestRuntimeClasspath'.
   > Could not download collection-ktx-1.4.0.jar (androidx.collection:collection-ktx:1.4.0)
      > Could not GET 'https://dl.google.com/dl/android/maven2/androidx/collection/collection-ktx/1.4.0/collection-ktx-1.4.0.jar'.
         > Connect to dl.google.com:443 ... failed: Connect timed out
   > Could not download concurrent-futures-1.1.0.jar (androidx.concurrent:concurrent-futures:1.1.0)
      > Could not GET 'https://dl.google.com/dl/android/maven2/androidx/concurrent/concurrent-futures/1.1.0/concurrent-futures-1.1.0.jar'.
         > Connect to dl.google.com:443 ... failed: Connect timed out
```

### Google Maven Timeout For `lint`

Representative failure:

```text
Execution failed for task ':core:extractDebugAnnotations'.
> Could not resolve all files for configuration ':core:detachedConfiguration1'.
   > Could not resolve com.android.tools.lint:lint-gradle:31.13.2.
      > Could not GET 'https://dl.google.com/dl/android/maven2/com/android/tools/lint/lint-gradle/31.13.2/lint-gradle-31.13.2.pom'.
         > Connect to dl.google.com:443 ... failed: Connect timed out
```

## L12 Status From This Batch

- Android `./gradlew lint`: keep open. Attempted and blocked by Google Maven timeout resolving `com.android.tools.lint:lint-gradle:31.13.2`.
- Android `./gradlew :core:testDebugUnitTest`: keep open. Attempted and blocked by Google Maven timeout resolving AndroidX runtime artifacts.
- Android `./gradlew build`: keep open. Not run after `lint` and `:core:testDebugUnitTest` both demonstrated the same unresolved Google Maven dependency blocker.
- Android `./gradlew :feature:reader:testDebugUnitTest`: keep open. Not run in this batch because the core unit-test runtime dependency resolution path is blocked.
- Android `./gradlew :app:assembleDebug`: keep open. Not run in this batch because the same dependency-resolution blocker affects the Gradle graph.
- Android `./gradlew :app:connectedDebugAndroidTest`: keep open. No attached device or running emulator.
- Android API 27 validation: keep open. No API 27 system image/device was found locally.
- Android low-memory/small-screen profile validation: keep open. No small-screen/low-memory device or emulator was available.
- Android modern device validation: keep open. No attached modern device or running emulator was available.

## Supervisor Checklist Recommendations

No new blueprint checklist item should be marked complete from this batch beyond existing prior evidence. This batch refreshes L12 blocker evidence and confirms that the Android Gradle wrapper project graph can still be evaluated when `JAVA_HOME` is explicitly set.

Evidence paths:

- This report: `android/docs/reports/stage1-android-l12-validation-refresh-batch37-20260506.md`
- Renderer audit source: `android/tools/audit_renderer_assets.sh`
- Renderer audit regression source: `android/tools/test_renderer_asset_audit.sh`
- Gradle project configuration: `android/settings.gradle.kts`, `android/build.gradle.kts`
